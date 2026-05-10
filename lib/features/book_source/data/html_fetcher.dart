import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:readlive/core/network/http_client.dart';

class HtmlFetcher {
  final HttpClient _client;
  static const _maxRetries = 3;

  HtmlFetcher({HttpClient? client}) : _client = client ?? HttpClient();

  /// Fetch HTML content from a URL with retry logic.
  Future<String> fetch(
    String url, {
    String? encoding,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    Exception? lastException;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (encoding != null && encoding.toLowerCase() != 'utf-8') {
          return await fetchWithEncoding(url, encoding,
              headers: headers, cancelToken: cancelToken);
        }

        final response = await _client.getHtml(
          url,
          headers: headers,
          cancelToken: cancelToken,
        );

        return response.data ?? '';
      } on DioException catch (e) {
        lastException = e;
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    throw lastException ?? Exception('Failed to fetch $url');
  }

  /// Fetch via POST request.
  Future<String> post(
    String url, {
    dynamic data,
    String? encoding,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    Exception? lastException;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _client.postHtml(
          url,
          data: data,
          headers: headers,
          cancelToken: cancelToken,
        );
        return response.data ?? '';
      } on DioException catch (e) {
        lastException = e;
        if (e.type == DioExceptionType.cancel) rethrow;
        if (attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    }

    throw lastException ?? Exception('Failed to POST $url');
  }

  /// Fetch raw bytes and decode with specified encoding.
  Future<String> fetchWithEncoding(
    String url,
    String encoding, {
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await _client.dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );

    final bytes = Uint8List.fromList(response.data ?? <int>[]);
    return _decodeBytes(bytes, encoding);
  }

  String _decodeBytes(Uint8List bytes, String encoding) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {}

    return latin1.decode(bytes);
  }
}
