import 'package:flutter/material.dart';

class TextContentView extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;

  const TextContentView({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.lineHeight = 1.8,
    this.textColor = const Color(0xFF333333),
    this.backgroundColor = const Color(0xFFF5F0E6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          ),
        ),
      ),
    );
  }
}
