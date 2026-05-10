# ReadLive — 小说阅读器设计文档

## 一、项目概述

ReadLive 是一款纯本地优先、跨 Android/iOS 的小说阅读器，核心为本地阅读 + 自定义书源（网络小说抓取），无广告、无付费墙、无强制联网，仅书源功能按需联网，适配双平台。

### 核心目标

1. 纯本地优先 + 自定义书源（网络解析）双模式
2. 无付费、无云端、无广告、无数据上传
3. 跨 Android/iOS 一致体验（桌面端可测试）

## 二、技术栈

| 类别 | 选型 | 说明 |
|------|------|------|
| 框架 | Flutter 3.x (Dart) | 跨平台，一套代码运行 Android/iOS/Windows/macOS/Linux |
| 状态管理 | Riverpod 2.x | 轻量、可测试、支持异步 |
| 数据库 | drift (SQLite ORM) | 类型安全，支持迁移 |
| 路由 | go_router | 声明式路由 |
| 网络 | dio | 拦截器、UA、编码、超时 |
| EPUB | epubx + 自定义渲染 | 结构解析 + 自定义排版 |
| 文件选择 | file_picker | 本地文件导入 |
| TTS | flutter_tts | 系统 TTS 引擎朗读 |

## 三、架构设计

### Clean Architecture + Feature-first

```
lib/
├── core/                 # 公共基础
│   ├── database/         # drift 数据库定义
│   ├── network/          # dio HTTP 客户端
│   ├── utils/            # 工具类
│   ├── theme/            # 主题系统
│   └── router/           # go_router 路由
├── features/
│   ├── bookshelf/        # 书架/书库
│   │   ├── data/         # Repository 实现
│   │   ├── domain/       # 实体、用例
│   │   └── presentation/ # 页面、组件、Provider
│   ├── reader/           # 阅读器
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── book_source/      # 书源管理
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── settings/         # 设置
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── backup/           # 备份恢复
│       ├── data/
│       ├── domain/
│       └── presentation/
└── app.dart
```

### 状态管理 (Riverpod)

```
providers/
├── database_provider.dart      # Database 实例
├── bookshelf_provider.dart     # 书架状态
│   ├── booksProvider           # 书籍列表 (Stream)
│   ├── filteredBooksProvider   # 按类型筛选 (novel/manga)
│   └── bookshelfActionsProvider # 增删改操作
├── reader_provider.dart        # 阅读器状态
│   ├── currentBookProvider     # 当前书籍
│   ├── chaptersProvider        # 章节列表
│   ├── currentPageProvider     # 当前页内容
│   ├── readingProgressProvider # 阅读进度
│   └── readerSettingsProvider  # 阅读设置
├── book_source_provider.dart   # 书源状态
│   ├── bookSourcesProvider     # 书源列表
│   ├── searchResultsProvider   # 搜索结果
│   └── sourceEngineProvider    # 规则引擎实例
├── settings_provider.dart      # 全局设置
│   ├── themeProvider           # 主题模式
│   ├── localeProvider          # 语言
│   └── generalSettingsProvider # 通用设置
└── stats_provider.dart         # 阅读统计
    ├── dailyStatsProvider      # 每日统计
    └── totalStatsProvider      # 总计统计
```

依赖关系通过 Riverpod Provider 自动注入，Stream 驱动 UI 更新。

## 四、数据模型

### books（书籍）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| title | TEXT | 书名 |
| author | TEXT | 作者 |
| cover_path | TEXT | 本地封面路径 |
| file_path | TEXT | 本地文件路径 |
| source_id | TEXT (FK) | 来源书源ID，NULL=本地 |
| book_url | TEXT | 网络书籍URL |
| content_type | TEXT | novel/manga |
| last_read_at | INTEGER | 最后阅读时间戳 |
| progress | REAL | 0.0-1.0 阅读进度 |
| created_at | INTEGER | 创建时间 |
| updated_at | INTEGER | 更新时间 |

### chapters（章节）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| book_id | TEXT (FK) | 关联书籍 |
| title | TEXT | 章节标题 |
| url | TEXT | 网络章节URL |
| content | TEXT | 正文内容（网络来源缓存） |
| index | INTEGER | 章节序号 |
| is_cached | INTEGER | 是否已缓存 |
| created_at | INTEGER | 创建时间 |

### bookmarks（书签/笔记/高亮）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| book_id | TEXT (FK) | 关联书籍 |
| chapter_id | TEXT (FK) | 关联章节 |
| position | INTEGER | 字符偏移 |
| content_preview | TEXT | 预览文本 |
| note | TEXT | 笔记内容 |
| highlight_color | TEXT | 高亮颜色 |
| type | TEXT | bookmark/highlight/note |
| created_at | INTEGER | 创建时间 |

### book_sources（书源）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| name | TEXT | 书源名称 |
| host | TEXT | 域名 |
| content_type | TEXT | novel/manga |
| enabled | INTEGER | 0/1 启用状态 |
| weight | INTEGER | 优先级权重 |
| rule_json | TEXT | 完整JSON规则 |
| status | TEXT | active/error/disabled |
| last_tested_at | INTEGER | 最后测试时间 |
| group_name | TEXT | 分组名称 |
| created_at | INTEGER | 创建时间 |

### reading_stats（阅读统计）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT (UUID) | 主键 |
| book_id | TEXT (FK) | 关联书籍 |
| date | TEXT | YYYY-MM-DD |
| duration_seconds | INTEGER | 阅读时长(秒) |
| characters_read | INTEGER | 阅读字数 |

### settings（设置）

| 字段 | 类型 | 说明 |
|------|------|------|
| key | TEXT | 主键 |
| value | TEXT | 值 |

## 五、书源规则引擎

### 书源规则 JSON 格式

```json
{
  "id": "uuid",
  "name": "书源名称",
  "host": "https://xxx.com",
  "contentType": "novel",
  "enabled": true,
  "weight": 100,
  "search": {
    "url": "https://xxx/search?kw={{key}}&page={{page}}",
    "list": ".result-item",
    "bookName": ".title@text",
    "author": ".author@text",
    "cover": ".img@src",
    "intro": ".desc@text",
    "bookUrl": ".title@href"
  },
  "bookInfo": {
    "cover": ".cover@src",
    "intro": ".intro@text",
    "author": ".author@text",
    "tocUrl": "{{bookUrl}}/catalog"
  },
  "toc": {
    "list": ".chapter li a",
    "name": "@text",
    "url": "@href"
  },
  "content": {
    "content": ".content@text|trim|removeAd",
    "nextPage": ".next@href",
    "encoding": "utf-8"
  }
}
```

### 引擎架构

```
BookSourceEngine
├── RuleParser          # 规则解析器
│   ├── CSS 选择器解析 (.class, #id, tag)
│   ├── 属性提取 (@text, @href, @src)
│   ├── 过滤器 (|trim, |removeAd, |replace)
│   └── 模板变量 ({{key}}, {{bookUrl}})
├── HtmlFetcher         # HTTP 请求器
│   ├── UA 管理
│   ├── 编码处理 (UTF-8, GBK, GB2312)
│   ├── 超时/重试 (3次，指数退避)
│   └── Cookie 管理
├── ContentExtractor    # 内容提取器
│   ├── 搜索结果列表提取
│   ├── 书籍详情提取
│   ├── 目录提取
│   ├── 正文提取
│   └── 广告/导航过滤
└── SourceManager       # 书源管理
    ├── 多源并行搜索
    ├── 结果合并去重
    ├── 换源匹配
    └── 书源校验/测速
```

### 规则语法

| 语法 | 说明 | 示例 |
|------|------|------|
| CSS选择器 | 元素定位 | `.title`, `#content`, `div.chapter` |
| @text | 提取文本 | `.title@text` |
| @href | 提取链接 | `a@href` |
| @src | 提取图片 | `img@src` |
| @attr | 提取属性 | `data-id@attr` |
| \|trim | 去除空白 | `@text\|trim` |
| \|removeAd | 广告过滤 | `@text\|removeAd` |
| \|replace | 文本替换 | `@text\|replace(a,b)` |
| {{变量}} | 模板变量 | `{{key}}`, `{{bookUrl}}`, `{{page}}` |

### 异常处理
- 网络超时：自动重试 3 次，指数退避
- 编码检测：自动检测 + 手动指定
- 解析失败：标记书源状态为 error，跳过继续
- 反盗链：支持 Referer、Cookie 传递

## 六、阅读器引擎

### 核心架构

```
ReaderEngine
├── FormatParser (格式解析器)
│   ├── TxtParser     # 纯文本解析，自动分章
│   ├── EpubParser    # EPUB 结构解析 (epubx)
│   ├── PdfParser     # PDF 渲染 (后期)
│   └── MobiParser    # MOBI 解析 (后期)
├── ContentRenderer (内容渲染器)
│   ├── TextRenderer   # 小说文本排版
│   │   ├── 分页算法（按屏幕高度计算）
│   │   ├── 段落排版（缩进、间距、对齐）
│   │   ├── 字体渲染（字号、字重、字体）
│   │   └── 翻页动画（淡入、仿真、平移、滚动）
│   └── ImageRenderer  # 漫画图片渲染 (后期)
├── ProgressManager (进度管理)
│   ├── 自动保存（翻页时）
│   ├── 手动跳转（章节/百分比）
│   └── 跨设备同步（通过备份）
└── ReadingSettings (阅读设置)
    ├── 字体/字号/字重
    ├── 行间距/段间距/字间距
    ├── 首行缩进/对齐方式
    ├── 背景色/背景图/文字颜色
    ├── 翻页效果/方向/速度
    ├── 亮度/色温/护眼
    └── 夜间模式
```

### 分页算法

1. 获取屏幕可用区域 (宽高)
2. 根据字号、行间距计算每行字数
3. 根据段间距、行间距计算每页行数
4. 将正文按段落拆分，逐段排版
5. 当一页排满时，记录断点，开始新页
6. 生成 PageList: [{startIndex, endIndex, lines[]}]

### TXT 自动分章策略

- 优先匹配正则：`第[零一二三四五六七八九十百千万\d]+[章节回卷集部篇]`
- 备选：按固定字数分章（如每 5000 字）
- 支持手动合并/拆分章节

### 翻页效果

| 效果 | 实现方式 |
|------|----------|
| 淡入 | AnimatedOpacity + SlideTransition |
| 仿真 | CustomClipper + Transform（拟真翻页） |
| 平移 | SlideTransition (左右/上下) |
| 滚动 | ListView.continuous |
| 无动画 | 直接切换 |

## 七、页面结构与导航

### 底部导航栏（2个Tab）

| Tab | 图标 | 说明 |
|-----|------|------|
| 书架 | book | 书籍列表（顶部切换小说/漫画） |
| 我的 | person | 个人中心/设置 |

### 书架页面

```
BookshelfPage
├── 顶部 TabBar: [小说] [漫画]
├── 搜索入口
├── 分类筛选（全部/本地/书源）
├── 书架列表（网格/列表视图）
└── 批量管理
```

### 个人中心页面

```
ProfilePage
├── 阅读统计（时长、本数、进度）
├── 外观定制（主题、字体、配色）
├── 阅读偏好设置
├── 书源管理（从底部导航移至此处）
├── 本地备份/恢复
├── 本地文件导入
├── 帮助与关于
└── 隐私设置
```

### 路由表

| 路由 | 页面 | 说明 |
|------|------|------|
| / | BookshelfPage | 书架（小说） |
| /manga | BookshelfPage | 书架（漫画） |
| /profile | ProfilePage | 个人中心 |
| /reader/:bookId | ReaderPage | 阅读器（全屏） |
| /book/:bookId | BookDetailPage | 书籍详情 |
| /search | SearchPage | 搜索 |
| /sources | BookSourcePage | 书源管理 |
| /bookmarks/:bookId | BookmarksPage | 书签/笔记 |
| /settings/* | SettingsPages | 设置子页面 |

## 八、阅读界面UI

### 阅读器页面布局

```
ReaderPage (全屏沉浸式)
├── 顶部工具栏（点击屏幕中央区域显示/隐藏）
│   ├── 返回按钮 ←
│   ├── 书籍标题（点击展开章节列表）
│   └── 功能图标区
│       ├── 🔊 朗读 (TTS)
│       ├── 🔖 书签
│       ├── ⏯ 播放/暂停
│       ├── 📝 笔记
│       ├── 🔒 锁定
│       ├── 🔆 屏幕常亮
│       └── ⋮ 更多菜单
├── 正文阅读区
│   ├── 点击区域
│   │   ├── 中央 → 显示/隐藏工具栏（解锁状态）
│   │   ├── 左侧 → 上一页（解锁状态）
│   │   ├── 右侧 → 下一页（解锁状态）
│   │   └── 双击 → 解锁（锁定状态）/ 全屏切换（解锁状态）
│   └── 长按 → 选中文本
└── 底部控制栏（与顶部联动显示/隐藏）
    ├── 目录按钮 → 侧边栏展开章节列表
    ├── 阅读进度条（可拖动跳转）
    ├── 上一章/下一章
    ├── 笔记按钮
    ├── 🌙 夜间模式切换
    ├── 🔒 锁定按钮
    ├── ⚙ 设置按钮 → 展开设置面板
    └── 🔍 书籍内搜索
```

### 阅读锁定机制

| 状态 | 单击 | 双击 | 滑动 | 长按 |
|------|------|------|------|------|
| 解锁（默认） | 中央:工具栏 / 左右:翻页 | 全屏切换 | 翻页/亮度/字号 | 选中文本 |
| 锁定 | 无反应 | 解锁 | 翻页/亮度/字号 | 选中文本 |

- 锁定入口：顶部/底部工具栏的锁定按钮
- 锁定提示：顶部显示半透明锁定图标，2秒后自动消失
- 锁定时保留滑动翻页和长按选中，仅屏蔽单击触发工具栏

### 阅读设置面板（底部弹出）

```
ReadingSettingsPanel (BottomSheet)
├── 亮度与护眼
│   ├── 亮度滑块（跟随系统/手动）
│   ├── 护眼模式开关
│   └── 色温调节
├── 字体与字号
│   ├── 字号滑块 (12-30) + Aa +/- 按钮
│   ├── 字体选择（内置 + 自定义导入 TTF/OTF）
│   └── 字重调节
├── 背景与主题
│   ├── 预设背景色（暖白、米黄、浅绿、深灰、纯黑）
│   ├── 自定义背景图
│   └── 文字颜色适配
├── 翻页效果
│   ├── 效果选择（淡入/仿真/平移/滚动/无）
│   ├── 方向（左→右/右→左/上下滚动）
│   └── 速度调节
└── 更多设置入口 → 排版/手势/朗读/统计等
```

### 手势交互

| 手势 | 解锁状态（默认） | 锁定状态 |
|------|------------------|----------|
| 左侧点击 | 上一页 | 无反应 |
| 右侧点击 | 下一页 | 无反应 |
| 中央点击 | 显示/隐藏工具栏 | 无反应 |
| 双击 | 全屏切换 | 解锁 |
| 左右滑动 | 翻页 | 翻页 |
| 上下滑动 | 亮度/字号调节 | 亮度/字号调节 |
| 长按 | 选中文本 | 选中文本 |
| 双指缩放 | 字号调节 | 字号调节 |

### 自动隐藏
- 工具栏显示后，无操作 3 秒自动隐藏
- 翻页时立即隐藏工具栏
- 设置面板打开时不自动隐藏

## 九、核心依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  go_router: ^14.x
  dio: ^5.x
  epubx: ^3.x
  file_picker: ^8.x
  path_provider: ^2.x
  path: ^1.x
  cached_network_image: ^3.x
  flutter_svg: ^2.x
  uuid: ^4.x
  intl: ^0.19.x
  shared_preferences: ^2.x
  json_annotation: ^4.x
  flutter_tts: ^3.x
  wakelock_plus: ^1.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.x
  riverpod_generator: ^2.x
  drift_dev: ^2.x
  json_serializable: ^6.x
  freezed_annotation: ^2.x
  freezed: ^2.x
  flutter_lints: ^3.x
```

### 项目配置
- Flutter 3.19+ / Dart 3.3+
- Android: minSdkVersion 21, targetSdkVersion 34
- iOS: 12.0+
- 桌面: Windows/macOS/Linux（开发测试用）

## 十、MVP 分阶段计划

### Phase 1 — 骨架 + 本地阅读（核心可用）
- 项目脚手架、路由、主题系统
- 本地文件导入（TXT/EPUB）
- 基础阅读器（排版、翻页、进度保存）
- 书架管理（列表、删除、分类）
- 基础设置（深色/浅色模式）

### Phase 2 — 书源引擎
- 书源规则解析引擎
- 书源管理页面（CRUD、导入导出）
- 书源搜索 + 书籍详情 + 目录获取
- 正文解析 + 广告过滤
- 章节缓存

### Phase 3 — 阅读体验增强
- 阅读设置面板（字体、背景、翻页效果、排版）
- 书签、笔记、高亮
- 夜间模式、护眼模式
- 手势自定义、阅读锁定
- TTS 语音朗读

### Phase 4 — 完善与优化
- 更多格式支持（PDF/MOBI/CBZ/CBR）
- 备份恢复
- 换源功能
- 性能优化
- 统计功能

## 十一、性能要求

- 启动时间 ≤ 2s
- 打开书籍 ≤ 1s
- 解析稳定，内存可控
- 崩溃率 ≤ 0.1%

## 十二、隐私与合规

- 无数据上传，仅书源联网，可全局禁网
- 用户自行导入书源，责任自负
- 支持黑名单、违规书源举报、一键禁用
