// lib/core/api/api_response.dart
import 'package:dio/dio.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse({
    this.data,
    this.error,
    this.statusCode,
    this.isSuccess = false,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      data: data,
      statusCode: statusCode,
      isSuccess: true,
    );
  }

  factory ApiResponse.error(String error, {int statusCode = 500}) {
    return ApiResponse(
      error: error,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  factory ApiResponse.fromException(dynamic exception) {
    if (exception is DioException) {
      final message = exception.response?.data['error'] ??
          exception.response?.data['message'] ??
          exception.message ??
          'Unknown error occurred';
      return ApiResponse.error(
        message,
        statusCode: exception.response?.statusCode ?? 500,
      );
    }
    return ApiResponse.error(exception.toString());
  }
}
