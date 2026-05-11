/// 存储跨规则传递的变量（@put/@get 机制）。
class RuleContext {
  final Map<String, String> _variables = {};

  void put(String key, String value) {
    _variables[key] = value;
  }

  String get(String key) {
    return _variables[key] ?? '';
  }

  bool containsKey(String key) {
    return _variables.containsKey(key);
  }

  void clear() {
    _variables.clear();
  }

  Map<String, String> get variables => Map.unmodifiable(_variables);
}
