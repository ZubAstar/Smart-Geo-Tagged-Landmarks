// lib/core/errors/app_exception.dart

abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection'])
      : super(message);
}

class ServerException extends AppException {
  const ServerException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

class CacheException extends AppException {
  const CacheException([String message = 'Cache error']) : super(message);
}

class LocationException extends AppException {
  const LocationException([String message = 'Location unavailable'])
      : super(message);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

// Result wrapper
class Result<T> {
  final T? data;
  final AppException? error;

  const Result.success(this.data) : error = null;
  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(error!);
  }
}
