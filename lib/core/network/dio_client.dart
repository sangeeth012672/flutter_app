// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete<T>(path, queryParameters: queryParameters);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ [${options.method}] ${options.uri}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← [${response.statusCode}] ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ [${err.type}] ${err.requestOptions.uri}: ${err.message}');
    super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Map DioException to AppException and rethrow
    final mapped = _mapError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: mapped,
        message: mapped.message,
        type: err.type,
      ),
    );
  }

  AppException _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final message = _extractMessage(err.response);
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: err.message ?? 'An unexpected error occurred.',
        );
    }
  }

  String _extractMessage(Response? response) {
    if (response == null) return 'Server error occurred.';
    try {
      final data = response.data;
      if (data is Map) {
        return data['detail']?.toString() ??
            data['message']?.toString() ??
            'Server error (${response.statusCode})';
      }
    } catch (_) {}
    return 'Server error (${response.statusCode})';
  }
}

AppException dioToAppException(DioException e) {
  if (e.error is AppException) return e.error as AppException;
  if (e.type == DioExceptionType.connectionError) {
    return const NetworkException();
  }
  return ServerException(message: e.message ?? 'Unknown error');
}

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
