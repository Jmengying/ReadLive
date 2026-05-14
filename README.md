<div align="center">
  <img src="readlive.png"  height="240" title="Miku Stage" />
  # ReadLive
</div>


本地优先的小说与漫画阅读器，支持 Android、iOS、Windows

## 功能特性

**书架管理**
- 小说与漫画双书架，一键切换
- 书箱分组、批量删除、批量分组
- 阅读进度自动保存，支持百分比精确恢复
- 网格/列表视图切换

**阅读器**
- 翻页模式与滚动模式，支持滑动/淡入/无动画
- 字号、行高、字体、字重、段间距、首行缩进、字间距可调
- 护眼模式、夜间模式、自定义背景色/图片、亮度调节
- TTS 语音朗读，可调语速和音调
- 书签管理，支持高亮和备注
- 屏幕常亮、自定义点击翻页区域
- 双击显示/隐藏工具栏

**本地文件导入**
- EPUB、TXT、PDF、CBZ/CBR 漫画压缩包
- 自动提取封面、目录、章节内容

**在线书源**
- 兼容 Legado 书源格式，一键导入社区书源包
- 规则引擎支持 CSS 选择器、XPath、JSONPath、正则表达式、JavaScript
- 跨源搜索，并行查询所有启用的书源
- 自动识别 JSON API 响应，支持 JSONPath 提取
- GBK/GB2312/GB18030 编码自动识别
- 多页章节自动抓取，内容本地缓存

**阅读统计**
- 连续阅读天数、总阅读时间、日均阅读时长
- 7 天柱状图、30 天折线图、每本书阅读时长饼图

**个性化**
- 亮色/暗色/跟随系统主题，8 种强调色
- 自定义头像和签名
- 20+ 阅读设置持久化

## UI 设计

采用 iOS 极简风格设计：
- 侧边栏导航，内容优先
- 封面大图卡片，阅读进度一目了然
- 系统灰背景，零阴影卡片
- 线性图标，统一视觉语言

## 技术栈

- Flutter + Dart
- Riverpod 状态管理
- Drift (SQLite) 本地数据库
- GoRouter 路由
- Dio 网络请求
- flutter_js (QuickJS) JavaScript 规则引擎
- json_path JSONPath 解析

## 构建

```bash
# Android APK
flutter build apk --release

# iOS (需要 macOS)
flutter build ipa --release

# Windows
flutter build windows --release
```

推送至 GitHub 后，GitHub Actions 自动构建 APK 和 IPA。

## 下载

前往 [Actions](https://github.com/Jmengying/ReadLive/actions) 页面下载最新构建产物。
