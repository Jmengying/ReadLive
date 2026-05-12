# Legado 搜索功能完整重构设计

**日期**: 2026-05-12
**状态**: 待批准

## 背景

当前 ReadLive 的在线搜索功能基本无法使用，主要原因：

1. **POST 请求解析错误** — `SearchNotifier.search()` 中 `@post:` 处理按逗号分割，但 Legado POST body 格式是 `@post:url,body`，body 可能包含逗号
2. **搜索关键词未 URL 编码** — `{{key}}` 被原样替换，但搜索词需要 `Uri.encodeComponent`
3. **不支持源级请求头** — 部分 Legado 书源需要 `@Header:` 自定义请求头
4. **无逐源 RuleContext** — 每个源搜索应有独立的上下文用于 `@put/@get`
5. **串行搜索** — 使用 `for...await` 逐个搜索，应并行
6. **无取消功能** — 无法停止正在进行的搜索
7. **UI 过于简陋** — 无按源分组、无逐源加载/错误状态
8. **SwitchSourceSheet 也有相同问题** — 共用了同样 broken 的搜索逻辑

## 设计目标

完全兼容 Legado 的搜索流程：
- 正确解析 Legado 搜索 URL 格式（GET/POST/自定义头/JSON body）
- 并行查询所有启用的书源
- 每个源独立的加载/成功/失败状态
- 结果按源分组展示
- 支持搜索取消
- 增量显示结果（源返回即显示）

## 文件变更

```
新增:
  lib/features/book_source/data/search_service.dart    # 核心搜索服务

修改:
  lib/features/book_source/presentation/book_source_provider.dart  # SearchNotifier 重写
  lib/features/book_source/presentation/search_page.dart           # 分组 UI
  lib/features/book_source/presentation/switch_source_sheet.dart   # 使用新搜索服务
  lib/features/book_source/domain/source_rule.dart                 # SearchRule 加 headers
  lib/features/book_source/data/content_extractor.dart             # 支持 JSON 搜索结果
  lib/features/book_source/data/rule_parser.dart                   # URL 编码 {{key}}
  lib/features/book_source/data/html_fetcher.dart                  # 支持自定义 headers
```

## 1. SearchService — 核心搜索服务

新建 `search_service.dart`，封装单个书源的搜索逻辑。

```dart
class SearchService {
  final HtmlFetcher _fetcher;
  final ContentExtractor _extractor;
  final RuleParser _parser;

  /// 搜索单个书源，返回结果列表。
  /// 支持取消 via CancelToken。
  Future<List<SearchResult>> searchSource({
    required BookSourceEntity source,
    required String keyword,
    RuleContext? context,
    CancelToken? cancelToken,
  }) async {
    final rule = source.parseRule();
    if (rule.search == null) return [];

    // 1. 解析搜索 URL 模板
    final resolved = _resolveSearchUrl(
      rule.search!.url,
      keyword,
      source.host,
      context: context,
    );

    // 2. 发送请求
    final String body;
    if (resolved.isPost) {
      body = await _fetcher.post(
        resolved.url,
        data: resolved.body,
        headers: resolved.headers,
        cancelToken: cancelToken,
      );
    } else {
      body = await _fetcher.fetch(
        resolved.url,
        headers: resolved.headers,
        cancelToken: cancelToken,
      );
    }

    // 3. 提取结果
    return _extractor.extractSearchResults(
      body, rule.search!, source.id, source.name,
      context: context,
    );
  }
}
```

### 搜索 URL 解析

Legado 的 `searchUrl` 格式：

| 格式 | 示例 |
|------|------|
| GET | `https://example.com/search?q={{key}}&page={{page}}` |
| POST form | `@post:https://example.com/search,q={{key}}&page={{page}}` |
| POST JSON | `@post:https://example.com/api/search,{"q":"{{key}}","page":{{page}}}` |
| 自定义头 | `@Header:Cookie=xxx\nhttps://...` 或在 JSON 的 `header` 字段 |

解析逻辑：

```dart
_ResolvedSearchUrl _resolveSearchUrl(
  String searchUrlTemplate,
  String keyword,
  String host, {
  RuleContext? context,
}) {
  var url = searchUrlTemplate;
  Map<String, String>? headers;
  bool isPost = false;
  String? body;

  // 1. 提取 @Header: 部分
  if (url.startsWith('@Header:')) {
    final headerEnd = url.indexOf('\n');
    if (headerEnd > 0) {
      final headerStr = url.substring(8, headerEnd);
      headers = _parseHeaderString(headerStr);
      url = url.substring(headerEnd + 1).trim();
    }
  }

  // 2. 检测 @post: 前缀
  if (url.startsWith('@post:')) {
    isPost = true;
    url = url.substring(6);
    // 分离 URL 和 body（第一个逗号后的内容）
    final commaIdx = url.indexOf(',');
    if (commaIdx > 0) {
      body = url.substring(commaIdx + 1).trim();
      url = url.substring(0, commaIdx).trim();
    }
  }

  // 3. 模板变量替换（URL 和 body 都要替换）
  final variables = {'key': keyword, 'page': '1'};
  url = _parser.resolveTemplate(url, variables, context: context);
  if (body != null) {
    body = _parser.resolveTemplate(body, variables, context: context);
  }

  // 4. 解析相对 URL
  url = resolveUrl(host, url);

  return _ResolvedSearchUrl(
    url: url,
    isPost: isPost,
    body: body,
    headers: headers,
  );
}
```

## 2. RuleParser — URL 编码修复

在 `resolveTemplate()` 中，`{{key}}` 替换时自动 URL 编码：

```dart
// 简单变量替换（key 特殊处理：URL 编码）
for (final entry in variables.entries) {
  var value = entry.value;
  // key 变量自动 URL 编码（因为搜索词会被拼入 URL）
  if (entry.key == 'key') {
    value = Uri.encodeComponent(value);
  }
  result = result.replaceAll('{{${entry.key}}}', value);
}
```

注意：`{{java.encodeURI(key)}}` 已经显式编码，保持不变。`{{key}}` 也自动编码是安全的，因为搜索词在 URL 中必须编码。

## 3. SearchRule — 增加 headers 字段

在 `source_rule.dart` 的 `SearchRule` 中增加 `headers` 字段：

```dart
class SearchRule {
  final String url;
  final String list;
  final String? bookName;
  final String? author;
  final String? cover;
  final String? intro;
  final String? bookUrl;
  final String? nextPage;
  final String? headers;  // 新增：自定义请求头
  // ...
}
```

Legado JSON 的 `searchUrl` 字段可以包含 `@Header:` 前缀，也可以在 `ruleSearch.header` 字段中指定。

## 4. ContentExtractor — JSON 搜索结果支持

部分 API 类书源返回 JSON 而非 HTML。`extractSearchResults` 需要检测响应类型：

```dart
List<SearchResult> extractSearchResults(
  String body,
  SearchRule rule,
  String sourceId,
  String sourceName, {
  RuleContext? context,
}) {
  // 检测是否为 JSON 响应
  final trimmed = body.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final jsonData = jsonDecode(trimmed);
      return _extractSearchResultsFromJson(
        jsonData, rule, sourceId, sourceName, context: context,
      );
    } catch (_) {
      // JSON 解析失败，尝试 HTML 解析
    }
  }

  // 原有的 HTML 解析逻辑
  return _extractSearchResultsFromHtml(
    body, rule, sourceId, sourceName, context: context,
  );
}
```

JSON 搜索结果提取使用已有的 `JsonpathHandler`。

## 5. SearchNotifier — 重写状态管理

```dart
// 每个源的搜索状态
class SourceSearchState {
  final String sourceId;
  final String sourceName;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SourceSearchState({
    required this.sourceId,
    required this.sourceName,
    this.results = const [],
    this.isLoading = true,
    this.error,
  });
}

// 整体搜索状态
class SearchState {
  final String query;
  final List<SourceSearchState> sourceStates;
  final bool isLoading;
  final bool isCancelled;

  const SearchState({
    this.query = '',
    this.sourceStates = const [],
    this.isLoading = false,
    this.isCancelled = false,
  });

  /// 所有结果（扁平化，兼容旧接口）
  List<SearchResult> get results =>
    sourceStates.expand((s) => s.results).toList();

  /// 正在搜索的源数量
  int get loadingCount =>
    sourceStates.where((s) => s.isLoading).length;

  /// 已完成的源数量
  int get completedCount =>
    sourceStates.where((s) => !s.isLoading).length;
}
```

搜索逻辑：

```dart
Future<void> search(String query) async {
  if (query.trim().isEmpty) return;

  _cancelToken?.cancel(); // 取消上一次搜索
  _cancelToken = CancelToken();

  final sources = await _repo.getEnabledSources();
  state = SearchState(
    query: query,
    isLoading: true,
    sourceStates: sources.map((s) => SourceSearchState(
      sourceId: s.id,
      sourceName: s.name,
    )).toList(),
  );

  // 并行搜索所有源
  final futures = sources.map((source) => _searchOneSource(
    source, query, _cancelToken!,
  ));

  await Future.wait(futures, eagerError: false);

  if (!_cancelToken!.isCancelled) {
    state = SearchState(
      query: state.query,
      sourceStates: state.sourceStates,
      isLoading: false,
    );
  }
}

Future<void> _searchOneSource(
  BookSourceEntity source,
  String keyword,
  CancelToken cancelToken,
) async {
  try {
    final context = RuleContext();
    final results = await _service.searchSource(
      source: source,
      keyword: keyword,
      context: context,
      cancelToken: cancelToken,
    );

    _updateSourceState(source.id, (s) => SourceSearchState(
      sourceId: s.sourceId,
      sourceName: s.sourceName,
      results: results,
      isLoading: false,
    ));
  } catch (e) {
    if (e is DioException && e.type == DioExceptionType.cancel) return;
    _updateSourceState(source.id, (s) => SourceSearchState(
      sourceId: s.sourceId,
      sourceName: s.sourceName,
      isLoading: false,
      error: e.toString(),
    ));
  }
}

void cancel() {
  _cancelToken?.cancel();
  state = SearchState(
    query: state.query,
    sourceStates: state.sourceStates.map((s) =>
      s.isLoading ? SourceSearchState(
        sourceId: s.sourceId,
        sourceName: s.sourceName,
        isLoading: false,
        error: '已取消',
      ) : s
    ).toList(),
    isLoading: false,
    isCancelled: true,
  );
}
```

## 6. SearchPage — 分组 UI

搜索结果按源分组展示，类似 Legado：

```
┌─────────────────────────────┐
│ [搜索框]              [取消] │
├─────────────────────────────┤
│ ▼ 笔趣阁 (3条)         ⏳  │  ← 正在搜索
│   斗破苍穹 · 天蚕土豆       │
│   武动乾坤 · 天蚕土豆       │
│   元尊 · 天蚕土豆           │
│ ▼ 起点中文网 (2条)     ✓   │  ← 已完成
│   斗破苍穹 · 天蚕土豆       │
│   大主宰 · 天蚕土豆         │
│ ▼ 书源C                ✗   │  ← 失败
│   (请求超时)                │
└─────────────────────────────┘
```

每个源组：
- 可折叠/展开（默认展开有结果的）
- 显示源名称 + 结果数量
- 加载中显示 spinner
- 失败显示错误信息（灰色文字）
- 点击结果进入详情页

## 7. HtmlFetcher — headers 支持

`HtmlFetcher.fetch()` 和 `post()` 已有 `headers` 参数，但需要确保与源级 headers 合并：

```dart
// 在 SearchService 中调用时传递源级 headers
final mergedHeaders = {
  ...?sourceHeaders,  // 源定义的 headers
};
body = await _fetcher.fetch(url, headers: mergedHeaders, cancelToken: cancelToken);
```

## 8. SwitchSourceSheet — 复用 SearchService

`SwitchSourceSheet` 中的搜索逻辑改为使用 `SearchService`，避免代码重复：

```dart
final service = ref.read(searchServiceProvider);
final results = await service.searchSource(
  source: source,
  keyword: widget.bookTitle,
  cancelToken: cancelToken,
);
```

## 测试计划

1. **单元测试**: `search_service_test.dart`
   - URL 模板解析：GET、POST form、POST JSON、@Header
   - `{{key}}` URL 编码
   - JSON 响应解析
   - HTML 响应解析
   - 取消搜索

2. **集成测试**: 用实际 Legado 书源验证完整搜索流程
   - 并行搜索多个源
   - 增量结果显示
   - 错误源不影响其他源

## 不在范围内

- 搜索历史记录
- 搜索建议/自动补全
- 搜索结果分页加载
- 按类型（小说/漫画）过滤搜索结果
