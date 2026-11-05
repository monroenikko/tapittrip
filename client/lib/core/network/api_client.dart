import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  ApiClient({required this.tokenStorage, String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            await tokenStorage.deleteToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  final TokenStorage tokenStorage;
  final Dio _dio;

  Dio get dio => _dio;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.put(path, data: data, queryParameters: queryParameters),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(() => _dio.delete(path, queryParameters: queryParameters));
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      throw _parseDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(code: 'unknown_error', message: e.toString());
    }
  }

  ApiException _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      final errorMap = data['error'] as Map<String, dynamic>;
      final code = errorMap['code'] as String? ?? 'error';
      final message =
          errorMap['message'] as String? ?? 'An unexpected error occurred.';
      final details = errorMap['details'] as Map<String, dynamic>? ?? {};

      if (code == 'validation_failed') {
        return ValidationException(
          message: message,
          details: details,
          statusCode: e.response?.statusCode ?? 422,
        );
      }
      if (e.response?.statusCode == 401 || code == 'unauthenticated') {
        return UnauthenticatedException(message);
      }
      return ApiException(
        code: code,
        message: message,
        statusCode: e.response?.statusCode,
        details: details,
      );
    }

    return ApiException(
      code: 'http_${e.response?.statusCode ?? 'unknown'}',
      message: e.message ?? 'Server communication failed.',
      statusCode: e.response?.statusCode,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});
