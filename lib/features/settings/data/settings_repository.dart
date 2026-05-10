import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _themeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _lineHeightKey = 'line_height';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<String> getThemeMode() async {
    final prefs = await _prefs();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _prefs();
    await prefs.setString(_themeKey, mode);
  }

  Future<double> getFontSize() async {
    final prefs = await _prefs();
    return prefs.getDouble(_fontSizeKey) ?? 18.0;
  }

  Future<void> setFontSize(double size) async {
    final prefs = await _prefs();
    await prefs.setDouble(_fontSizeKey, size);
  }

  Future<double> getLineHeight() async {
    final prefs = await _prefs();
    return prefs.getDouble(_lineHeightKey) ?? 1.8;
  }

  Future<void> setLineHeight(double height) async {
    final prefs = await _prefs();
    await prefs.setDouble(_lineHeightKey, height);
  }

  // 阅读设置 keys
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

  Future<int> getReadingBgIndex() async {
    final prefs = await _prefs();
    return prefs.getInt(_readingBgIndexKey) ?? 0;
  }

  Future<void> setReadingBgIndex(int index) async {
    final prefs = await _prefs();
    await prefs.setInt(_readingBgIndexKey, index);
  }

  Future<String> getReadingFontFamily() async {
    final prefs = await _prefs();
    return prefs.getString(_readingFontFamilyKey) ?? 'system';
  }

  Future<void> setReadingFontFamily(String family) async {
    final prefs = await _prefs();
    await prefs.setString(_readingFontFamilyKey, family);
  }

  Future<int> getReadingFontWeight() async {
    final prefs = await _prefs();
    return prefs.getInt(_readingFontWeightKey) ?? 400;
  }

  Future<void> setReadingFontWeight(int weight) async {
    final prefs = await _prefs();
    await prefs.setInt(_readingFontWeightKey, weight);
  }

  Future<double> getReadingParagraphSpacing() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingParagraphSpacingKey) ?? 16.0;
  }

  Future<void> setReadingParagraphSpacing(double spacing) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingParagraphSpacingKey, spacing);
  }

  Future<double> getReadingFirstLineIndent() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingFirstLineIndentKey) ?? 2.0;
  }

  Future<void> setReadingFirstLineIndent(double indent) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingFirstLineIndentKey, indent);
  }

  Future<String> getReadingPageAnimation() async {
    final prefs = await _prefs();
    return prefs.getString(_readingPageAnimKey) ?? 'slide';
  }

  Future<void> setReadingPageAnimation(String anim) async {
    final prefs = await _prefs();
    await prefs.setString(_readingPageAnimKey, anim);
  }

  Future<double> getReadingBrightness() async {
    final prefs = await _prefs();
    return prefs.getDouble(_readingBrightnessKey) ?? -1.0;
  }

  Future<void> setReadingBrightness(double value) async {
    final prefs = await _prefs();
    await prefs.setDouble(_readingBrightnessKey, value);
  }

  Future<bool> getReadingEyeProtection() async {
    final prefs = await _prefs();
    return prefs.getBool(_readingEyeProtectionKey) ?? false;
  }

  Future<void> setReadingEyeProtection(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_readingEyeProtectionKey, enabled);
  }

  Future<bool> getReadingKeepScreenOn() async {
    final prefs = await _prefs();
    return prefs.getBool(_readingKeepScreenOnKey) ?? true;
  }

  Future<void> setReadingKeepScreenOn(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_readingKeepScreenOnKey, enabled);
  }

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
}
