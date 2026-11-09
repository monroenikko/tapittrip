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

  String _normalizePath(String path) {
    if (path.startsWith('/api/v1/')) {
      return path.substring(7);
    }
    if (path.startsWith('/v1/')) {
      return path.substring(3);
    }
    return path;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.get(_normalizePath(path), queryParameters: queryParameters),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.post(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.put(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.patch(
        _normalizePath(path),
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.delete(_normalizePath(path), queryParameters: queryParameters),
    );
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map && body.containsKey('data')) {
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

    final rawData = e.response?.data;
    if (rawData is Map) {
      final errorMap = rawData['error'];
      if (errorMap is Map) {
        final code = errorMap['code'] as String? ?? 'error';
        final message =
            errorMap['message'] as String? ?? 'An unexpected error occurred.';
        final rawDetails = errorMap['details'];
        final Map<String, dynamic> details = rawDetails is Map
            ? Map<String, dynamic>.from(rawDetails)
            : const {};

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
