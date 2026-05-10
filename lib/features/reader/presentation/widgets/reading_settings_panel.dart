import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class ReadingSettingsPanel extends ConsumerWidget {
  const ReadingSettingsPanel({super.key});

  static const _animationOptions = <_AnimOption>[
    _AnimOption('slide', '滑动', Icons.swipe),
    _AnimOption('fade', '淡入', Icons.opacity),
    _AnimOption('scroll', '滚读', Icons.swap_vert),
    _AnimOption('none', '无', Icons.block),
  ];

  static const _fontFamilies = <_FontOption>[
    _FontOption('system', '默认'),
    _FontOption('serif', '宋体'),
    _FontOption('sans-serif', '黑体'),
    _FontOption('monospace', '等宽'),
  ];

  static const _fontWeights = <_WeightOption>[
    _WeightOption(100, '极细'),
    _WeightOption(200, '纤细'),
    _WeightOption(300, '细'),
    _WeightOption(400, '常规'),
    _WeightOption(500, '中等'),
    _WeightOption(600, '半粗'),
    _WeightOption(700, '粗'),
    _WeightOption(800, '超粗'),
    _WeightOption(900, '黑'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readingSettingsProvider);
    final notifier = ref.read(readingSettingsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ---- Font size ----
            _buildSectionTitle(context, '字号'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: settings.fontSize > 12
                      ? () => notifier.setFontSize(
                            (settings.fontSize - 1).clamp(12, 30),
                          )
                      : null,
                ),
                Expanded(
                  child: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 30,
                    divisions: 18,
                    label: settings.fontSize.toStringAsFixed(0),
                    onChanged: (v) => notifier.setFontSize(v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: settings.fontSize < 30
                      ? () => notifier.setFontSize(
                            (settings.fontSize + 1).clamp(12, 30),
                          )
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    settings.fontSize.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- Font family ----
            _buildSectionTitle(context, '字体'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                children: _fontFamilies.map((opt) {
                  final selected = settings.fontFamily == opt.value;
                  return ChoiceChip(
                    label: Text(opt.label),
                    selected: selected,
                    onSelected: (_) => notifier.setFontFamily(opt.value),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ---- Font weight ----
            _buildSectionTitle(context, '字重'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.fontWeight.toDouble(),
                    min: 100,
                    max: 900,
                    divisions: 8,
                    label: _fontWeights
                        .where((w) => w.value == settings.fontWeight)
                        .firstOrNull
                        ?.label ?? '${settings.fontWeight}',
                    onChanged: (v) => notifier.setFontWeight(v.toInt()),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${settings.fontWeight}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- Line height ----
            _buildSectionTitle(context, '行距'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.lineHeight,
                    min: 1.0,
                    max: 3.0,
                    divisions: 20,
                    label: settings.lineHeight.toStringAsFixed(1),
                    onChanged: (v) => notifier.setLineHeight(v),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    settings.lineHeight.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- Paragraph spacing ----
            _buildSectionTitle(context, '段间距'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.paragraphSpacing,
                    min: 0,
                    max: 40,
                    divisions: 16,
                    label: settings.paragraphSpacing.toStringAsFixed(0),
                    onChanged: (v) => notifier.setParagraphSpacing(v),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    settings.paragraphSpacing.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- Letter spacing ----
            _buildSectionTitle(context, '字间距'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.letterSpacing,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: settings.letterSpacing.toStringAsFixed(1),
                    onChanged: (v) => notifier.setLetterSpacing(v),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    settings.letterSpacing.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- First line indent ----
            _buildSectionTitle(context, '首行缩进'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: settings.firstLineIndent,
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: settings.firstLineIndent.toStringAsFixed(0),
                    onChanged: (v) => notifier.setFirstLineIndent(v),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${settings.firstLineIndent.toInt()}字',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---- Background color ----
            _buildSectionTitle(context, '背景色'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...List.generate(AppTheme.readingBackgrounds.length, (i) {
                    final selected = settings.bgIndex == i && settings.customBgColor < 0;
                    final color = AppTheme.readingBackgrounds[i];
                    return _buildColorCircle(
                      context, color, selected,
                      () => notifier.clearCustomBgColor().then((_) => notifier.setBgIndex(i)),
                    );
                  }),
                  // Custom color indicator
                  if (settings.customBgColor >= 0)
                    _buildColorCircle(
                      context, Color(settings.customBgColor), true,
                      () => _showColorPicker(context, notifier, settings.customBgColor),
                    ),
                  // Add custom color button
                  _buildAddColorButton(context, () {
                    _showColorPicker(context, notifier, settings.customBgColor);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---- Background image ----
            _buildSectionTitle(context, '背景图'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  if (settings.bgImagePath != null &&
                      settings.bgImagePath!.isNotEmpty &&
                      File(settings.bgImagePath!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(settings.bgImagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '已设置背景图',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => notifier.setBgImagePath(null),
                      child: const Text('移除'),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        '未设置背景图（使用背景色）',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickBgImage(context, notifier),
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('选择'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---- Page animation ----
            _buildSectionTitle(context, '翻页动画'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                children: _animationOptions.map((opt) {
                  final selected = settings.pageAnimation == opt.value;
                  return ChoiceChip(
                    label: Text(opt.label),
                    avatar: Icon(opt.icon, size: 18),
                    selected: selected,
                    onSelected: (_) => notifier.setPageAnimation(opt.value),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ---- Brightness ----
            _buildSectionTitle(context, '亮度'),
            Row(
              children: [
                const Icon(Icons.brightness_low, size: 20),
                Expanded(
                  child: Slider(
                    value: settings.brightness < 0 ? 1.0 : settings.brightness,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => notifier.setBrightness(v),
                  ),
                ),
                const Icon(Icons.brightness_high, size: 20),
              ],
            ),

            const SizedBox(height: 8),

            // ---- Eye protection ----
            SwitchListTile(
              title: const Text('护眼模式'),
              subtitle: const Text('减少蓝光，缓解视觉疲劳'),
              value: settings.eyeProtection,
              onChanged: (v) => notifier.setEyeProtection(v),
              contentPadding: EdgeInsets.zero,
            ),

            if (settings.eyeProtection) ...[
              _buildSectionTitle(context, '护眼强度'),
              Row(
                children: [
                  const Icon(Icons.remove_red_eye, size: 20),
                  Expanded(
                    child: Slider(
                      value: settings.eyeProtectionIntensity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: '${(settings.eyeProtectionIntensity * 100).toInt()}%',
                      onChanged: (v) => notifier.setEyeProtectionIntensity(v),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(settings.eyeProtectionIntensity * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(
    BuildContext context, Color color, bool selected, VoidCallback onTap,
  ) {
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                )]
              : null,
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: isDark ? Colors.white70 : Colors.black54)
            : null,
      ),
    );
  }

  Widget _buildAddColorButton(BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        child: Icon(Icons.add, size: 20, color: Colors.grey.shade600),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context, ReadingSettingsNotifier notifier, int currentColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        currentColor: currentColor >= 0 ? Color(currentColor) : null,
        onColorSelected: (color) {
          final argb = ((color.a * 255).toInt() << 24) |
              ((color.r * 255).toInt() << 16) |
              ((color.g * 255).toInt() << 8) |
              (color.b * 255).toInt();
          notifier.setCustomBgColor(argb);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _pickBgImage(
    BuildContext context, ReadingSettingsNotifier notifier,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      notifier.setBgImagePath(result.files.single.path!);
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color? currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerDialog({this.currentColor, required this.onColorSelected});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r;
  late double _g;
  late double _b;

  static const _quickColors = [
    0xFFFFF8E1, 0xFFFFF3E0, 0xFFE8F5E9, 0xFFE3F2FD, 0xFFFCE4EC,
    0xFFF3E5F5, 0xFFE0F7FA, 0xFFFFFDE7, 0xFFEFEBE9, 0xFFECEFF1,
    0xFFD7CCC8, 0xFFCFD8DC, 0xFF263238, 0xFF37474F, 0xFF455A64,
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.currentColor ?? const Color(0xFFF5F0E6);
    _r = c.r.toDouble();
    _g = c.g.toDouble();
    _b = c.b.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Color.fromRGBO(
      (_r * 255).toInt(), (_g * 255).toInt(), (_b * 255).toInt(), 1,
    );
    final hexR = (_r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final hexG = (_g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final hexB = (_b * 255).toInt().toRadixString(16).padLeft(2, '0');

    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${hexR.toUpperCase()}${hexG.toUpperCase()}${hexB.toUpperCase()}',
                style: TextStyle(
                  color: ThemeData.estimateBrightnessForColor(selectedColor) == Brightness.dark
                      ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick colors
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickColors.map((c) {
                final color = Color(c);
                final isSelected = (color.r * 255).round() == (_r * 255).round() &&
                    (color.g * 255).round() == (_g * 255).round() &&
                    (color.b * 255).round() == (_b * 255).round();
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _r = color.r.toDouble();
                      _g = color.g.toDouble();
                      _b = color.b.toDouble();
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black54 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // RGB sliders
            _buildChannelSlider('R', _r, Colors.red, (v) => setState(() => _r = v)),
            _buildChannelSlider('G', _g, Colors.green, (v) => setState(() => _g = v)),
            _buildChannelSlider('B', _b, Colors.blue, (v) => setState(() => _b = v)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => widget.onColorSelected(selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildChannelSlider(
    String label, double value, Color color, ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(activeTrackColor: color, thumbColor: color),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 255,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 255).toInt()}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _AnimOption {
  final String value;
  final String label;
  final IconData icon;

  const _AnimOption(this.value, this.label, this.icon);
}

class _FontOption {
  final String value;
  final String label;

  const _FontOption(this.value, this.label);
}

class _WeightOption {
  final int value;
  final String label;

  const _WeightOption(this.value, this.label);
}
