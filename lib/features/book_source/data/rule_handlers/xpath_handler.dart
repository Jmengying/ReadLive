import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

/// Handles XPath-based rule extraction from HTML content.
///
/// Uses the `xpath_selector` and `xpath_selector_html_parser` packages
/// to evaluate XPath expressions against parsed HTML.
class XpathHandler {
  /// Extract a single text value from HTML using an XPath expression.
  ///
  /// Returns the first matching value, or `null` if no match is found.
  /// The [xpathRule] may optionally start with `@XPath:` prefix which
  /// will be stripped before evaluation.
  String? extractText(String html, String xpathRule) {
    final xpath = _cleanRule(xpathRule);
    try {
      final doc = HtmlXPath.html(html);
      final result = doc.query(xpath);
      return _getFirstValue(result)?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Extract a list of text values from HTML using an XPath expression.
  ///
  /// Returns all matching values. Returns an empty list if no matches
  /// are found or on error.
  List<String> extractList(String html, String xpathRule) {
    final xpath = _cleanRule(xpathRule);
    try {
      final doc = HtmlXPath.html(html);
      final result = doc.query(xpath);
      return _getAllValues(result)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Remove `@XPath:` prefix if present.
  String _cleanRule(String rule) {
    if (rule.startsWith('@XPath:')) {
      return rule.substring(7).trim();
    }
    return rule;
  }

  /// Get the first value from an XPath result.
  ///
  /// If the XPath queried for an attribute (e.g., `/@href`), the value
  /// comes from [XPathResult.attrs]. Otherwise, it comes from the
  /// node's text content.
  String? _getFirstValue(XPathResult result) {
    // If attribute values were collected, use those
    if (result.attrs.isNotEmpty) {
      return result.attrs.firstWhere(
        (a) => a != null,
        orElse: () => null,
      );
    }
    // Otherwise use node text
    if (result.nodes.isNotEmpty) {
      return result.nodes.first.text;
    }
    return null;
  }

  /// Get all values from an XPath result.
  List<String> _getAllValues(XPathResult result) {
    // If attribute values were collected, use those
    if (result.attrs.isNotEmpty) {
      return result.attrs.whereType<String>().toList();
    }
    // Otherwise use node texts
    return result.nodes
        .map((n) => n.text ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
