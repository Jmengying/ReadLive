import 'package:flutter_test/flutter_test.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';

void main() {
  group('RuleContext', () {
    test('put and get', () {
      final ctx = RuleContext();
      ctx.put('key1', 'value1');
      expect(ctx.get('key1'), 'value1');
    });

    test('get returns empty string for missing key', () {
      final ctx = RuleContext();
      expect(ctx.get('missing'), '');
    });

    test('containsKey', () {
      final ctx = RuleContext();
      expect(ctx.containsKey('key'), false);
      ctx.put('key', 'v');
      expect(ctx.containsKey('key'), true);
    });

    test('clear removes all variables', () {
      final ctx = RuleContext();
      ctx.put('a', '1');
      ctx.put('b', '2');
      ctx.clear();
      expect(ctx.get('a'), '');
      expect(ctx.get('b'), '');
    });

    test('variables returns unmodifiable view', () {
      final ctx = RuleContext();
      ctx.put('x', 'y');
      expect(ctx.variables, {'x': 'y'});
    });
  });
}
