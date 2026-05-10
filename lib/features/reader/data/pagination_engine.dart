import 'package:flutter/material.dart';
import 'package:readlive/features/reader/domain/page_content.dart';

class PaginationEngine {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double screenWidth;
  final double screenHeight;
  final EdgeInsets padding;

  PaginationEngine({
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.screenWidth,
    required this.screenHeight,
    required this.padding,
  });

  List<PageContent> paginate(String text) {
    if (text.isEmpty) {
      return [const PageContent(text: '', startIndex: 0, endIndex: 0)];
    }

    final availableWidth = screenWidth - padding.left - padding.right;
    final availableHeight = screenHeight - padding.top - padding.bottom;
    final actualLineHeight = fontSize * lineHeight;
    final linesPerPage = (availableHeight / actualLineHeight).floor();

    if (linesPerPage <= 0) {
      return [PageContent(text: text, startIndex: 0, endIndex: text.length)];
    }

    // Approximate characters per line (Chinese characters are ~fontSize wide)
    final charsPerLine = (availableWidth / fontSize).floor();
    if (charsPerLine <= 0) {
      return [PageContent(text: text, startIndex: 0, endIndex: text.length)];
    }

    final paragraphs = text.split('\n');
    final pages = <PageContent>[];
    var currentText = StringBuffer();
    var currentLines = 0;
    var startIndex = 0;
    var charOffset = 0;

    for (var i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      final paraLines = (para.length / charsPerLine).ceil().clamp(1, 999);

      if (currentLines + paraLines > linesPerPage && currentText.isNotEmpty) {
        pages.add(PageContent(
          text: currentText.toString().trim(),
          startIndex: startIndex,
          endIndex: charOffset,
        ));
        currentText = StringBuffer();
        currentLines = 0;
        startIndex = charOffset;
      }

      currentText.writeln(para);
      currentLines += paraLines;
      // Add paragraph spacing as ~1 line
      if (i < paragraphs.length - 1) {
        currentLines += 1;
      }
      charOffset += para.length + 1; // +1 for newline
    }

    if (currentText.isNotEmpty) {
      pages.add(PageContent(
        text: currentText.toString().trim(),
        startIndex: startIndex,
        endIndex: charOffset,
      ));
    }

    return pages.isEmpty
        ? [const PageContent(text: '', startIndex: 0, endIndex: 0)]
        : pages;
  }
}
