import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:readlive/features/bookshelf/presentation/bookshelf_provider.dart';
import 'package:readlive/features/book_source/data/book_source_repository.dart';
import 'package:readlive/features/book_source/data/chapter_crawler.dart';
import 'package:readlive/features/book_source/data/content_extractor.dart';
import 'package:readlive/features/book_source/data/html_fetcher.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';
import 'package:readlive/features/book_source/data/rule_parser.dart';
import 'package:readlive/features/book_source/data/search_service.dart';
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

// Search service
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    fetcher: ref.watch(htmlFetcherProvider),
    extractor: ref.watch(contentExtractorProvider),
    parser: ref.watch(ruleParserProvider),
  );
});

// Search state

/// Per-source search state for tracking individual source results.
class SourceSearchState {
  final String sourceId;
  final String sourceName;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SourceSearchState({
    required this.sourceId,
    required this.sourceName,
    this.results = const [],
    this.isLoading = true,
    this.error,
  });

  SourceSearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SourceSearchState(
      sourceId: sourceId,
      sourceName: sourceName,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Overall search state aggregating per-source states.
class SearchState {
  final String query;
  final List<SourceSearchState> sourceStates;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.sourceStates = const [],
    this.isLoading = false,
  });

  List<SearchResult> get results =>
      sourceStates.expand((s) => s.results).toList();

  int get loadingCount =>
      sourceStates.where((s) => s.isLoading).length;

  int get completedCount =>
      sourceStates.where((s) => !s.isLoading).length;

  int get totalResultCount =>
      sourceStates.fold(0, (sum, s) => sum + s.results.length);
}

class SearchNotifier extends StateNotifier<SearchState> {
  final BookSourceRepository _repo;
  final SearchService _service;
  CancelToken? _cancelToken;

  SearchNotifier(this._repo, this._service) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final cancelToken = _cancelToken!;

    final sources = await _repo.getEnabledSources();
    final sourcesWithSearch =
        sources.where((s) => s.parseRule().search != null).toList();

    state = SearchState(
      query: query,
      isLoading: true,
      sourceStates: sourcesWithSearch
          .map((s) => SourceSearchState(
                sourceId: s.id,
                sourceName: s.name,
              ))
          .toList(),
    );

    final futures = sourcesWithSearch
        .map((source) => _searchOneSource(source, query, cancelToken));

    await Future.wait(futures, eagerError: false);

    if (!cancelToken.isCancelled) {
      state = SearchState(
        query: state.query,
        sourceStates: state.sourceStates,
        isLoading: false,
      );
    }
  }

  Future<void> _searchOneSource(
    BookSourceEntity source,
    String keyword,
    CancelToken cancelToken,
  ) async {
    try {
      final context = RuleContext();
      final results = await _service.searchSource(
        source: source,
        keyword: keyword,
        context: context,
        cancelToken: cancelToken,
      );

      _updateSourceState(source.id, (s) => s.copyWith(
            results: results,
            isLoading: false,
          ));
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) return;
      _updateSourceState(source.id, (s) => s.copyWith(
            isLoading: false,
            error: e.toString(),
          ));
    }
  }

  void _updateSourceState(
    String sourceId,
    SourceSearchState Function(SourceSearchState) updater,
  ) {
    final updated = state.sourceStates.map((s) {
      if (s.sourceId == sourceId) return updater(s);
      return s;
    }).toList();

    state = SearchState(
      query: state.query,
      sourceStates: updated,
      isLoading: state.isLoading,
    );
  }

  void cancel() {
    _cancelToken?.cancel();
    state = SearchState(
      query: state.query,
      sourceStates: state.sourceStates
          .map((s) => s.isLoading
              ? s.copyWith(isLoading: false, error: '已取消')
              : s)
          .toList(),
      isLoading: false,
    );
  }

  void clear() {
    _cancelToken?.cancel();
    state = const SearchState();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(
    ref.watch(bookSourceRepositoryProvider),
    ref.watch(searchServiceProvider),
  );
});
