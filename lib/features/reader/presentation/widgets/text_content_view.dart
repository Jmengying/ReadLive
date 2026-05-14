import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HighlightRange {
  final int startOffset;
  final int endOffset;
  final Color color;

  const HighlightRange({
    required this.startOffset,
    required this.endOffset,
    required this.color,
  });
}

class TextContentView extends StatelessWidget {
  final String text;
  final double fontSize;
  final double lineHeight;
  final Color textColor;
  final Color backgroundColor;
  final String fontFamily;
  final int fontWeight;
  final double firstLineIndent;
  final double letterSpacing;
  final bool eyeProtection;
  final double eyeProtectionIntensity;
  final bool scrollable;
  final List<HighlightRange> highlights;
  final String? imageDirPath; // Base directory for resolving relative image paths

  static final _imgPattern = RegExp(r'\[\[IMG:(.*?)\]\]');

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
    this.letterSpacing = 0.0,
    this.eyeProtection = false,
    this.eyeProtectionIntensity = 0.3,
    this.scrollable = true,
    this.highlights = const [],
    this.imageDirPath,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: textColor,
      fontWeight: _parseFontWeight(fontWeight),
      fontFamily: fontFamily == 'system' ? null : fontFamily,
      letterSpacing: letterSpacing,
    );

    final indentedText = _applyIndent(text, firstLineIndent);
    final hasImages = _imgPattern.hasMatch(indentedText);
    final hasHighlights = highlights.isNotEmpty;

    Widget textWidget;
    if (hasHighlights && !hasImages) {
      textWidget = _buildHighlightText(indentedText, style);
    } else if (hasImages) {
      textWidget = RichText(
          text: TextSpan(style: style, children: _buildSpans(indentedText, style)));
    } else {
      textWidget = Text(indentedText, style: style);
    }

    Widget content = Container(
      color: backgroundColor,
      width: double.infinity,
      height: scrollable ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      child: scrollable
          ? SingleChildScrollView(child: textWidget)
          : textWidget,
    );

    if (eyeProtection) {
      final alpha = (eyeProtectionIntensity * 0x80).toInt().clamp(0, 0xFF);
      content = Stack(
        children: [
          content,
          Container(
            color: Color.fromRGBO(0xFF, 0xBE, 0x76, alpha / 255.0),
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      );
    }

    return SelectionArea(
      child: content,
    );
  }

  Widget _buildHighlightText(String text, TextStyle style) {
    if (highlights.isEmpty) {
      return Text(text, style: style);
    }

    // Sort highlights by start offset
    final sorted = List<HighlightRange>.from(highlights)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final hl in sorted) {
      final start = hl.startOffset.clamp(0, text.length);
      final end = hl.endOffset.clamp(0, text.length);

      if (start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, start)));
      }
      if (start < end) {
        spans.add(TextSpan(
          text: text.substring(start, end),
          style: TextStyle(backgroundColor: hl.color.withAlpha(80)),
        ));
      }
      lastEnd = end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
    );
  }

  List<InlineSpan> _buildSpans(String text, TextStyle style) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _imgPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }
      final imagePath = match.group(1) ?? '';
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _buildImageWidget(imagePath),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return spans;
  }

  Widget _buildImageWidget(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }
    return _buildImage(file);
  }

  Widget _buildImage(File file) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  String _applyIndent(String text, double indent) {
    if (indent <= 0) return text;
    final spaces = '　' * indent.toInt();
    return text.split('\n').map((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('[[IMG:')) return trimmed;
      return '$spaces$trimmed';
    }).join('\n');
  }

  FontWeight _parseFontWeight(int weight) {
    final index = ((weight ~/ 100) - 1).clamp(0, 8);
    return FontWeight.values[index];
  }
}
