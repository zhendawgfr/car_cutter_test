import 'dart:developer' as developer;

import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final String message;
  final String userMessage;
  final int? statusCode;

  ApiException(this.message, this.userMessage, [this.statusCode]);

  @override
  String toString() => message;
}

class RateLimitException extends ApiException {
  RateLimitException([String? message])
    : super(
        message ?? 'Rate limit exceeded',
        'Rate limit exceeded. Please try again later.',
        429,
      );
}

class TimeoutException extends ApiException {
  TimeoutException([String? message])
    : super(
        message ?? 'Connection timeout',
        'Connection timeout. Check your internet.',
      );
}

class ConnectionException extends ApiException {
  ConnectionException([String? message])
    : super(message ?? 'No internet connection', 'No internet connection');
}

// Server errors (5xx)
class ServerException extends ApiException {
  ServerException(String message, [int? statusCode])
    : super(message, 'Server error. Please try again later.', statusCode);
}

// Client errors (4xx, except 429)
class ClientException extends ApiException {
  ClientException(String message, [int? statusCode])
    : super(message, 'Request failed. Please check your input.', statusCode);
}

// HTTP client with error handling
class ApiClient {
  late final Dio _dio;
  static const String baseUrl = 'https://dummy.restapiexample.com/api/v1';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add error logging interceptor
    _dio.interceptors.add(LoggingInterceptor());
  }

  Dio get dio => _dio;
}

// Logs requests and errors
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '🌐 REQUEST[${options.method}] => PATH: ${options.path}\n📦 Data: ${options.data}',
      name: 'ApiClient',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    developer.log(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n📦 Data: ${response.data}',
      name: 'ApiClient',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n📦 Error: ${err.message}\n📦 Response: ${err.response?.data}',
      name: 'ApiClient',
      error: err,
    );
    super.onError(err, handler);
  }
}

// Employee API endpoints
class EmployeeApi {
  final ApiClient _apiClient;

  EmployeeApi(this._apiClient);

  // Get all employees
  Future<Map<String, dynamic>> getEmployees() async {
    try {
      final response = await _apiClient.dio.get('/employees');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get employee by ID
  Future<Map<String, dynamic>> getEmployee(int id) async {
    try {
      final response = await _apiClient.dio.get('/employee/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create new employee
  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/create', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update employee by ID
  Future<Map<String, dynamic>> updateEmployee(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.dio.put('/update/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete employee by ID
  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await _apiClient.dio.delete('/delete/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle Dio errors and convert to meaningful exceptions
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Unknown error';

        // Handle specific status codes
        if (statusCode == 429) {
          return RateLimitException(message);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(message, statusCode);
        } else {
          return ClientException(message, statusCode);
        }
      case DioExceptionType.cancel:
        return ClientException('Request cancelled');
      case DioExceptionType.connectionError:
        return ConnectionException();
      default:
        return ClientException('Unexpected error: ${error.message}');
    }
  }
}
