import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/theme/app_theme.dart';
import 'package:readlive/features/settings/presentation/settings_provider.dart';

class ReadingSettingsPanel extends ConsumerWidget {
  const ReadingSettingsPanel({super.key});

  static const _bgLabels = ['暖白', '米黄', '浅绿', '深灰', '纯黑'];

  static const _animationOptions = <_AnimOption>[
    _AnimOption('slide', '滑动', Icons.swipe),
    _AnimOption('fade', '淡入', Icons.opacity),
    _AnimOption('scroll', '滚动', Icons.swap_vert),
    _AnimOption('none', '无', Icons.block),
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

            // ---- Background color presets ----
            _buildSectionTitle(context, '背景色'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(AppTheme.readingBackgrounds.length, (i) {
                  final selected = settings.bgIndex == i;
                  final color = AppTheme.readingBackgrounds[i];
                  final isDark = ThemeData.estimateBrightnessForColor(color) ==
                      Brightness.dark;
                  return GestureDetector(
                    onTap: () => notifier.setBgIndex(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
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
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bgLabels[i],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }),
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
          ],
        ),
      ),
    );
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

class _AnimOption {
  final String value;
  final String label;
  final IconData icon;

  const _AnimOption(this.value, this.label, this.icon);
}
