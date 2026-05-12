import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_handlers/xpath_handler.dart';
import 'package:readlive/features/book_source/data/rule_handlers/jsonpath_handler.dart';
import 'package:readlive/features/book_source/data/rule_handlers/regex_handler.dart';
import 'package:readlive/features/book_source/data/rule_handlers/js_handler.dart';

class RuleParser {
  final _xpathHandler = XpathHandler();
  final _jsonpathHandler = JsonpathHandler();
  final _regexHandler = RegexHandler();
  final _jsHandler = JsHandler();

  // ============================================================
  // Template resolution
  // ============================================================

  /// Resolve template variables like {{key}} in a string.
  /// Handles Legado patterns: {{key}}, {{java.encodeURI(key)}},
  /// {{java.get('key')}}, {{@get:key}}, {{(page-1)*10}}, etc.
  String resolveTemplate(
    String template,
    Map<String, String> variables, {
    RuleContext? context,
  }) {
    var result = template;

    // Handle {{java.encodeURI(key)}}
    result = result.replaceAllMapped(
      RegExp(r'\{\{java\.encodeURI\((\w+)\)\}\}'),
      (m) => Uri.encodeComponent(variables[m.group(1)] ?? ''),
    );

    // Handle {{java.get('key')}} — read from context
    result = result.replaceAllMapped(
      RegExp(r"""\{\{java\.get\(['"](\w+)['"]\)\}\}"""),
      (m) {
        if (context != null) return context.get(m.group(1)!);
        return variables[m.group(1)] ?? '';
      },
    );

    // Handle {{@get:key}} — read from context
    result = result.replaceAllMapped(
      RegExp(r'\{\{@get:(\w+)\}\}'),
      (m) {
        if (context != null) return context.get(m.group(1)!);
        return variables[m.group(1)] ?? '';
      },
    );

    // Handle {{java.put('key', value)}} — remove these blocks
    result = result.replaceAll(RegExp(r"\{\{java\.put\([^)]*\)\}\}"), '');

    // Handle simple variable substitution
    for (final entry in variables.entries) {
      var value = entry.value;
      // key variable is auto URL-encoded (search keywords must be encoded in URLs)
      if (entry.key == 'key') {
        value = Uri.encodeComponent(value);
      }
      result = result.replaceAll('{{${entry.key}}}', value);
    }

    // Handle simple math expressions like {{(page - 1) * 10}}
    result = result.replaceAllMapped(
      RegExp(r'\{\{([^{}]+?)\}\}'),
      (m) {
        final expr = m.group(1)!.trim();
        try {
          var mathExpr = expr;
          for (final entry in variables.entries) {
            mathExpr = mathExpr.replaceAll(entry.key, entry.value);
          }
          if (RegExp(r'^[\d\s+\-*/().]+$').hasMatch(mathExpr)) {
            return _evalMath(mathExpr).toString();
          }
        } catch (_) {}
        return m.group(0)!;
      },
    );

    return result;
  }

  // ============================================================
  // Math evaluation
  // ============================================================

  num _evalMath(String expr) {
    expr = expr.replaceAll(' ', '');
    return _parseExpr(expr, 0).$1;
  }

  (num, int) _parseExpr(String s, int pos) {
    var (value, newPos) = _parseTerm(s, pos);
    while (newPos < s.length && (s[newPos] == '+' || s[newPos] == '-')) {
      final op = s[newPos];
      final (term, nextPos) = _parseTerm(s, newPos + 1);
      value = op == '+' ? value + term : value - term;
      newPos = nextPos;
    }
    return (value, newPos);
  }

  (num, int) _parseTerm(String s, int pos) {
    var (value, newPos) = _parseFactor(s, pos);
    while (newPos < s.length && (s[newPos] == '*' || s[newPos] == '/')) {
      final op = s[newPos];
      final (factor, nextPos) = _parseFactor(s, newPos + 1);
      value = op == '*' ? value * factor : value / factor;
      newPos = nextPos;
    }
    return (value, newPos);
  }

  (num, int) _parseFactor(String s, int pos) {
    if (pos < s.length && s[pos] == '(') {
      final (value, newPos) = _parseExpr(s, pos + 1);
      return (value, newPos + 1);
    }
    var end = pos;
    while (end < s.length && (s[end].contains(RegExp(r'[\d.]')))) {
      end++;
    }
    return (num.parse(s.substring(pos, end)), end);
  }

  // ============================================================
  // Extraction methods
  // ============================================================

  /// Extract a single value from HTML using a rule string.
  ///
  /// Supports connectors (&&, ||), CSS selectors, OnlyOne regex, and
  /// @put context storage. Returns null for JSONPath, XPath, JS, and
  /// AllInOne rules (use dedicated methods for those).
  String? extractText(String html, String rule, {RuleContext? context}) {
    if (rule.isEmpty) return null;

    // Handle connectors first
    if (_hasConnector(rule)) {
      return _handleConnectors(html, rule, context);
    }

    // Parse rule
    final parsed = _parseRule(rule);

    // JS rules need async — skip for sync extractText
    if (parsed.jsCode != null) return null;

    // JSONPath rules need JSON data — skip for HTML extractText
    if (parsed.jsonPathRule != null) return null;

    // AllInOne regex is list-only
    if (parsed.allInOneRegex != null) return null;

    String value;

    if (parsed.onlyOneRule != null) {
      value = _regexHandler.applyOnlyOne(
        html,
        parsed.onlyOneRule!.regex,
        parsed.onlyOneRule!.replacement,
      );
      for (final filter in parsed.filters) {
        value = _applyFilter(value, filter);
      }
    } else if (parsed.purifyRule != null) {
      value = _regexHandler.applyPurify(
        html,
        parsed.purifyRule!.regex,
        parsed.purifyRule!.replacement,
      );
      for (final filter in parsed.filters) {
        value = _applyFilter(value, filter);
      }
    } else {
      // Default: CSS selector
      final soup = BeautifulSoup(html);
      final element = soup.find(parsed.selector);
      if (element == null) return null;
      value = _extractAttribute(element, parsed.attribute);
      for (final filter in parsed.filters) {
        value = _applyFilter(value, filter);
      }
    }

    // Store in context if @put was specified
    if (value.isNotEmpty &&
        parsed.putKey != null &&
        context != null) {
      context.put(parsed.putKey!, value);
    }

    return value.isEmpty ? null : value;
  }

  /// Extract a list of values from HTML.
  ///
  /// Supports AllInOne regex (prefixed with :) and CSS selectors.
  List<String> extractList(
    String html,
    String listSelector,
    String itemRule, {
    RuleContext? context,
  }) {
    if (itemRule.isEmpty) return [];

    final parsed = _parseRule(itemRule);

    // AllInOne regex — apply to full HTML
    if (parsed.allInOneRegex != null) {
      return _regexHandler.extractAllInOne(html, parsed.allInOneRegex!);
    }

    // Default: CSS selector
    if (listSelector.isEmpty) return [];
    final soup = BeautifulSoup(html);
    final elements = soup.findAll(listSelector);
    final results = <String>[];
    for (final element in elements) {
      var value = _extractAttribute(element, parsed.attribute);
      for (final filter in parsed.filters) {
        value = _applyFilter(value, filter);
      }
      if (value.isNotEmpty) {
        results.add(value);
      }
    }
    return results;
  }

  /// Extract full text content, removing script/style tags first.
  ///
  /// Supports purify rules and CSS selectors.
  String extractContent(String html, String rule, {RuleContext? context}) {
    if (rule.isEmpty) return '';

    final parsed = _parseRule(rule);

    var cleanHtml = html
        .replaceAll(
          RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
          '',
        );

    // Purify rule
    if (parsed.purifyRule != null) {
      var value = _regexHandler.applyPurify(
        cleanHtml,
        parsed.purifyRule!.regex,
        parsed.purifyRule!.replacement,
      );
      for (final filter in parsed.filters) {
        value = _applyFilter(value, filter);
      }
      return value.trim();
    }

    // Default: CSS selector
    final soup = BeautifulSoup(cleanHtml);
    final element = soup.find(parsed.selector);
    if (element == null) return '';
    var value = _extractAttribute(element, parsed.attribute);
    for (final filter in parsed.filters) {
      value = _applyFilter(value, filter);
    }
    return value.trim();
  }

  /// Extract a list of image URLs from HTML.
  List<String> extractImageList(
    String html,
    String listSelector,
    String itemRule, {
    RuleContext? context,
  }) {
    return extractList(html, listSelector, itemRule, context: context);
  }

  /// Extract structured data from a list of elements.
  List<Map<String, String>> extractTable(
    String html,
    String listSelector,
    Map<String, String> fieldRules, {
    RuleContext? context,
  }) {
    final soup = BeautifulSoup(html);
    final elements = soup.findAll(listSelector);
    final results = <Map<String, String>>[];

    for (final element in elements) {
      final row = <String, String>{};
      for (final entry in fieldRules.entries) {
        final parsed = _parseRule(entry.value);
        final child =
            parsed.selector.isEmpty ? element : element.find(parsed.selector);
        if (child != null) {
          var value = _extractAttribute(child, parsed.attribute);
          for (final filter in parsed.filters) {
            value = _applyFilter(value, filter);
          }
          row[entry.key] = value;
        }
      }
      if (row.isNotEmpty) {
        results.add(row);
      }
    }
    return results;
  }

  // ============================================================
  // JSON and XPath extraction
  // ============================================================

  /// Extract a single value from JSON data using a JSONPath rule.
  String? extractFromJson(
    dynamic jsonData,
    String rule, {
    RuleContext? context,
  }) {
    if (rule.isEmpty) return null;
    final parsed = _parseRule(rule);
    if (parsed.jsonPathRule != null) {
      return _jsonpathHandler.extractText(jsonData, parsed.jsonPathRule!);
    }
    return null;
  }

  /// Extract a list of values from JSON data using a JSONPath rule.
  List<String> extractListFromJson(
    dynamic jsonData,
    String rule, {
    RuleContext? context,
  }) {
    if (rule.isEmpty) return [];
    final parsed = _parseRule(rule);
    if (parsed.jsonPathRule != null) {
      return _jsonpathHandler.extractList(jsonData, parsed.jsonPathRule!);
    }
    return [];
  }

  /// Extract a single value from HTML using an XPath rule.
  String? extractTextWithXpath(
    String html,
    String rule, {
    RuleContext? context,
  }) {
    if (rule.isEmpty) return null;
    final parsed = _parseRule(rule);
    if (parsed.xpathRule != null) {
      return _xpathHandler.extractText(html, parsed.xpathRule!);
    }
    return null;
  }

  /// Extract a list of values from HTML using an XPath rule.
  List<String> extractListWithXpath(
    String html,
    String rule, {
    RuleContext? context,
  }) {
    if (rule.isEmpty) return [];
    final parsed = _parseRule(rule);
    if (parsed.xpathRule != null) {
      return _xpathHandler.extractList(html, parsed.xpathRule!);
    }
    return [];
  }

  // ============================================================
  // Connectors
  // ============================================================

  bool _hasConnector(String rule) {
    return rule.contains('||') || rule.contains('&&');
  }

  /// Handle && (merge values) and || (first non-empty) connectors.
  String? _handleConnectors(String html, String rule, RuleContext? context) {
    // || has lower precedence — check first
    if (rule.contains('||')) {
      final parts = rule.split('||');
      for (final part in parts) {
        final result = extractText(html, part.trim(), context: context);
        if (result != null && result.isNotEmpty) return result;
      }
      return null;
    }

    // && merges values
    if (rule.contains('&&')) {
      final parts = rule.split('&&');
      final results = <String>[];
      for (final part in parts) {
        final result = extractText(html, part.trim(), context: context);
        if (result != null && result.isNotEmpty) results.add(result);
      }
      if (results.isEmpty) return null;
      return results.join('\n');
    }

    return null;
  }

  // ============================================================
  // Rule parsing
  // ============================================================

  _ParsedRule _parseRule(String rule) {
    var workingRule = rule.trim();

    // 1. Extract @put:{key=value} from end
    String? putKey;
    final putMatch = RegExp(r'@put:\{([^}]+)\}$').firstMatch(workingRule);
    if (putMatch != null) {
      final putContent = putMatch.group(1)!;
      final eqIdx = putContent.indexOf('=');
      if (eqIdx >= 0) {
        putKey = putContent.substring(0, eqIdx).trim();
      }
      workingRule = workingRule.substring(0, putMatch.start).trim();
    }

    // 2. Check for ## rules (purify / OnlyOne)
    if (workingRule.startsWith('##')) {
      // OnlyOne: ##regex##replacement###
      if (RegexHandler.isOnlyOne(workingRule)) {
        final onlyOne = RegexHandler.parseOnlyOneRule(workingRule);
        return _ParsedRule(
          selector: '',
          attribute: 'text',
          filters: [],
          onlyOneRule: onlyOne,
          putKey: putKey,
        );
      }
      // Purify: ##regex##replacement (no trailing ###)
      if (RegexHandler.isPurify(workingRule)) {
        final purify = RegexHandler.parsePurifyRule(workingRule);
        return _ParsedRule(
          selector: '',
          attribute: 'text',
          filters: [],
          purifyRule: purify,
          putKey: putKey,
        );
      }
    }

    // 3. Check JS rule
    if (JsHandler.isJsRule(workingRule)) {
      final jsCode = JsHandler.extractJsCode(workingRule);
      return _ParsedRule(
        selector: '',
        attribute: 'text',
        filters: [],
        jsCode: jsCode,
        putKey: putKey,
      );
    }

    // 4. Split by | for filters
    final parts = workingRule.split('|');
    var selectorAttr = parts[0].trim();
    final filters = parts.skip(1).map((f) => f.trim()).toList();

    // 5. Strip @css: prefix
    if (selectorAttr.startsWith('@css:')) {
      selectorAttr = selectorAttr.substring(5).trim();
    }

    // 6. Check JSONPath (@json: or $.)
    if (selectorAttr.startsWith(r'$.') || selectorAttr.startsWith('@json:')) {
      return _ParsedRule(
        selector: '',
        attribute: 'text',
        filters: filters,
        jsonPathRule: selectorAttr,
        putKey: putKey,
      );
    }

    // 7. Check XPath (// or @XPath:)
    if (selectorAttr.startsWith('//') || selectorAttr.startsWith('@XPath:')) {
      return _ParsedRule(
        selector: '',
        attribute: 'text',
        filters: filters,
        xpathRule: selectorAttr,
        putKey: putKey,
      );
    }

    // 8. Check AllInOne (: prefix)
    if (selectorAttr.startsWith(':')) {
      return _ParsedRule(
        selector: '',
        attribute: 'text',
        filters: filters,
        allInOneRegex: selectorAttr.substring(1),
        putKey: putKey,
      );
    }

    // 9. Default: CSS selector
    final atIdx = selectorAttr.lastIndexOf('@');
    String selector;
    String attribute;
    if (atIdx >= 0) {
      selector = selectorAttr.substring(0, atIdx).trim();
      attribute = selectorAttr.substring(atIdx + 1).trim();
    } else {
      selector = selectorAttr;
      attribute = 'text';
    }

    return _ParsedRule(
      selector: selector,
      attribute: attribute,
      filters: filters,
      putKey: putKey,
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _extractAttribute(Bs4Element element, String attribute) {
    switch (attribute) {
      case 'text':
        return element.text;
      case 'href':
        return element.attributes['href'] ?? '';
      case 'src':
        return element.attributes['src'] ?? '';
      case 'html':
        return element.innerHtml;
      default:
        return element.attributes[attribute] ?? '';
    }
  }

  String _applyFilter(String value, String filter) {
    // Check for purify pattern in filter (##regex##replacement)
    if (RegexHandler.isPurify(filter)) {
      final purify = RegexHandler.parsePurifyRule(filter);
      if (purify != null) {
        return _regexHandler.applyPurify(
          value,
          purify.regex,
          purify.replacement,
        );
      }
    }

    if (filter == 'trim') {
      return value.trim();
    } else if (filter == 'removeAd') {
      return value
          .replaceAll(
            RegExp(r'(广告|推荐|百度搜索|喜欢.*?推荐|最新章节|手机阅读)'),
            '',
          )
          .trim();
    } else if (filter.startsWith('replace(') && filter.endsWith(')')) {
      final args = filter.substring(8, filter.length - 1);
      final commaIdx = args.indexOf(',');
      if (commaIdx >= 0) {
        final from = args.substring(0, commaIdx).trim();
        final to = args.substring(commaIdx + 1).trim();
        return value.replaceAll(from, to);
      }
    }
    return value;
  }
}

class _ParsedRule {
  final String selector;
  final String attribute;
  final List<String> filters;
  final String? jsonPathRule;
  final String? xpathRule;
  final String? allInOneRegex;
  final ({String regex, String replacement})? onlyOneRule;
  final ({String regex, String replacement})? purifyRule;
  final String? jsCode;
  final String? putKey;

  const _ParsedRule({
    required this.selector,
    required this.attribute,
    required this.filters,
    this.jsonPathRule,
    this.xpathRule,
    this.allInOneRegex,
    this.onlyOneRule,
    this.purifyRule,
    this.jsCode,
    this.putKey,
  });
}
