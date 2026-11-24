import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import 'exception_mapper.dart';

/// Thin Dio wrapper: base URL, timeouts, JSON decoding, and translation
/// of transport errors into [Failure].
///
/// This is the ONLY place that knows about Dio. Datasources call
/// [getJson]; if something goes wrong they receive a [Failure] and
/// just rethrow it.
class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              // The brief requires distinguishable timeout/offline errors.
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 10),
              responseType: ResponseType.json,
            ),
          ) {
    // Request/response bodies are not logged: they may hold tokens
    // once this app talks to a real API.
    this.dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  final Dio dio;

  /// GET [path] and return the decoded JSON object.
  ///
  /// Throws [Failure] for transport problems and [FormatException]
  /// when the body is not a JSON object — both mapped to a user
  /// message by the repository.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('Response body is empty');
      }
      return data;
    } on DioException catch (exception) {
      throw mapDioExceptionToFailure(exception);
    }
  }
}
