import 'dart:math';
import 'package:beautiful_soup_dart/beautiful_soup.dart';

class RuleParser {
  /// Resolve template variables like {{key}} in a string.
  /// Handles Legado patterns: {{key}}, {{java.encodeURI(key)}}, {{(page-1)*10}}, etc.
  String resolveTemplate(String template, Map<String, String> variables) {
    var result = template;

    // Handle {{java.encodeURI(key)}} and similar
    result = result.replaceAllMapped(
      RegExp(r'\{\{java\.encodeURI\((\w+)\)\}\}'),
      (m) => Uri.encodeComponent(variables[m.group(1)] ?? ''),
    );

    // Handle {{java.put('key', value)}} - just remove these blocks
    result = result.replaceAll(RegExp(r"\{\{java\.put\([^)]*\)\}\}"), '');

    // Handle simple variable substitution
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }

    // Handle simple math expressions like {{(page - 1) * 10}}
    result = result.replaceAllMapped(
      RegExp(r'\{\{([^{}]+?)\}\}'),
      (m) {
        final expr = m.group(1)!.trim();
        // Try to evaluate simple math with variable substitution
        try {
          var mathExpr = expr;
          for (final entry in variables.entries) {
            mathExpr = mathExpr.replaceAll(entry.key, entry.value);
          }
          // Only evaluate if it looks like a math expression
          if (RegExp(r'^[\d\s+\-*/().]+$').hasMatch(mathExpr)) {
            return _evalMath(mathExpr).toString();
          }
        } catch (_) {}
        return m.group(0)!; // Return original if can't evaluate
      },
    );

    return result;
  }

  /// Simple math expression evaluator for basic arithmetic.
  num _evalMath(String expr) {
    // Use Dart's expression evaluation for simple math
    expr = expr.replaceAll(' ', '');
    // Handle basic operations: +, -, *, /
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
      return (value, newPos + 1); // skip ')'
    }
    var end = pos;
    while (end < s.length && (s[end].contains(RegExp(r'[\d.]')))) {
      end++;
    }
    return (num.parse(s.substring(pos, end)), end);
  }

  /// Extract a single value from HTML using a rule string.
  ///
  /// Rule format: `css_selector@attribute|filter1|filter2`
  String? extractText(String html, String rule) {
    if (rule.isEmpty) return null;

    final parsed = _parseRule(rule);
    final soup = BeautifulSoup(html);
    final element = soup.find(parsed.selector);

    if (element == null) return null;

    var value = _extractAttribute(element, parsed.attribute);

    for (final filter in parsed.filters) {
      value = _applyFilter(value, filter);
    }

    return value.isEmpty ? null : value;
  }

  /// Extract a list of values from HTML.
  List<String> extractList(String html, String listSelector, String itemRule) {
    if (listSelector.isEmpty || itemRule.isEmpty) return [];

    final parsed = _parseRule(itemRule);
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
  String extractContent(String html, String rule) {
    if (rule.isEmpty) return '';

    final parsed = _parseRule(rule);

    var cleanHtml = html
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');

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
  ///
  /// [listSelector] selects the container or image elements.
  /// [itemRule] extracts the image src from each element.
  List<String> extractImageList(String html, String listSelector, String itemRule) {
    return extractList(html, listSelector, itemRule);
  }

  /// Extract structured data from a list of elements.
  List<Map<String, String>> extractTable(
    String html,
    String listSelector,
    Map<String, String> fieldRules,
  ) {
    final soup = BeautifulSoup(html);
    final elements = soup.findAll(listSelector);
    final results = <Map<String, String>>[];

    for (final element in elements) {
      final row = <String, String>{};
      for (final entry in fieldRules.entries) {
        final parsed = _parseRule(entry.value);
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
      if (row.isNotEmpty) {
        results.add(row);
      }
    }
    return results;
  }

  _ParsedRule _parseRule(String rule) {
    final parts = rule.split('|');
    final selectorAttr = parts[0].trim();
    final filters = parts.skip(1).map((f) => f.trim()).toList();

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
    );
  }

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
    if (filter == 'trim') {
      return value.trim();
    } else if (filter == 'removeAd') {
      return value
          .replaceAll(RegExp(r'(广告|推荐|百度搜索|喜欢.*?推荐|最新章节|手机阅读)'), '')
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

  const _ParsedRule({
    required this.selector,
    required this.attribute,
    required this.filters,
  });
}
