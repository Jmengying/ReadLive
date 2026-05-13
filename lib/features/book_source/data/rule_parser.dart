import 'dart:convert' show jsonDecode;
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:json_path/json_path.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
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
      final elements = soup.findAll(parsed.selector);
      if (elements.isEmpty) return null;
      final element = elements[parsed.elementIndex.clamp(0, elements.length - 1)];
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
      Bs4Element? target;
      if (parsed.selector.isEmpty) {
        target = element;
      } else {
        final found = element.findAll(parsed.selector);
        if (found.isNotEmpty) {
          target = found[parsed.elementIndex.clamp(0, found.length - 1)];
        }
      }
      if (target != null) {
        var value = _extractAttribute(target, parsed.attribute);
        for (final filter in parsed.filters) {
          value = _applyFilter(value, filter);
        }
        if (value.isNotEmpty) {
          results.add(value);
        }
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
  ///
  /// Supports both CSS selectors and XPath selectors (starting with //).
  List<Map<String, String>> extractTable(
    String html,
    String listSelector,
    Map<String, String> fieldRules, {
    RuleContext? context,
  }) {
    if (listSelector.isEmpty) return [];

    // Skip @js: selectors
    if (listSelector.startsWith('@js:')) return [];

    // Handle XPath selectors
    if (listSelector.startsWith('//') || listSelector.startsWith('@XPath:')) {
      return _extractTableWithXpath(html, listSelector, fieldRules);
    }

    try {
      final soup = BeautifulSoup(html);
      final elements = soup.findAll(listSelector);
      final results = <Map<String, String>>[];

      for (final element in elements) {
        final row = <String, String>{};
        for (final entry in fieldRules.entries) {
          try {
            final parsed = _parseRule(entry.value);
            // Skip @js: field rules
            if (parsed.jsCode != null) continue;
            Bs4Element? child;
            if (parsed.selector.isEmpty) {
              child = element;
            } else {
              final found = element.findAll(parsed.selector);
              if (found.isNotEmpty) {
                child = found[parsed.elementIndex.clamp(0, found.length - 1)];
              }
            }
            if (child != null) {
              var value = _extractAttribute(child, parsed.attribute);
              for (final filter in parsed.filters) {
                value = _applyFilter(value, filter);
              }
              row[entry.key] = value;
            }
          } catch (_) {
            // Skip fields that fail to parse
          }
        }
        if (row.isNotEmpty) {
          results.add(row);
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Extract table using XPath selectors.
  List<Map<String, String>> _extractTableWithXpath(
    String html,
    String listSelector,
    Map<String, String> fieldRules,
  ) {
    try {
      final listXpath = listSelector.startsWith('@XPath:')
          ? listSelector.substring(7).trim()
          : listSelector;

      // Find all items using XPath
      final doc = HtmlXPath.html(html);
      final items = doc.query(listXpath).nodes;
      if (items.isEmpty) return [];

      final results = <Map<String, String>>[];
      for (final item in items) {
        final row = <String, String>{};
        final itemHtml = item.node is html_dom.Element
            ? (item.node as html_dom.Element).outerHtml
            : item.text ?? '';

        for (final entry in fieldRules.entries) {
          try {
            final rule = entry.value.trim();
            if (rule.isEmpty) continue;

            String? value;
            if (rule.startsWith('//') || rule.startsWith('@XPath:')) {
              // XPath field rule — apply to item HTML
              final fieldXpath = rule.startsWith('@XPath:')
                  ? rule.substring(7).trim()
                  : rule;
              value = _xpathHandler.extractText(itemHtml, fieldXpath);
            } else {
              // Try as XPath if it looks like one, otherwise CSS
              final parsed = _parseRule(rule);
              if (parsed.xpathRule != null) {
                value = _xpathHandler.extractText(itemHtml, parsed.xpathRule!);
              } else if (parsed.jsCode != null) {
                continue; // Skip JS rules
              } else {
                // CSS selector on item HTML
                final soup = BeautifulSoup(itemHtml);
                Bs4Element? child;
                if (parsed.selector.isEmpty) {
                  child = soup.find('*');
                } else {
                  final found = soup.findAll(parsed.selector);
                  if (found.isNotEmpty) {
                    child = found[parsed.elementIndex.clamp(0, found.length - 1)];
                  }
                }
                if (child != null) {
                  value = _extractAttribute(child, parsed.attribute);
                }
              }
            }

            if (value != null && value.isNotEmpty) {
              // Apply filters
              final parsed = _parseRule(entry.value);
              for (final filter in parsed.filters) {
                value = _applyFilter(value!, filter);
              }
              row[entry.key] = value!;
            }
          } catch (_) {}
        }
        if (row.isNotEmpty) results.add(row);
      }
      return results;
    } catch (_) {
      return [];
    }
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
  // Async extraction methods (with JS support)
  // ============================================================

  /// Async version of [extractText] that evaluates JS rules and JSONPath.
  Future<String?> extractTextAsync(
    String body,
    String rule, {
    RuleContext? context,
    String? baseUrl,
  }) async {
    if (rule.isEmpty) return null;

    final parsed = _parseRule(rule);

    // If rule is JSONPath, try to parse input as JSON first
    if (parsed.jsonPathRule != null) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final jsonData = jsonDecode(trimmed);
          return _jsonpathHandler.extractText(jsonData, parsed.jsonPathRule!);
        } catch (_) {}
      }
      return null;
    }

    // If rule contains JS, evaluate it
    if (parsed.jsCode != null) {
      final ctx = context ?? RuleContext();
      final jsResult = await _jsHandler.execute(parsed.jsCode!, ctx, baseUrl: baseUrl, result: body);
      if (jsResult != null && jsResult.isNotEmpty) {
        // Apply filters
        var value = jsResult;
        for (final filter in parsed.filters) {
          value = _applyFilter(value, filter);
        }
        if (parsed.putKey != null) ctx.put(parsed.putKey!, value);
        return value;
      }
      return null;
    }

    // Fall back to sync method
    return extractText(body, rule, context: context);
  }

  /// Async version of [extractList] that evaluates JS rules and JSONPath.
  Future<List<String>> extractListAsync(
    String body,
    String listSelector,
    String itemRule, {
    RuleContext? context,
    String? baseUrl,
  }) async {
    if (itemRule.isEmpty) return [];

    final parsed = _parseRule(itemRule);

    // If list selector is JSONPath, try to parse input as JSON
    if (JsonpathHandler.isJsonPath(listSelector)) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final jsonData = jsonDecode(trimmed);
          return _jsonpathHandler.extractList(jsonData, listSelector);
        } catch (_) {}
      }
      return [];
    }

    // If list selector contains JS, evaluate it to get the list
    if (listSelector.startsWith('<js>') || listSelector.startsWith('@js:')) {
      final jsCode = JsHandler.extractJsCode(listSelector);
      final ctx = context ?? RuleContext();
      final jsResult = await _jsHandler.execute(jsCode, ctx, baseUrl: baseUrl, result: body);
      if (jsResult != null && jsResult.isNotEmpty) {
        // JS result might be a JSON array or newline-separated values
        try {
          final List<dynamic> arr;
          if (jsResult.startsWith('[')) {
            arr = List<dynamic>.from(_parseJson(jsResult));
          } else {
            arr = jsResult.split('\n').where((s) => s.isNotEmpty).toList();
          }
          return arr.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
        } catch (_) {
          return [jsResult];
        }
      }
      return [];
    }

    // If item rule contains JS, evaluate for each element
    if (parsed.jsCode != null) {
      final items = extractList(body, listSelector, '', context: context);
      final results = <String>[];
      for (final item in items) {
        final ctx = context ?? RuleContext();
        final jsResult = await _jsHandler.execute(parsed.jsCode!, ctx, baseUrl: baseUrl, result: item);
        if (jsResult != null && jsResult.isNotEmpty) {
          results.add(jsResult);
        }
      }
      return results;
    }

    return extractList(body, listSelector, itemRule, context: context);
  }

  /// Async version of [extractContent] that evaluates JS rules and JSONPath.
  Future<String> extractContentAsync(
    String body,
    String rule, {
    RuleContext? context,
    String? baseUrl,
  }) async {
    if (rule.isEmpty) return '';

    final parsed = _parseRule(rule);

    // If rule is JSONPath, try to parse input as JSON first
    if (parsed.jsonPathRule != null) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final jsonData = jsonDecode(trimmed);
          final result = _jsonpathHandler.extractText(jsonData, parsed.jsonPathRule!);
          if (result != null && result.isNotEmpty) {
            var value = result;
            for (final filter in parsed.filters) {
              value = _applyFilter(value, filter);
            }
            return value.trim();
          }
        } catch (_) {}
      }
      return '';
    }

    if (parsed.jsCode != null) {
      final ctx = context ?? RuleContext();
      final jsResult = await _jsHandler.execute(parsed.jsCode!, ctx, baseUrl: baseUrl, result: body);
      if (jsResult != null && jsResult.isNotEmpty) {
        var value = jsResult;
        for (final filter in parsed.filters) {
          value = _applyFilter(value, filter);
        }
        return value.trim();
      }
      return '';
    }

    return extractContent(body, rule, context: context);
  }

  /// Async version of [extractTable] that evaluates JS rules in fields.
  Future<List<Map<String, String>>> extractTableAsync(
    String body,
    String listSelector,
    Map<String, String> fieldRules, {
    RuleContext? context,
    String? baseUrl,
  }) async {
    if (listSelector.isEmpty) return [];

    // Handle JSONPath list selectors
    if (JsonpathHandler.isJsonPath(listSelector)) {
      final trimmed = body.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final jsonData = jsonDecode(trimmed);
          final cleanPath = listSelector.startsWith('@json:')
              ? listSelector.substring(6).trim()
              : listSelector;
          final jsonItems = JsonPath(cleanPath).read(jsonData).map((m) => m.value).toList();
          return jsonItems.whereType<Map>().map((item) {
            final row = <String, String>{};
            for (final entry in fieldRules.entries) {
              try {
                final parsed = _parseRule(entry.value);
                if (parsed.jsonPathRule != null) {
                  final val = _jsonpathHandler.extractText(item, parsed.jsonPathRule!);
                  if (val != null && val.isNotEmpty) row[entry.key] = val;
                }
              } catch (_) {}
            }
            return row;
          }).where((r) => r.isNotEmpty).toList();
        } catch (_) {}
      }
      return [];
    }

    // Handle @js: list selectors
    if (listSelector.startsWith('@js:')) {
      final jsCode = JsHandler.extractJsCode(listSelector);
      final ctx = context ?? RuleContext();
      final jsResult = await _jsHandler.execute(jsCode, ctx, baseUrl: baseUrl, result: body);
      if (jsResult == null || jsResult.isEmpty) return [];

      // JS might return a JSON array of objects
      try {
        final arr = _parseJson(jsResult);
        if (arr is List) {
          return arr.whereType<Map>().map((item) {
            final row = <String, String>{};
            for (final entry in fieldRules.entries) {
              final val = item[entry.key];
              if (val != null) row[entry.key] = val.toString();
            }
            return row;
          }).where((r) => r.isNotEmpty).toList();
        }
      } catch (_) {}
      return [];
    }

    // Check if any field rules contain JS
    final hasJsFields = fieldRules.values.any((v) => JsHandler.isJsRule(v));

    if (!hasJsFields) {
      return extractTable(body, listSelector, fieldRules, context: context);
    }

    // Extract elements first, then evaluate JS fields
    try {
      final soup = BeautifulSoup(body);
      final elements = soup.findAll(listSelector);
      final results = <Map<String, String>>[];

      for (final element in elements) {
        final row = <String, String>{};
        for (final entry in fieldRules.entries) {
          try {
            final parsed = _parseRule(entry.value);
            if (parsed.jsCode != null) {
              final ctx = context ?? RuleContext();
              final jsResult = await _jsHandler.execute(parsed.jsCode!, ctx, baseUrl: baseUrl, result: element.outerHtml);
              if (jsResult != null && jsResult.isNotEmpty) {
                row[entry.key] = jsResult;
              }
            } else {
              final child = parsed.selector.isEmpty
                  ? element
                  : element.find(parsed.selector);
              if (child != null) {
                var value = _extractAttribute(child, parsed.attribute);
                for (final filter in parsed.filters) {
                  value = _applyFilter(value, filter);
                }
                row[entry.key] = value;
              }
            }
          } catch (_) {}
        }
        if (row.isNotEmpty) results.add(row);
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Parse JSON string helper.
  static dynamic _parseJson(String s) => jsonDecode(s);

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

    // Parse Legado index notation: "a.1" means second <a> tag, ".item.0" means first .item
    int elementIndex = 0;
    final indexMatch = RegExp(r'\.(\d+)$').firstMatch(selector);
    if (indexMatch != null) {
      elementIndex = int.parse(indexMatch.group(1)!);
      selector = selector.substring(0, indexMatch.start);
    }

    return _ParsedRule(
      selector: selector,
      attribute: attribute,
      filters: filters,
      elementIndex: elementIndex,
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
  final int elementIndex;
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
    this.elementIndex = 0,
    this.jsonPathRule,
    this.xpathRule,
    this.allInOneRegex,
    this.onlyOneRule,
    this.purifyRule,
    this.jsCode,
    this.putKey,
  });
}
