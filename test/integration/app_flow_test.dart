import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readlive/app.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/bookshelf/domain/book_entity.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches and shows bookshelf', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booksStreamProvider.overrideWith(
            (ref) => Stream<List<BookEntity>>.value([]),
          ),
        ],
        child: const ReadLiveApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Should show bookshelf with novel/manga tabs
    expect(find.text('小说'), findsOneWidget);
    expect(find.text('漫画'), findsOneWidget);

    // Should show bottom navigation
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('Navigate to profile page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booksStreamProvider.overrideWith(
            (ref) => Stream<List<BookEntity>>.value([]),
          ),
        ],
        child: const ReadLiveApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Tap on 我的 tab
    await tester.tap(find.text('我的'));
    await tester.pump(const Duration(seconds: 2));

    // Should show profile page with 书源管理 menu item
    expect(find.text('书源管理'), findsOneWidget);
  });
}
