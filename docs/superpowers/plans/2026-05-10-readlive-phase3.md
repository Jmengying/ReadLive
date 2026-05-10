# ReadLive Phase 3: Reading Experience Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the reading experience with a full-reading settings panel (font, background, page animation), bookmarks/notes/highlights, night mode, eye protection, gesture customization, and TTS voice reading.

**Architecture:** Reading settings are persisted via SharedPreferences through SettingsRepository. The reader page connects settings to the PaginationEngine and TextContentView. Bookmarks use the existing BookmarksTable. TTS uses the flutter_tts package. All features integrate into the existing reader UI via the toolbar and bottom sheet panels.

**Tech Stack:** flutter_tts (TTS), wakelock_plus (screen awake), existing Riverpod/drift/shared_preferences stack

**Dependencies to add to pubspec.yaml:**
- `flutter_tts: ^4.2.2` — Text-to-speech engine
- `wakelock_plus: ^1.2.10` — Keep screen awake while reading

---

## File Structure

```
lib/
├── features/
│   ├── reader/
│   │   ├── presentation/
│   │   │   ├── reader_page.dart                   # MODIFY: integrate settings, bookmarks, TTS, gestures
│   │   │   ├── reader_provider.dart               # MODIFY: add reading settings provider, bookmark actions
│   │   │   └── widgets/
│   │   │       ├── text_content_view.dart          # MODIFY: use dynamic settings
│   │   │       ├── reader_toolbar.dart             # MODIFY: add TTS, bookmark, night mode buttons
│   │   │       ├── reading_settings_panel.dart     # CREATE: bottom sheet settings panel
│   │   │       ├── bookmark_list_sheet.dart        # CREATE: bookmark list bottom sheet
│   │   │       └── tts_controls.dart               # CREATE: TTS playback controls
│   │   └── data/
│   │       └── bookmark_repository.dart            # CREATE: bookmark CRUD operations
│   └── settings/
│       ├── data/
│       │   └── settings_repository.dart            # MODIFY: add reading settings keys
│       └── presentation/
│           └── settings_provider.dart              # MODIFY: add reading settings notifier
```

---

### Task 1: Add Dependencies (flutter_tts, wakelock_plus)

**Files:**
- Modify: `D:/ReadLive/pubspec.yaml`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Add under `dependencies`:

```yaml
  flutter_tts: ^4.2.2
  wakelock_plus: ^1.2.10
```

- [ ] **Step 2: Install dependencies**

```bash
cd D:/ReadLive
flutter pub get
```

Expected: All dependencies resolved.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml
git commit -m "feat: add flutter_tts and wakelock_plus dependencies"
```

---

### Task 2: Extend Settings Repository — Reading Settings Persistence

**Files:**
- Modify: `D:/ReadLive/lib/features/settings/data/settings_repository.dart`

- [ ] **Step 1: Add reading settings keys and methods**

Append to `lib/features/settings/data/settings_repository.dart`:

```dart
  // Reading settings keys
  static const _readingBgIndexKey = 'reading_bg_index';
  static const _readingFontFamilyKey = 'reading_font_family';
  static const _readingFontWeightKey = 'reading_font_weight';
  static const _readingParagraphSpacingKey = 'reading_paragraph_spacing';
  static const _readingFirstLineIndentKey = 'reading_first_line_indent';
  static const _readingPageAnimKey = 'reading_page_animation';
  static const _readingBrightnessKey = 'reading_brightness';
  static const _readingEyeProtectionKey = 'reading_eye_protection';
  static const _readingKeepScreenOnKey = 'reading_keep_screen_on';
  static const _readingTapZoneLeftKey = 'reading_tap_zone_left';
  static const _readingTapZoneRightKey = 'reading_tap_zone_right';

  // Background color index (0-4, maps to AppTheme.readingBackgrounds)
  Future<int> getReadingBgIndex() async {
    final prefs = await _prefs();
    return prefs.getInt(_readingBgIndexKey) ?? 0;
  }

  Future<void> setReadingBgIndex(int index) async {
    final prefs = await _prefs();
    await prefs.setInt(_readingBgIndexKey, index);
  }

  // Font family
  Future<String> getReadingFontFamily() async {
    final prefs = await _prefs();
    return prefs.getString(_readingFontFamilyKey) ?? 'system';
  }

  Future<void> setReadingFontFamily(String family) async {
    final prefs = await _prefs();
    await prefs.setString(_readingFontFamilyKey, family);
  }

  // Font weight (100-900, default 400)
  Future<int> getReadingFontWeight() async {
    final prefs = await _prefs();
    return prefs.getInt(_readingFontWeightKey) ?? 400;
  }

  Future<void> setReadingFontWeight(int weight) async {
    final prefs = await _prefs();
    await prefs.setInt(_readingFontWeightKey, weight);
  }

  // Paragraph spacing
  Future<double> getReadingParagraphSpacing() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingParagraphSpacingKey) ?? 16.0;
  }

  Future<void> setReadingParagraphSpacing(double spacing) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingParagraphSpacingKey, spacing);
  }

  // First line indent (in em, default 2)
  Future<double> getReadingFirstLineIndent() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingFirstLineIndentKey) ?? 2.0;
  }

  Future<void> setReadingFirstLineIndent(double indent) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingFirstLineIndentKey, indent);
  }

  // Page animation type: 'slide', 'fade', 'simulation', 'scroll', 'none'
  Future<String> getReadingPageAnimation() async {
    final prefs = await _prefs();
    return prefs.getString(_readingPageAnimKey) ?? 'slide';
  }

  Future<void> setReadingPageAnimation(String anim) async {
    final prefs = await _prefs();
    await prefs.setString(_readingPageAnimKey, anim);
  }

  // Brightness (0.0-1.0, -1.0 means follow system)
  Future<double> getReadingBrightness() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingBrightnessKey) ?? -1.0;
  }

  Future<void> setReadingBrightness(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingBrightnessKey, value);
  }

  // Eye protection mode
  Future<bool> getReadingEyeProtection() async {
    final prefs = await _prefs();
    return prefs.getBool(_readingEyeProtectionKey) ?? false;
  }

  Future<void> setReadingEyeProtection(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_readingEyeProtectionKey, enabled);
  }

  // Keep screen on while reading
  Future<bool> getReadingKeepScreenOn() async {
    final prefs = await _prefs();
    return prefs.getBool(_readingKeepScreenOnKey) ?? true;
  }

  Future<void> setReadingKeepScreenOn(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_readingKeepScreenOnKey, enabled);
  }

  // Tap zone widths (0.0-1.0, default left=0.3, right=0.3)
  Future<double> getReadingTapZoneLeft() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingTapZoneLeftKey) ?? 0.3;
  }

  Future<void> setReadingTapZoneLeft(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingTapZoneLeftKey, value);
  }

  Future<double> getReadingTapZoneRight() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingTapZoneRightKey) ?? 0.3;
  }

  Future<void> setReadingTapZoneRight(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingTapZoneRightKey, value);
  }
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/settings/data/settings_repository.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/data/settings_repository.dart
git commit -m "feat: add reading settings persistence (font, background, animation, brightness, gestures)"
```

---

### Task 3: Reading Settings Notifier (Riverpod)

**Files:**
- Modify: `D:/ReadLive/lib/features/settings/presentation/settings_provider.dart`

- [ ] **Step 1: Add ReadingSettings model and notifier**

Append to `lib/features/settings/presentation/settings_provider.dart`:

```dart
// Reading settings model
class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final int bgIndex;
  final String fontFamily;
  final int fontWeight;
  final double paragraphSpacing;
  final double firstLineIndent;
  final String pageAnimation;
  final double brightness; // -1.0 = follow system
  final bool eyeProtection;
  final bool keepScreenOn;
  final double tapZoneLeft;
  final double tapZoneRight;

  const ReadingSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.bgIndex = 0,
    this.fontFamily = 'system',
    this.fontWeight = 400,
    this.paragraphSpacing = 16.0,
    this.firstLineIndent = 2.0,
    this.pageAnimation = 'slide',
    this.brightness = -1.0,
    this.eyeProtection = false,
    this.keepScreenOn = true,
    this.tapZoneLeft = 0.3,
    this.tapZoneRight = 0.3,
  });

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    int? bgIndex,
    String? fontFamily,
    int? fontWeight,
    double? paragraphSpacing,
    double? firstLineIndent,
    String? pageAnimation,
    double? brightness,
    bool? eyeProtection,
    bool? keepScreenOn,
    double? tapZoneLeft,
    double? tapZoneRight,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      bgIndex: bgIndex ?? this.bgIndex,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      brightness: brightness ?? this.brightness,
      eyeProtection: eyeProtection ?? this.eyeProtection,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      tapZoneLeft: tapZoneLeft ?? this.tapZoneLeft,
      tapZoneRight: tapZoneRight ?? this.tapZoneRight,
    );
  }
}

class ReadingSettingsNotifier extends StateNotifier<ReadingSettings> {
  final SettingsRepository _repo;

  ReadingSettingsNotifier(this._repo) : super(const ReadingSettings()) {
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.getFontSize(),
      _repo.getLineHeight(),
      _repo.getReadingBgIndex(),
      _repo.getReadingFontFamily(),
      _repo.getReadingFontWeight(),
      _repo.getReadingParagraphSpacing(),
      _repo.getReadingFirstLineIndent(),
      _repo.getReadingPageAnimation(),
      _repo.getReadingBrightness(),
      _repo.getReadingEyeProtection(),
      _repo.getReadingKeepScreenOn(),
      _repo.getReadingTapZoneLeft(),
      _repo.getReadingTapZoneRight(),
    ]);

    state = ReadingSettings(
      fontSize: results[0] as double,
      lineHeight: results[1] as double,
      bgIndex: results[2] as int,
      fontFamily: results[3] as String,
      fontWeight: results[4] as int,
      paragraphSpacing: results[5] as double,
      firstLineIndent: results[6] as double,
      pageAnimation: results[7] as String,
      brightness: results[8] as double,
      eyeProtection: results[9] as bool,
      keepScreenOn: results[10] as bool,
      tapZoneLeft: results[11] as double,
      tapZoneRight: results[12] as double,
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _repo.setFontSize(size);
  }

  Future<void> setLineHeight(double height) async {
    state = state.copyWith(lineHeight: height);
    await _repo.setLineHeight(height);
  }

  Future<void> setBgIndex(int index) async {
    state = state.copyWith(bgIndex: index);
    await _repo.setReadingBgIndex(index);
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _repo.setReadingFontFamily(family);
  }

  Future<void> setFontWeight(int weight) async {
    state = state.copyWith(fontWeight: weight);
    await _repo.setReadingFontWeight(weight);
  }

  Future<void> setParagraphSpacing(double spacing) async {
    state = state.copyWith(paragraphSpacing: spacing);
    await _repo.setReadingParagraphSpacing(spacing);
  }

  Future<void> setFirstLineIndent(double indent) async {
    state = state.copyWith(firstLineIndent: indent);
    await _repo.setReadingFirstLineIndent(indent);
  }

  Future<void> setPageAnimation(String anim) async {
    state = state.copyWith(pageAnimation: anim);
    await _repo.setReadingPageAnimation(anim);
  }

  Future<void> setBrightness(double value) async {
    state = state.copyWith(brightness: value);
    await _repo.setReadingBrightness(value);
  }

  Future<void> setEyeProtection(bool enabled) async {
    state = state.copyWith(eyeProtection: enabled);
    await _repo.setReadingEyeProtection(enabled);
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    state = state.copyWith(keepScreenOn: enabled);
    await _repo.setReadingKeepScreenOn(enabled);
  }

  Future<void> setTapZoneLeft(double value) async {
    state = state.copyWith(tapZoneLeft: value);
    await _repo.setReadingTapZoneLeft(value);
  }

  Future<void> setTapZoneRight(double value) async {
    state = state.copyWith(tapZoneRight: value);
    await _repo.setReadingTapZoneRight(value);
  }
}

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ReadingSettingsNotifier(repo);
});
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/settings/presentation/settings_provider.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/settings_provider.dart
git commit -m "feat: reading settings notifier with full persistence"
```

---

### Task 4: Reading Settings Panel (BottomSheet UI)

**Files:**
- Create: `D:/ReadLive/lib/features/reader/presentation/widgets/reading_settings_panel.dart`

- [ ] **Step 1: Create reading_settings_panel.dart**

```dart
// lib/features/reader/presentation/widgets/reading_settings_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class ReadingSettingsPanel extends ConsumerWidget {
  final VoidCallback onClose;

  const ReadingSettingsPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final notifier = ref.read(readingSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Font size
          _SettingRow(
            label: '字号',
            child: Row(
              children: [
                _RoundButton(
                  icon: Icons.remove,
                  onPressed: settings.fontSize > 12
                      ? () => notifier.setFontSize(settings.fontSize - 1)
                      : null,
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${settings.fontSize.toInt()}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                _RoundButton(
                  icon: Icons.add,
                  onPressed: settings.fontSize < 30
                      ? () => notifier.setFontSize(settings.fontSize + 1)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    onChanged: (v) => notifier.setFontSize(v),
                  ),
                ),
              ],
            ),
          ),

          // Line height
          _SettingRow(
            label: '行距',
            child: Slider(
              value: settings.lineHeight,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              label: settings.lineHeight.toStringAsFixed(1),
              onChanged: (v) => notifier.setLineHeight(v),
            ),
          ),

          // Background color presets
          _SettingRow(
            label: '背景',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(AppTheme.readingBackgrounds.length, (index) {
                final color = AppTheme.readingBackgrounds[index];
                final isSelected = settings.bgIndex == index;
                return GestureDetector(
                  onTap: () => notifier.setBgIndex(index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: index >= 3 ? Colors.white : Colors.black,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),

          // Page animation
          _SettingRow(
            label: '翻页',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AnimChip(
                  label: '滑动',
                  isSelected: settings.pageAnimation == 'slide',
                  onTap: () => notifier.setPageAnimation('slide'),
                ),
                _AnimChip(
                  label: '淡入',
                  isSelected: settings.pageAnimation == 'fade',
                  onTap: () => notifier.setPageAnimation('fade'),
                ),
                _AnimChip(
                  label: '滚动',
                  isSelected: settings.pageAnimation == 'scroll',
                  onTap: () => notifier.setPageAnimation('scroll'),
                ),
                _AnimChip(
                  label: '无',
                  isSelected: settings.pageAnimation == 'none',
                  onTap: () => notifier.setPageAnimation('none'),
                ),
              ],
            ),
          ),

          // Brightness
          _SettingRow(
            label: '亮度',
            child: Slider(
              value: settings.brightness < 0 ? 0.5 : settings.brightness,
              min: 0.0,
              max: 1.0,
              onChanged: (v) => notifier.setBrightness(v),
            ),
          ),

          // Eye protection toggle
          SwitchListTile(
            title: const Text('护眼模式'),
            value: settings.eyeProtection,
            onChanged: (v) => notifier.setEyeProtection(v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _AnimChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/presentation/widgets/reading_settings_panel.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/widgets/reading_settings_panel.dart
git commit -m "feat: reading settings panel with font, background, animation, brightness"
```

---

### Task 5: Bookmarks — Repository and Provider

**Files:**
- Create: `D:/ReadLive/lib/features/reader/data/bookmark_repository.dart`
- Modify: `D:/ReadLive/lib/features/reader/presentation/reader_provider.dart`

- [ ] **Step 1: Create bookmark_repository.dart**

```dart
// lib/features/reader/data/bookmark_repository.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:readlive/core/database/app_database.dart';

class BookmarkRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BookmarkRepository(this._db);

  Future<List<BookmarksTableData>> getBookmarks(String bookId) =>
      _db.getBookmarksByBook(bookId);

  Future<BookmarksTableData> addBookmark({
    required String bookId,
    required String chapterId,
    required int position,
    String? contentPreview,
    String? note,
    String? highlightColor,
    String type = 'bookmark',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final companion = BookmarksTableCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      position: Value(position),
      contentPreview: Value(contentPreview),
      note: Value(note),
      highlightColor: Value(highlightColor),
      type: Value(type),
      createdAt: Value(now),
    );
    await _db.insertBookmark(companion);
    return (await _db.getBookmarksByBook(bookId))
        .firstWhere((b) => b.id == id);
  }

  Future<void> deleteBookmark(String id) => _db.deleteBookmark(id);

  Future<bool> isBookmarked(String bookId, String chapterId, int position) async {
    final bookmarks = await _db.getBookmarksByBook(bookId);
    return bookmarks.any(
        (b) => b.chapterId == chapterId && b.position == position && b.type == 'bookmark');
  }
}
```

- [ ] **Step 2: Add bookmark provider to reader_provider.dart**

Append to `lib/features/reader/presentation/reader_provider.dart`:

```dart
// Bookmark repository provider
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookmarkRepository(db);
});

// Bookmarks for a book
final bookmarksProvider =
    FutureProvider.family<List<BookmarksTableData>, String>((ref, bookId) {
  final repo = ref.watch(bookmarkRepositoryProvider);
  return repo.getBookmarks(bookId);
});
```

Add the import at the top:

```dart
import 'package:readlive/features/reader/data/bookmark_repository.dart';
```

- [ ] **Step 3: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/
```

Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/reader/data/bookmark_repository.dart lib/features/reader/presentation/reader_provider.dart
git commit -m "feat: bookmark repository and provider"
```

---

### Task 6: Bookmark List Sheet

**Files:**
- Create: `D:/ReadLive/lib/features/reader/presentation/widgets/bookmark_list_sheet.dart`

- [ ] **Step 1: Create bookmark_list_sheet.dart**

```dart
// lib/features/reader/presentation/widgets/bookmark_list_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';

class BookmarkListSheet extends ConsumerWidget {
  final String bookId;
  final Function(int chapterIndex, int position) onJumpToBookmark;

  const BookmarkListSheet({
    super.key,
    required this.bookId,
    required this.onJumpToBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider(bookId));
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('书签', style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: bookmarksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (bookmarks) {
                if (bookmarks.isEmpty) {
                  return const Center(child: Text('暂无书签'));
                }
                return ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bm = bookmarks[index];
                    return _BookmarkTile(
                      bookmark: bm,
                      onTap: () {
                        // For now, jump using position as page index
                        onJumpToBookmark(0, bm.position);
                        Navigator.pop(context);
                      },
                      onDelete: () {
                        ref.read(bookmarkRepositoryProvider).deleteBookmark(bm.id);
                        ref.invalidate(bookmarksProvider(bookId));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarksTableData bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeIcon = bookmark.type == 'highlight'
        ? Icons.highlight
        : bookmark.type == 'note'
            ? Icons.note
            : Icons.bookmark;

    return ListTile(
      leading: Icon(typeIcon, color: theme.colorScheme.primary),
      title: Text(
        bookmark.contentPreview ?? '书签',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: bookmark.note != null
          ? Text(bookmark.note!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/presentation/widgets/bookmark_list_sheet.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/widgets/bookmark_list_sheet.dart
git commit -m "feat: bookmark list sheet with jump and delete"
```

---

### Task 7: TTS Controls Widget

**Files:**
- Create: `D:/ReadLive/lib/features/reader/presentation/widgets/tts_controls.dart`

- [ ] **Step 1: Create tts_controls.dart**

```dart
// lib/features/reader/presentation/widgets/tts_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsControls extends StatefulWidget {
  final String text;
  final VoidCallback onClose;

  const TtsControls({super.key, required this.text, required this.onClose});

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls> {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _speed = 0.5;
  double _pitch = 1.0;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(_speed);
    await _tts.setPitch(_pitch);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _speak() async {
    if (widget.text.isEmpty) return;
    await _tts.speak(widget.text);
    setState(() => _isPlaying = true);
  }

  Future<void> _pause() async {
    await _tts.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _stop,
                tooltip: '停止',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 48,
                color: theme.colorScheme.primary,
                onPressed: _isPlaying ? _pause : _speak,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _stop();
                  widget.onClose();
                },
                tooltip: '关闭',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Speed control
          Row(
            children: [
              const Text('语速'),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_speed * 2).toStringAsFixed(1)}x',
                  onChanged: (v) async {
                    setState(() => _speed = v);
                    await _tts.setSpeechRate(v);
                  },
                ),
              ),
            ],
          ),

          // Pitch control
          Row(
            children: [
              const Text('音调'),
              Expanded(
                child: Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _pitch.toStringAsFixed(1),
                  onChanged: (v) async {
                    setState(() => _pitch = v);
                    await _tts.setPitch(v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/presentation/widgets/tts_controls.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/widgets/tts_controls.dart
git commit -m "feat: TTS controls with play/pause, speed, and pitch"
```

---

### Task 8: Integrate Settings, Bookmarks, TTS into Reader Page

**Files:**
- Modify: `D:/ReadLive/lib/features/reader/presentation/reader_page.dart`
- Modify: `D:/ReadLive/lib/features/reader/presentation/widgets/text_content_view.dart`
- Modify: `D:/ReadLive/lib/features/reader/presentation/widgets/reader_toolbar.dart`

- [ ] **Step 1: Update text_content_view.dart to accept dynamic settings**

Replace `lib/features/reader/presentation/widgets/text_content_view.dart` with:

```dart
// lib/features/reader/presentation/widgets/text_content_view.dart
import 'package:flutter/material.dart';

class TextContentView extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;
  final String fontFamily;
  final int fontWeight;
  final double firstLineIndent;
  final bool eyeProtection;

  const TextContentView({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.textColor = const Color(0xFF333333),
    this.backgroundColor = const Color(0xFFF5F0E6),
    this.fontFamily = 'system',
    this.fontWeight = 400,
    this.firstLineIndent = 2.0,
    this.eyeProtection = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: lineHeight,
            color: textColor,
            fontWeight: _parseFontWeight(fontWeight),
            fontFamily: fontFamily == 'system' ? null : fontFamily,
          ),
        ),
      ),
    );

    // Eye protection overlay (warm color filter)
    if (eyeProtection) {
      content = Stack(
        children: [
          content,
          Container(
            color: const Color(0x0AFFBE76), // Warm yellow overlay
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      );
    }

    return content;
  }

  FontWeight _parseFontWeight(int weight) {
    switch (weight) {
      case 100: return FontWeight.w100;
      case 200: return FontWeight.w200;
      case 300: return FontWeight.w300;
      case 400: return FontWeight.w400;
      case 500: return FontWeight.w500;
      case 600: return FontWeight.w600;
      case 700: return FontWeight.w700;
      case 800: return FontWeight.w800;
      case 900: return FontWeight.w900;
      default: return FontWeight.w400;
    }
  }
}
```

- [ ] **Step 2: Update reader_toolbar.dart to add new buttons**

Replace `lib/features/reader/presentation/widgets/reader_toolbar.dart` with:

```dart
// lib/features/reader/presentation/widgets/reader_toolbar.dart
import 'package:flutter/material.dart';

class ReaderToolbar extends StatelessWidget {
  final String bookTitle;
  final int currentChapter;
  final int totalChapters;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onToggleLock;
  final VoidCallback onShowChapters;
  final VoidCallback onShowSettings;
  final VoidCallback onShowBookmarks;
  final VoidCallback onToggleNightMode;
  final VoidCallback onToggleTts;
  final VoidCallback onAddBookmark;
  final ValueChanged<int> onChapterChange;

  const ReaderToolbar({
    super.key,
    required this.bookTitle,
    required this.currentChapter,
    required this.totalChapters,
    required this.isLocked,
    required this.onBack,
    required this.onToggleLock,
    required this.onShowChapters,
    required this.onShowSettings,
    required this.onShowBookmarks,
    required this.onToggleNightMode,
    required this.onToggleTts,
    required this.onAddBookmark,
    required this.onChapterChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top toolbar
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 8,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  bookTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                onPressed: onToggleLock,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom toolbar
        Container(
          color: Colors.black54,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '第${currentChapter + 1}章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentChapter.toDouble(),
                      min: 0,
                      max: (totalChapters - 1).toDouble().clamp(0, double.infinity),
                      onChanged: (v) => onChapterChange(v.toInt()),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                    ),
                  ),
                  Text(
                    '第$totalChapters章',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.list, color: Colors.white),
                    onPressed: onShowChapters,
                    tooltip: '目录',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: onShowBookmarks,
                    tooltip: '书签',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_add, color: Colors.white),
                    onPressed: onAddBookmark,
                    tooltip: '添加书签',
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white),
                    onPressed: onToggleTts,
                    tooltip: '朗读',
                  ),
                  IconButton(
                    icon: const Icon(Icons.nightlight_round, color: Colors.white),
                    onPressed: onToggleNightMode,
                    tooltip: '夜间模式',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: onShowSettings,
                    tooltip: '设置',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Update reader_page.dart to integrate all features**

The reader_page.dart needs significant updates. Here's the full replacement:

```dart
// lib/features/reader/presentation/reader_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';
import 'package:readlive/features/reader/presentation/reader_provider.dart';
import 'package:readlive/features/reader/presentation/widgets/text_content_view.dart';
import 'package:readlive/features/reader/presentation/widgets/reader_toolbar.dart';
import 'package:readlive/features/reader/presentation/widgets/reading_settings_panel.dart';
import 'package:readlive/features/reader/presentation/widgets/bookmark_list_sheet.dart';
import 'package:readlive/features/reader/presentation/widgets/tts_controls.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  const ReaderPage({super.key, required this.bookId});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  bool _showTts = false;
  bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _enableWakelock();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _enableWakelock() async {
    final settings = ref.read(readingSettingsProvider);
    if (settings.keepScreenOn) {
      await WakelockPlus.enable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.bookId));
    final readerState = ref.watch(readerNotifierProvider(widget.bookId));
    final notifier = ref.read(readerNotifierProvider(widget.bookId).notifier);
    final readingSettings = ref.watch(readingSettingsProvider);

    // Get background color
    final bgIndex = _isNightMode ? 4 : readingSettings.bgIndex;
    final bgColor = AppTheme.readingBackgrounds[bgIndex];
    final textColor = bgIndex >= 3
        ? AppTheme.readingTextColors[1]
        : AppTheme.readingTextColors[0];

    return Scaffold(
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('书籍不存在'));
          }

          return chaptersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载章节失败: $e')),
            data: (chapters) {
              if (chapters.isEmpty) {
                return const Center(child: Text('暂无章节内容'));
              }

              final chapterIndex = readerState.currentChapterIndex.clamp(
                  0, chapters.length - 1);
              final content = chapters[chapterIndex].content ?? '';
              final screenSize = MediaQuery.of(context).size;

              final pagesAsync = ref.watch(chapterPagesProvider((
                bookId: widget.bookId,
                chapterIndex: chapterIndex,
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
              )));

              return pagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('分页失败: $e')),
                data: (pages) {
                  if (pages.isEmpty) {
                    return const Center(child: Text('章节内容为空'));
                  }

                  final pageIndex = readerState.currentPageIndex.clamp(
                      0, pages.length - 1);

                  return GestureDetector(
                    onTapUp: (details) => _handleTap(
                        details, screenSize, notifier, pages.length,
                        readingSettings),
                    onDoubleTap: () {
                      if (readerState.isLocked) {
                        notifier.toggleLock();
                      }
                    },
                    child: Stack(
                      children: [
                        // Content
                        TextContentView(
                          text: pages[pageIndex].text,
                          fontSize: readingSettings.fontSize,
                          lineHeight: readingSettings.lineHeight,
                          textColor: textColor,
                          backgroundColor: bgColor,
                          fontFamily: readingSettings.fontFamily,
                          fontWeight: readingSettings.fontWeight,
                          firstLineIndent: readingSettings.firstLineIndent,
                          eyeProtection: readingSettings.eyeProtection,
                        ),
                        // Toolbar overlay
                        if (readerState.isToolbarVisible)
                          ReaderToolbar(
                            bookTitle: book.title,
                            currentChapter: chapterIndex,
                            totalChapters: chapters.length,
                            isLocked: readerState.isLocked,
                            onBack: () => context.pop(),
                            onToggleLock: notifier.toggleLock,
                            onShowChapters: () =>
                                _showChapterDrawer(chapters),
                            onShowSettings: () => _showSettingsPanel(),
                            onShowBookmarks: () => _showBookmarkSheet(
                                chapters[chapterIndex]),
                            onToggleNightMode: _toggleNightMode,
                            onToggleTts: _toggleTts,
                            onAddBookmark: () => _addBookmark(
                                chapters[chapterIndex], pageIndex),
                            onChapterChange: (index) {
                              notifier.setChapter(index);
                            },
                          ),
                        // Lock indicator
                        if (readerState.isLocked)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('已锁定',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // TTS controls
                        if (_showTts)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: TtsControls(
                              text: pages[pageIndex].text,
                              onClose: () => setState(() => _showTts = false),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(TapUpDetails details, Size screenSize,
      ReaderNotifier notifier, int totalPages, ReadingSettings settings) {
    final dx = details.globalPosition.dx;
    final width = screenSize.width;

    if (ref.read(readerNotifierProvider(widget.bookId)).isLocked) {
      return;
    }

    final leftBound = width * settings.tapZoneLeft;
    final rightBound = width * (1 - settings.tapZoneRight);

    if (dx < leftBound) {
      notifier.previousPage();
    } else if (dx > rightBound) {
      notifier.nextPage(totalPages);
    } else {
      notifier.toggleToolbar();
    }
  }

  void _showChapterDrawer(List chapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('目录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (ctx, index) => ListTile(
                  title: Text(chapters[index].title),
                  onTap: () {
                    ref
                        .read(readerNotifierProvider(widget.bookId).notifier)
                        .setChapter(index);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPanel() {
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ReadingSettingsPanel(
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showBookmarkSheet(dynamic chapter) {
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BookmarkListSheet(
        bookId: widget.bookId,
        onJumpToBookmark: (chapterIndex, position) {
          ref
              .read(readerNotifierProvider(widget.bookId).notifier)
              .setChapter(chapterIndex);
        },
      ),
    );
  }

  void _toggleNightMode() {
    setState(() => _isNightMode = !_isNightMode);
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }

  void _toggleTts() {
    setState(() => _showTts = !_showTts);
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }

  Future<void> _addBookmark(dynamic chapter, int pageIndex) async {
    final repo = ref.read(bookmarkRepositoryProvider);
    await repo.addBookmark(
      bookId: widget.bookId,
      chapterId: chapter.id,
      position: pageIndex,
      contentPreview: chapter.title,
    );
    ref.invalidate(bookmarksProvider(widget.bookId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加书签')),
      );
    }
    ref.read(readerNotifierProvider(widget.bookId).notifier).hideToolbar();
  }
}
```

- [ ] **Step 4: Verify app builds**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reader/
git commit -m "feat: integrate settings, bookmarks, TTS, night mode into reader page"
```

---

### Task 9: Reader Page Animation Support

**Files:**
- Modify: `D:/ReadLive/lib/features/reader/presentation/reader_page.dart`

- [ ] **Step 1: Add page animation to reader_page.dart**

Wrap the page content in the reader page with animation based on `readingSettings.pageAnimation`. This requires modifying the content display section.

In the `build` method, replace the direct `TextContentView` with an animated version:

```dart
// Replace the TextContentView section with:
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    switch (readingSettings.pageAnimation) {
      case 'fade':
        return FadeTransition(opacity: animation, child: child);
      case 'scroll':
        return child; // Scroll is handled by ListView
      case 'none':
        return child;
      case 'slide':
      default:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
    }
  },
  child: TextContentView(
    key: ValueKey('$chapterIndex-$pageIndex'),
    text: pages[pageIndex].text,
    fontSize: readingSettings.fontSize,
    lineHeight: readingSettings.lineHeight,
    textColor: textColor,
    backgroundColor: bgColor,
    fontFamily: readingSettings.fontFamily,
    fontWeight: readingSettings.fontWeight,
    firstLineIndent: readingSettings.firstLineIndent,
    eyeProtection: readingSettings.eyeProtection,
  ),
),
```

- [ ] **Step 2: Verify no analysis errors**

```bash
cd D:/ReadLive
flutter analyze lib/features/reader/presentation/reader_page.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/reader/presentation/reader_page.dart
git commit -m "feat: page turn animation support (slide, fade, scroll, none)"
```

---

### Task 10: Tests

**Files:**
- Create: `D:/ReadLive/test/features/reader/data/bookmark_repository_test.dart`

- [ ] **Step 1: Write bookmark repository test**

```dart
// test/features/reader/data/bookmark_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:readlive/core/database/app_database.dart';
import 'package:readlive/features/bookshelf/data/book_repository.dart';
import 'package:readlive/features/reader/data/bookmark_repository.dart';

void main() {
  late AppDatabase db;
  late BookRepository bookRepo;
  late BookmarkRepository bookmarkRepo;

  setUp(() {
    db = AppDatabase(executor: NativeDatabase.memory());
    bookRepo = BookRepository(db);
    bookmarkRepo = BookmarkRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addBookmark and getBookmarks', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    final bm = await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 42,
      contentPreview: 'Test bookmark',
    );

    expect(bm.bookId, book.id);
    expect(bm.position, 42);

    final bookmarks = await bookmarkRepo.getBookmarks(book.id);
    expect(bookmarks.length, 1);
    expect(bookmarks.first.contentPreview, 'Test bookmark');
  });

  test('deleteBookmark', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    final bm = await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 0,
    );

    await bookmarkRepo.deleteBookmark(bm.id);
    final bookmarks = await bookmarkRepo.getBookmarks(book.id);
    expect(bookmarks, isEmpty);
  });

  test('isBookmarked', () async {
    final book = await bookRepo.addBook(
      title: 'Test',
      filePath: '/test.txt',
      contentType: 'novel',
    );

    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 42), false);

    await bookmarkRepo.addBookmark(
      bookId: book.id,
      chapterId: 'ch-1',
      position: 42,
    );

    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 42), true);
    expect(await bookmarkRepo.isBookmarked(book.id, 'ch-1', 43), false);
  });
}
```

- [ ] **Step 2: Run all tests**

```bash
cd D:/ReadLive
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/features/reader/data/bookmark_repository_test.dart
git commit -m "test: bookmark repository tests"
```

---

### Task 11: Final Verification

- [ ] **Step 1: Run all tests**

```bash
cd D:/ReadLive
flutter test
```

Expected: All tests pass.

- [ ] **Step 2: Run analysis**

```bash
cd D:/ReadLive
flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Build for Windows**

```bash
cd D:/ReadLive
flutter build windows --debug
```

Expected: Build succeeds.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: Phase 3 complete — reading settings, bookmarks, TTS, night mode, gestures"
```
