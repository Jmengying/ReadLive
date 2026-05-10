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
  final double letterSpacing;
  final String pageAnimation;
  final double brightness; // -1.0 = 跟随系统
  final bool eyeProtection;
  final double eyeProtectionIntensity; // 0.0 ~ 1.0
  final bool isNightMode;
  final bool keepScreenOn;
  final double tapZoneLeft;
  final double tapZoneRight;
  final int customBgColor; // ARGB int, -1 = not set
  final String? bgImagePath;

  const ReadingSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.8,
    this.bgIndex = 0,
    this.fontFamily = 'system',
    this.fontWeight = 400,
    this.paragraphSpacing = 16.0,
    this.firstLineIndent = 2.0,
    this.letterSpacing = 0.0,
    this.pageAnimation = 'slide',
    this.brightness = -1.0,
    this.eyeProtection = false,
    this.eyeProtectionIntensity = 0.3,
    this.isNightMode = false,
    this.keepScreenOn = true,
    this.tapZoneLeft = 0.3,
    this.tapZoneRight = 0.3,
    this.customBgColor = -1,
    this.bgImagePath,
  });

  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    int? bgIndex,
    String? fontFamily,
    int? fontWeight,
    double? paragraphSpacing,
    double? firstLineIndent,
    double? letterSpacing,
    String? pageAnimation,
    double? brightness,
    bool? eyeProtection,
    double? eyeProtectionIntensity,
    bool? isNightMode,
    bool? keepScreenOn,
    double? tapZoneLeft,
    double? tapZoneRight,
    int? customBgColor,
    String? bgImagePath,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      bgIndex: bgIndex ?? this.bgIndex,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      firstLineIndent: firstLineIndent ?? this.firstLineIndent,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      pageAnimation: pageAnimation ?? this.pageAnimation,
      brightness: brightness ?? this.brightness,
      eyeProtection: eyeProtection ?? this.eyeProtection,
      eyeProtectionIntensity: eyeProtectionIntensity ?? this.eyeProtectionIntensity,
      isNightMode: isNightMode ?? this.isNightMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      tapZoneLeft: tapZoneLeft ?? this.tapZoneLeft,
      tapZoneRight: tapZoneRight ?? this.tapZoneRight,
      customBgColor: customBgColor ?? this.customBgColor,
      bgImagePath: bgImagePath ?? this.bgImagePath,
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
      _repo.getFontSize(),           // 0
      _repo.getLineHeight(),         // 1
      _repo.getReadingBgIndex(),     // 2
      _repo.getReadingFontFamily(),  // 3
      _repo.getReadingFontWeight(),  // 4
      _repo.getReadingParagraphSpacing(), // 5
      _repo.getReadingFirstLineIndent(),  // 6
      _repo.getReadingPageAnimation(),    // 7
      _repo.getReadingBrightness(),       // 8
      _repo.getReadingEyeProtection(),    // 9
      _repo.getReadingKeepScreenOn(),     // 10
      _repo.getReadingTapZoneLeft(),      // 11
      _repo.getReadingTapZoneRight(),     // 12
      _repo.getReadingNightMode(),        // 13
      _repo.getReadingEyeProtectionIntensity(), // 14
      _repo.getReadingLetterSpacing(),    // 15
      _repo.getReadingCustomBgColor(),    // 16
      _repo.getReadingBgImagePath(),      // 17
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
      isNightMode: results[13] as bool,
      eyeProtectionIntensity: results[14] as double,
      letterSpacing: results[15] as double,
      customBgColor: results[16] as int,
      bgImagePath: results[17] as String?,
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

  Future<void> setNightMode(bool enabled) async {
    state = state.copyWith(isNightMode: enabled);
    await _repo.setReadingNightMode(enabled);
  }

  Future<void> setEyeProtectionIntensity(double value) async {
    state = state.copyWith(eyeProtectionIntensity: value);
    await _repo.setReadingEyeProtectionIntensity(value);
  }

  Future<void> setLetterSpacing(double value) async {
    state = state.copyWith(letterSpacing: value);
    await _repo.setReadingLetterSpacing(value);
  }

  Future<void> setCustomBgColor(int color) async {
    state = state.copyWith(customBgColor: color);
    await _repo.setReadingCustomBgColor(color);
  }

  Future<void> clearCustomBgColor() async {
    state = state.copyWith(customBgColor: -1);
    await _repo.setReadingCustomBgColor(-1);
  }

  Future<void> setBgImagePath(String? path) async {
    state = state.copyWith(bgImagePath: path);
    await _repo.setReadingBgImagePath(path);
  }
}

final readingSettingsProvider =
    StateNotifierProvider<ReadingSettingsNotifier, ReadingSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return ReadingSettingsNotifier(repo);
});

// Accent color
class AccentColorNotifier extends StateNotifier<Color> {
  final SettingsRepository _repo;

  AccentColorNotifier(this._repo) : super(const Color(0xFF8B6914)) {
    _load();
  }

  Future<void> _load() async {
    final colorValue = await _repo.getAccentColor();
    state = Color(colorValue);
  }

  Future<void> setColor(Color color) async {
    state = color;
    await _repo.setAccentColor(color.value);
  }
}

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return AccentColorNotifier(repo);
});

// Avatar path
class AvatarPathNotifier extends StateNotifier<String?> {
  final SettingsRepository _repo;

  AvatarPathNotifier(this._repo) : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getAvatarPath();
  }

  Future<void> setPath(String? path) async {
    state = path;
    await _repo.setAvatarPath(path);
  }
}

final avatarPathProvider =
    StateNotifierProvider<AvatarPathNotifier, String?>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return AvatarPathNotifier(repo);
});

// Signature
class SignatureNotifier extends StateNotifier<String> {
  final SettingsRepository _repo;

  SignatureNotifier(this._repo) : super('记录每一次阅读') {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getSignature();
  }

  Future<void> setSignature(String value) async {
    state = value;
    await _repo.setSignature(value);
  }
}

final signatureProvider =
    StateNotifierProvider<SignatureNotifier, String>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SignatureNotifier(repo);
});
