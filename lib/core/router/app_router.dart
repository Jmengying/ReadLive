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
      pageBuilder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final chapterIndex = int.tryParse(
            state.uri.queryParameters['chapter'] ?? '0') ?? 0;
        return CustomTransitionPage(
          child: ReaderPage(bookId: bookId, initialChapter: chapterIndex),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Opening: slide up + fade in
            // Closing: slide down + fade out
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: curved,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
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
      pageBuilder: (context, state) {
        final bookUrl = state.uri.queryParameters['bookUrl'] ?? '';
        final sourceId = state.uri.queryParameters['sourceId'] ?? '';
        final bookName = state.uri.queryParameters['bookName'] ?? '';
        return CustomTransitionPage(
          child: BookDetailPage(
            bookUrl: bookUrl,
            sourceId: sourceId,
            bookName: bookName,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
      },
    ),
  ],
);
