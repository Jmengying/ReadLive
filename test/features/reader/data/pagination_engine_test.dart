import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:readlive/features/reader/data/pagination_engine.dart';

void main() {
  test('paginate splits text into pages based on dimensions', () {
    const text = '这是第一段内容。\n\n这是第二段内容。\n\n这是第三段内容。';
    final engine = PaginationEngine(
      fontSize: 18,
      lineHeight: 1.8,
      paragraphSpacing: 16,
      screenWidth: 360,
      screenHeight: 640,
      padding: const EdgeInsets.all(16),
    );
    final pages = engine.paginate(text);
    expect(pages, isNotEmpty);
    expect(pages.first.text, isNotEmpty);
  });

  test('paginate handles empty text', () {
    final engine = PaginationEngine(
      fontSize: 18,
      lineHeight: 1.8,
      paragraphSpacing: 16,
      screenWidth: 360,
      screenHeight: 640,
      padding: const EdgeInsets.all(16),
    );
    final pages = engine.paginate('');
    expect(pages.length, 1);
    expect(pages.first.text, '');
  });
}
