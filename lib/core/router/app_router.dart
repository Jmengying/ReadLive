import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:readlive/features/bookshelf/presentation/groups_page.dart';
import 'package:readlive/features/reader/presentation/reader_page.dart';
import 'package:readlive/features/settings/presentation/settings_page.dart';
import 'package:readlive/features/book_source/presentation/book_source_page.dart';
import 'package:readlive/features/book_source/presentation/search_page.dart';
import 'package:readlive/features/book_source/presentation/book_detail_page.dart';
import 'package:readlive/features/book_source/presentation/source_edit_page.dart';
import 'package:readlive/features/profile/presentation/stats_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const BookshelfPage(contentType: 'novel'),
    ),
    GoRoute(
      path: '/manga',
      builder: (context, state) => const BookshelfPage(contentType: 'manga'),
    ),
    GoRoute(
      path: '/reader/:bookId',
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final chapterIndex = int.tryParse(
            state.uri.queryParameters['chapter'] ?? '0') ?? 0;
        return ReaderPage(bookId: bookId, initialChapter: chapterIndex);
      },
    ),
    GoRoute(
      path: '/groups',
      builder: (context, state) => const GroupsPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/sources',
      builder: (context, state) => const BookSourcePage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/source-edit',
      builder: (context, state) {
        final sourceId = state.uri.queryParameters['sourceId'] ?? '';
        return SourceEditPage(sourceId: sourceId);
      },
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsPage(),
    ),
    GoRoute(
      path: '/book-detail',
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
