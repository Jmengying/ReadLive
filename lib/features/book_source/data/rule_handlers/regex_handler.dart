class RegexHandler {
  /// AllInOne: extract all matches. Used in list rules, prefixed with `:`.
  List<String> extractAllInOne(String content, String regexPattern) {
    try {
      final regex = RegExp(regexPattern);
      return regex.allMatches(content).map((m) {
        return m.groupCount > 0 ? (m.group(1) ?? m.group(0)!) : m.group(0)!;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// OnlyOne: take first match and replace. Format: ##regex##replacement###
  String applyOnlyOne(String content, String regex, String replacement) {
    try {
      final match = RegExp(regex).firstMatch(content);
      if (match == null) return content;
      return _applyReplacement(match, replacement);
    } catch (_) {
      return content;
    }
  }

  /// Purification: loop replace until no match. Format: ##regex##replacement
  String applyPurify(String content, String regex, String replacement) {
    try {
      var result = content;
      var prev = '';
      while (prev != result) {
        prev = result;
        result = result.replaceAll(RegExp(regex), replacement);
      }
      return result;
    } catch (_) {
      return content;
    }
  }

  String _applyReplacement(RegExpMatch match, String replacement) {
    var result = replacement;
    for (var i = 1; i <= match.groupCount; i++) {
      result = result.replaceAll('\$$i', match.group(i) ?? '');
    }
    return result;
  }

  static bool isAllInOne(String rule) {
    return rule.trim().startsWith(':');
  }

  static bool isOnlyOne(String rule) {
    return RegExp(r'^##.+##.*###$').hasMatch(rule.trim());
  }

  static bool isPurify(String rule) {
    final trimmed = rule.trim();
    return RegExp(r'^##.+##').hasMatch(trimmed) &&
        !RegExp(r'###$').hasMatch(trimmed);
  }

  static ({String regex, String replacement})? parseOnlyOneRule(String rule) {
    final match = RegExp(r'^##(.+?)##(.*)###$').firstMatch(rule.trim());
    if (match == null) return null;
    return (regex: match.group(1)!, replacement: match.group(2)!);
  }

  static ({String regex, String replacement})? parsePurifyRule(String rule) {
    final match = RegExp(r'^##(.+?)##(.*)$').firstMatch(rule.trim());
    if (match == null) return null;
    return (regex: match.group(1)!, replacement: match.group(2)!);
  }
}
