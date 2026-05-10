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
          _applyIndent(text, firstLineIndent),
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

    if (eyeProtection) {
      content = Stack(
        children: [
          content,
          Container(
            color: const Color(0x1AFFBE76),
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      );
    }

    return content;
  }

  String _applyIndent(String text, double indent) {
    if (indent <= 0) return text;
    final spaces = '　' * indent.toInt();
    return text.split('\n').map((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return '';
      return '$spaces$trimmed';
    }).join('\n');
  }

  FontWeight _parseFontWeight(int weight) {
    final index = ((weight ~/ 100) - 1).clamp(0, 8);
    return FontWeight.values[index];
  }
}
