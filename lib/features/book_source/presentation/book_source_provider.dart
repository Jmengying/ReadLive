import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/core/network/url_utils.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/book_source/data/book_source_repository.dart';
import 'package:readlive/features/book_source/data/chapter_crawler.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/data/source_tester.dart';
import 'package:readlive/features/book_source/domain/book_source_entity.dart';
import 'package:readlive/features/book_source/domain/search_result.dart';

// Infrastructure
final ruleParserProvider = Provider<RuleParser>((ref) => RuleParser());
final htmlFetcherProvider = Provider<HtmlFetcher>((ref) => HtmlFetcher());
final contentExtractorProvider = Provider<ContentExtractor>((ref) {
  return ContentExtractor(ruleParser: ref.watch(ruleParserProvider));
});

final chapterCrawlerProvider = Provider<ChapterCrawler>((ref) {
  return ChapterCrawler(
    fetcher: ref.watch(htmlFetcherProvider),
    extractor: ref.watch(contentExtractorProvider),
  );
});

final sourceTesterProvider = Provider<SourceTester>((ref) {
  return SourceTester(
    fetcher: ref.watch(htmlFetcherProvider),
    extractor: ref.watch(contentExtractorProvider),
    parser: ref.watch(ruleParserProvider),
  );
});

// Repository
final bookSourceRepositoryProvider = Provider<BookSourceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BookSourceRepository(db);
});

// All sources stream
final bookSourcesStreamProvider = StreamProvider<List<BookSourceEntity>>((ref) {
  final repo = ref.watch(bookSourceRepositoryProvider);
  return repo.watchAllSources();
});

// Enabled sources
final enabledSourcesProvider = FutureProvider<List<BookSourceEntity>>((ref) {
  final repo = ref.watch(bookSourceRepositoryProvider);
  return repo.getEnabledSources();
});

// Search state
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final BookSourceRepository _repo;
  final HtmlFetcher _fetcher;
  final ContentExtractor _extractor;
  final RuleParser _parser;

  SearchNotifier(this._repo, this._fetcher, this._extractor, this._parser)
      : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(query: query, isLoading: true, error: null, results: []);

    try {
      final sources = await _repo.getEnabledSources();

      for (final source in sources) {
        try {
          final rule = source.parseRule();
          if (rule.search == null) continue;

          final rawUrl = _parser.resolveTemplate(
            rule.search!.url,
            {'key': query, 'page': '1'},
          );

          // Handle @post: prefix (Legado format)
          final String html;
          if (rawUrl.startsWith('@post:')) {
            final postBody = rawUrl.substring(6);
            final parts = postBody.split(',');
            final postUrl = resolveUrl(source.host, parts.first.trim());
            final postData = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
            html = await _fetcher.post(postUrl, data: postData);
          } else {
            final url = resolveUrl(source.host, rawUrl);
            html = await _fetcher.fetch(url);
          }

          final results = _extractor.extractSearchResults(
            html,
            rule.search!,
            source.id,
            source.name,
          );

          // Update state incrementally - show results as they come in
          if (results.isNotEmpty) {
            state = state.copyWith(
              results: [...state.results, ...results],
            );
          }
        } catch (_) {
          // Skip failed sources, continue with others
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '搜索失败: $e',
      );
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(
    ref.watch(bookSourceRepositoryProvider),
    ref.watch(htmlFetcherProvider),
    ref.watch(contentExtractorProvider),
    ref.watch(ruleParserProvider),
  );
});
