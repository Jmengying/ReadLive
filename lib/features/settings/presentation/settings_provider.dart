import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/settings/data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(repo);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _repo;

  ThemeModeNotifier(this._repo) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final mode = await _repo.getThemeMode();
    state = _parseThemeMode(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repo.setThemeMode(_themeModeToString(mode));
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}

// 阅读设置模型
class ReadingSettings {
  final double fontSize;
  final double lineHeight;
  final int bgIndex;
  final String fontFamily;
  final int fontWeight;
  final double paragraphSpacing;
  final double firstLineIndent;
  final String pageAnimation;
  final double brightness; // -1.0 = 跟随系统
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
