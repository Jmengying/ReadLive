import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_handlers/js_handler.dart';

void main() {
  late JsHandler handler;
  late RuleContext context;

  setUp(() {
    handler = JsHandler();
    context = RuleContext();
  });

  group('JsHandler', () {
    test('execute simple JS expression', () async {
      final result = await handler.execute('var result = "hello";', context);
      expect(result, 'hello');
    });

    test('execute JS with string manipulation', () async {
      final result = await handler.execute(
        'var result = "Hello World".toLowerCase();',
        context,
      );
      expect(result, 'hello world');
    });

    test('execute JS returning number', () async {
      final result = await handler.execute('var result = 42;', context);
      expect(result, '42');
    });

    test('java.encodeURI works', () async {
      final result = await handler.execute(
        "var result = java.encodeURI('hello world');",
        context,
      );
      expect(result, contains('hello'));
    });

    test('java.put and java.get work', () async {
      await handler.execute("java.put('myKey', 'myValue');", context);
      expect(context.get('myKey'), 'myValue');

      final result = await handler.execute(
        "var result = java.get('myKey');",
        context,
      );
      expect(result, 'myValue');
    });

    test('isJsRule detects <js> tags', () {
      expect(JsHandler.isJsRule('<js>var result = 1;</js>'), true);
      expect(JsHandler.isJsRule('@js:return "hi";'), true);
      expect(JsHandler.isJsRule('.title@text'), false);
    });

    test('extractJsCode extracts code from <js> tags', () {
      final code = JsHandler.extractJsCode('<js>var result = 1;</js>');
      expect(code, 'var result = 1;');
    });

    test('extractJsCode extracts code from @js: prefix', () {
      final code = JsHandler.extractJsCode('@js:return "hi";');
      expect(code, 'return "hi";');
    });
  });
}
