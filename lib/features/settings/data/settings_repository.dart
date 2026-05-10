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
}
