// lib/services/auth_service.dart
// ignore_for_file: unused_local_variable

import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = ApiClient.dio;

  /// Send OTP to email or phone
  Future<ApiResponse<String>> sendOTP(String identifier) async {
    try {
      final response = await _dio.post(
        '/auth/send-otp',
        data: {'identifier': identifier},
      );
      return ApiResponse.success('OTP sent to $identifier');
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Verify OTP and get JWT token
  Future<ApiResponse<AuthResponse>> verifyOTP(
      String identifier, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {'identifier': identifier, 'otp': otp},
      );

      final token = response.data['token'] as String?;
      if (token == null) throw Exception('No token in response');

      final userData = response.data['user'] as Map<String, dynamic>? ?? {};
      final user = User.fromJson(userData);

      // Store token
      await ApiClient.setToken(token);

      return ApiResponse.success(AuthResponse(token: token, user: user));
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Clear stored token
  Future<void> logout() async {
    await ApiClient.clearToken();
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({required this.token, required this.user});
}
