// lib/services/user_service.dart
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/user_model.dart';

class UserService {
  final Dio _dio = ApiClient.dio;

  /// Get current user profile
  Future<ApiResponse<User>> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final user = User.fromJson(response.data);
      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile(String name) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: {'name': name},
      );
      final user = User.fromJson(response.data);
      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get emergency contacts
  Future<ApiResponse<List<EmergencyContact>>> getContacts() async {
    try {
      final response = await _dio.get('/users/me/contacts');
      final contacts = (response.data as List)
          .map((c) => EmergencyContact.fromJson(c))
          .toList();
      return ApiResponse.success(contacts);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Add emergency contact
  Future<ApiResponse<List<EmergencyContact>>> addContact(
    String name,
    String phone,
  ) async {
    try {
      final response = await _dio.post(
        '/users/me/contacts',
        data: {'name': name, 'phone': phone},
      );
      final contacts = (response.data as List)
          .map((c) => EmergencyContact.fromJson(c))
          .toList();
      return ApiResponse.success(contacts);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Delete emergency contact
  Future<ApiResponse<List<EmergencyContact>>> deleteContact(
      String contactId) async {
    try {
      final response = await _dio.delete('/users/me/contacts/$contactId');
      final contacts = (response.data as List)
          .map((c) => EmergencyContact.fromJson(c))
          .toList();
      return ApiResponse.success(contacts);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
