import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readlive/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ReadLiveApp(),
      ),
    );

    expect(find.byType(ReadLiveApp), findsOneWidget);
  });
}
