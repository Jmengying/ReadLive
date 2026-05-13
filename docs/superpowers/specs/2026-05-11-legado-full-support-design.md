# Legado 书源完整支持设计

**日期**: 2026-05-11
**状态**: 已批准

## 背景

当前 ReadLive 的 `RuleParser` 仅支持 CSS Selector 和基本 XPath 转换，对 Legado 书源格式的支持不完整。大量 API 类书源使用 JSONPath，高级书源依赖 JS 规则，正则提取也完全缺失。本次改动补齐所有 7 项缺失能力，使 ReadLive 能兼容绝大多数 Legado 书源。

## 新增依赖

```yaml
# pubspec.yaml
xpath_selector: ^3.0.0    # XPath 解析
json_path: ^2.0.0          # JSONPath 解析 (Jayway 兼容)
flutter_js: ^0.8.0         # JS 引擎 (QuickJS, ES2023)
gbk_codec: ^1.0.0          # GBK/GB2312/GB18030 编码
```

## 文件结构

```
lib/features/book_source/data/
  rule_parser.dart              # 路由分发 + CSS 处理 + 模板解析 (重构)
  rule_context.dart             # RuleContext: 变量存储 (@put/@get)
  rule_handlers/
    xpath_handler.dart          # XPath 规则处理
    jsonpath_handler.dart       # JSONPath 规则处理
    js_handler.dart             # JS 规则处理 (<js></js>, @js:)
    regex_handler.dart          # 正则 AllInOne + OnlyOne + 净化
```

`ContentExtractor` 增加 `RuleContext` 参数传递，其余调用链不变。

## 七项实现方案

### 1. XPath 支持

用 `xpath_selector` 包替代当前 `_xpathToCss()` 手动转换。

- 检测 `@XPath:` 或 `//` 前缀
- 直接调用 `xpath_selector` 的 API 查询 HTML 节点
- 返回匹配节点的文本/属性值
- 移除现有的 `_xpathToCss()` 方法

```dart
// xpath_handler.dart
class XpathHandler {
  String? extractText(String html, String xpathRule) { ... }
  List<String> extractList(String html, String xpathRule) { ... }
}
```

### 2. JSONPath 支持

用 `json_path` 包解析 API 响应中的 JSON 数据。

- 检测 `@json:` 或 `$.` 前缀
- 在 `ContentExtractor` 层判断：如果规则是 JSONPath 类型，先 `jsonDecode` 响应体
- 调用 `JsonPath(rule).read(jsonData)` 提取数据
- 返回字符串或字符串列表

```dart
// jsonpath_handler.dart
class JsonpathHandler {
  String? extractText(dynamic jsonData, String jsonPathRule) { ... }
  List<String> extractList(dynamic jsonData, String jsonPathRule) { ... }
}
```

`ContentExtractor` 需增加 JSON 感知的提取方法：

```dart
// content_extractor.dart 新增
String? extractFromJson(String body, String rule) {
  final data = jsonDecode(body);
  return JsonpathHandler().extractText(data, rule);
}
```

### 3. 正则 AllInOne

只能在 list 规则（搜索列表、目录列表）中使用，以 `:` 开头。

- 用 `RegExp.allMatches(content)` 提取所有匹配
- 如果正则有捕获组，取第一个捕获组作为结果
- 返回 `List<String>`

```dart
// regex_handler.dart
class RegexHandler {
  /// AllInOne: :regex_pattern
  List<String> extractAllInOne(String content, String regexPattern) {
    final regex = RegExp(regexPattern);
    return regex.allMatches(content).map((m) {
      return m.groupCount > 0 ? m.group(1)! : m.group(0)!;
    }).toList();
  }
}
```

### 4. 正则 OnlyOne / 净化

**OnlyOne** (`##regex##replacement###`)：只在详情页等单值场景使用。

- 用 `RegExp.firstMatch(content)` 取第一个匹配
- 将捕获组代入 replacement 模板（`$1`, `$2` 等）
- 返回替换后的字符串

**净化** (`##regex##replacement`)：作为 filter 处理，循环替换直到无匹配。

```dart
// regex_handler.dart
String applyOnlyOne(String content, String regex, String replacement) { ... }
String applyPurify(String content, String regex, String replacement) {
  // 循环替换直到无匹配
  var result = content;
  while (RegExp(regex).hasMatch(result)) {
    result = result.replaceAll(RegExp(regex), replacement);
  }
  return result;
}
```

### 5. JS 规则

用 `flutter_js` 包嵌入 QuickJS 引擎。

**初始化**：懒加载，首次使用时创建 JS 运行时。

**桥接对象**：在 JS 上下文中注入 `java` 对象：
- `java.ajax(url, options)` — HTTP 请求（通过 Dart 的 `dio` 转发）
- `java.put(key, value)` — 写入变量存储
- `java.get(key)` — 从变量存储读取
- `java.encodeURI(str)` — URL 编码
- `java.getCookie(url, name)` — Cookie 读取（后续实现）

**规则格式**：
- `<js>JS代码</js>` — 在任意位置使用
- `@js:JS代码` — 只能放在规则末尾
- JS 中通过 `result` 变量返回结果

```dart
// js_handler.dart
class JsHandler {
  JsEngine? _engine;

  Future<void> _ensureInitialized() async {
    _engine ??= await JsEngine.create();
  }

  Future<String?> execute(String jsCode, RuleContext context) async {
    await _ensureInitialized();
    // 注入 java 对象
    // 执行 jsCode
    // 从 result 变量取回结果
  }
}
```

### 6. URL 模板增强

增强 `RuleParser.resolveTemplate()`：

- `{{key}}` — 简单变量替换（已有）
- `{{java.encodeURI(key)}}` — URL 编码（已有）
- `{{java.get('key')}}` — 从 `RuleContext.variables` 取值（新增）
- 支持 POST 请求体解析：URL 中 `@post:` 后面的部分作为 body

```dart
// rule_parser.dart resolveTemplate() 增强
// 处理 {{java.get('key')}}
result = result.replaceAllMapped(
  RegExp(r"\{\{java\.get\(['\"](\w+)['\"]\)\}\}"),
  (m) => context.variables[m.group(1)] ?? '',
);
```

### 7. 变量 @put/@get

`RuleContext` 存储跨规则传递的变量：

```dart
// rule_context.dart
class RuleContext {
  final Map<String, String> variables = {};

  void put(String key, String value) => variables[key] = value;
  String get(String key) => variables[key] ?? '';
}
```

**@put**：规则中出现 `@put:{key=value}` 时，执行规则后将值存入 `context.put(key, value)`。

**@get**：规则中出现 `@get:{key}` 时，执行规则前用 `context.get(key)` 替换。

**java.put/get**：在 JS 规则和模板中通过桥接对象调用，操作同一个 `RuleContext.variables`。

## 规则分发流程

`RuleParser._parseRule()` 改为按优先级检测：

```
1. 检测 && / || / %% 连接符 → 拆分，递归调用
2. 检测 @json: / $. 前缀 → 标记为 JSONPath
3. 检测 @XPath: / // 前缀 → 标记为 XPath
4. 检测 <js></js> / @js: → 标记为 JS
5. 检测 :regex 前缀 → 标记为 AllInOne
6. 检测 ##regex##replacement### → 标记为 OnlyOne
7. 检测 @css: 或默认 → CSS Selector 处理
```

过滤器链中检测 `##regex##replacement`（净化）在最后统一处理。

## 编码支持

`HtmlFetcher` 中 GBK 解码：

```dart
// html_fetcher.dart
import 'package:gbk_codec/gbk_codec.dart';

String decodeBody(List<int> bytes, String? charset) {
  if (charset == 'gbk' || charset == 'gb2312' || charset == 'gb18030') {
    return gbk.decode(bytes);
  }
  return utf8.decode(bytes, allowMalformed: true);
}
```

`ContentRule.encoding` 字段已在数据模型中，传递给 `HtmlFetcher` 使用。

## 测试计划

每个 handler 独立单元测试：

1. `xpath_handler_test.dart` — 各种 XPath 表达式
2. `jsonpath_handler_test.dart` — JSON 数据提取
3. `regex_handler_test.dart` — AllInOne、OnlyOne、净化
4. `js_handler_test.dart` — JS 执行、java 对象桥接
5. `rule_parser_test.dart` — 补充连接符、变量传递、编码测试

集成测试：用实际 Legado 书源 JSON 验证完整流程（搜索 → 详情 → 目录 → 正文）。

## 不在范围内

以下功能本次不实现，后续按需添加：
- WebView 加载
- 登录流程 (loginUrl)
- Cookie 管理
- 代理支持
- 发现/探索 (exploreUrl)
