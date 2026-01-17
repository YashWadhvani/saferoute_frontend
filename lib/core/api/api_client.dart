// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl =
      'https://saferoute-backend-nw9n.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 10);

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeoutDuration,
      receiveTimeout: timeoutDuration,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static void initialize() {
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
  }

  static Dio get dio => _dio;

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    _dio.options.headers.remove('Authorization');
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await ApiClient._storage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('🔵 [${options.method}] ${options.path}');
      if (options.data != null) debugPrint('📤 Body: ${options.data}');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('🟢 [${response.statusCode}] ${response.requestOptions.path}');
      debugPrint('📥 Response: ${response.data}');
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode) {
      debugPrint('🔴 [ERROR] ${err.requestOptions.path}');
      debugPrint('❌ ${err.response?.statusCode}: ${err.response?.data}');
    }
    return handler.next(err);
  }
}
