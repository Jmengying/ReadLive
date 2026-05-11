import 'package:json_path/json_path.dart';

/// Handles JSONPath-based rule extraction from JSON data.
///
/// Uses the `json_path` package (v0.7.x) to evaluate JSONPath expressions
/// against parsed JSON structures. Many API-based Legado book sources use
/// JSONPath to extract data from JSON responses.
class JsonpathHandler {
  /// Extract a single text value from JSON data using a JSONPath expression.
  ///
  /// Returns the first matching value as a string, or `null` if no match
  /// is found. The [jsonPathRule] may optionally start with `@json:` prefix
  /// which will be stripped before evaluation.
  String? extractText(dynamic jsonData, String jsonPathRule) {
    final path = _cleanRule(jsonPathRule);
    try {
      final matches = JsonPath(path).read(jsonData);
      if (matches.isEmpty) return null;
      final value = matches.first.value;
      if (value == null) return null;
      return value.toString();
    } catch (_) {
      return null;
    }
  }

  /// Extract a list of text values from JSON data using a JSONPath expression.
  ///
  /// Returns all matching values as strings. Returns an empty list if no
  /// matches are found or on error.
  List<String> extractList(dynamic jsonData, String jsonPathRule) {
    final path = _cleanRule(jsonPathRule);
    try {
      final matches = JsonPath(path).read(jsonData);
      return matches
          .map((m) => m.value?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Check whether a rule string looks like a JSONPath expression.
  ///
  /// Returns `true` if the trimmed rule starts with `$.` or `@json:`.
  static bool isJsonPath(String rule) {
    final trimmed = rule.trim();
    return trimmed.startsWith(r'$.') || trimmed.startsWith('@json:');
  }

  /// Remove `@json:` prefix if present.
  String _cleanRule(String rule) {
    if (rule.startsWith('@json:')) {
      return rule.substring(6).trim();
    }
    return rule;
  }
}
