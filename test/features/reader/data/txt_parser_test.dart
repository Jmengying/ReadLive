import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/reader/data/txt_parser.dart';

void main() {
  final parser = TxtParser();

  test('splitChapters detects chapter headings', () {
    const text = '''
第一章 开始
这是第一章的内容。

第二章 发展
这是第二章的内容。

第三章 高潮
这是第三章的内容。
''';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 3);
    expect(chapters[0].title, '第一章 开始');
    expect(chapters[1].title, '第二章 发展');
    expect(chapters[2].title, '第三章 高潮');
    expect(chapters[0].content, contains('这是第一章'));
  });

  test('splitChapters handles text without chapters', () {
    const text = '这是一段很长的文本内容，没有章节标记。';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 1);
    expect(chapters[0].title, '开始');
  });

  test('splitChapters handles numeric chapter numbers', () {
    const text = '''
第1章 开始
内容1

第2章 发展
内容2
''';
    final chapters = parser.splitChapters(text);
    expect(chapters.length, 2);
    expect(chapters[0].title, '第1章 开始');
  });
}
