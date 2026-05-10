// lib/core/network/http_client.dart
import 'package:dio/dio.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._();
  factory HttpClient() => _instance;

  late final Dio _dio;

  HttpClient._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.headers['Referer'] == null) {
          final uri = Uri.tryParse(options.uri.toString());
          if (uri != null) {
            options.headers['Referer'] = '${uri.scheme}://${uri.host}';
          }
        }
        handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response<String>> getHtml(
    String url, {
    String? encoding,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
    return response;
  }

  Future<Response<String>> postHtml(
    String url, {
    dynamic data,
    String? encoding,
    Map<String, String>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<String>(
      url,
      data: data,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
    return response;
  }

  void close() {
    _dio.close();
  }
}
