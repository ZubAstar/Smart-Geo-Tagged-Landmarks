// lib/core/network/dio_client.dart

import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[DIO] $obj'),
      ),
      _ApiKeyInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(
    String action, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(
        '',
        queryParameters: {
          'action': action,
          'key': AppConstants.apiKey,
          ...?queryParams,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String action,
    dynamic data, {
    Options? options,
  }) async {
    try {
      return await _dio.post(
        '',
        queryParameters: {
          'action': action,
          'key': AppConstants.apiKey,
        },
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timed out');
      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final msg = e.response?.data?['message'] ?? 'Server error';
        return ServerException(msg.toString(), statusCode: code);
      default:
        return NetworkException(e.message ?? 'Unknown network error');
    }
  }
}

class _ApiKeyInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.queryParameters.putIfAbsent('key', () => AppConstants.apiKey);
    handler.next(options);
  }
}
