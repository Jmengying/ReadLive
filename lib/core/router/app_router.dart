import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:readlive/features/bookshelf/presentation/groups_page.dart';
import 'package:readlive/features/profile/presentation/profile_page.dart';
import 'package:readlive/features/reader/presentation/reader_page.dart';
import 'package:readlive/features/settings/presentation/settings_page.dart';
import 'package:readlive/features/book_source/presentation/book_source_page.dart';
import 'package:readlive/features/book_source/presentation/search_page.dart';
import 'package:readlive/features/book_source/presentation/book_detail_page.dart';
import 'package:readlive/features/book_source/presentation/source_edit_page.dart';
import 'package:readlive/features/profile/presentation/stats_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookshelfPage(contentType: 'novel'),
          ),
        ),
        GoRoute(
          path: '/manga',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookshelfPage(contentType: 'manga'),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/reader/:bookId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final chapterIndex = int.tryParse(
            state.uri.queryParameters['chapter'] ?? '0') ?? 0;
        return ReaderPage(bookId: bookId, initialChapter: chapterIndex);
      },
    ),
    GoRoute(
      path: '/groups',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GroupsPage(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/sources',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BookSourcePage(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/source-edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final sourceId = state.uri.queryParameters['sourceId'] ?? '';
        return SourceEditPage(sourceId: sourceId);
      },
    ),
    GoRoute(
      path: '/stats',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StatsPage(),
    ),
    GoRoute(
      path: '/book-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final bookUrl = state.uri.queryParameters['bookUrl'] ?? '';
        final sourceId = state.uri.queryParameters['sourceId'] ?? '';
        final bookName = state.uri.queryParameters['bookName'] ?? '';
        return BookDetailPage(
          bookUrl: bookUrl,
          sourceId: sourceId,
          bookName: bookName,
        );
      },
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '书架',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/manga')) return 0;
    if (location.startsWith('/profile')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/profile');
    }
  }
}
