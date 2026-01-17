// lib/services/report_service.dart
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/report_model.dart';

class ReportService {
  final Dio _dio = ApiClient.dio;

  /// Submit a report
  Future<ApiResponse<Report>> submitReport({
    required String
        type, // 'harassment', 'theft', 'accident', 'dark_area', 'suspicious_activity'
    required String description,
    required double latitude,
    required double longitude,
    int severity = 3,
  }) async {
    try {
      final response = await _dio.post(
        '/reports',
        data: {
          'type': type,
          'description': description,
          'location': {'lat': latitude, 'lng': longitude},
          'severity': severity,
        },
      );
      final report = Report.fromJson(response.data);
      return ApiResponse.success(report);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get nearby reports
  Future<ApiResponse<List<Report>>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
        },
      );
      final reports =
          (response.data as List).map((r) => Report.fromJson(r)).toList();
      return ApiResponse.success(reports);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get reports submitted by the authenticated user
  Future<ApiResponse<List<Report>>> getUserReports() async {
    try {
      final response = await _dio.get('/reports/user');
      final reports =
          (response.data as List).map((r) => Report.fromJson(r)).toList();
      return ApiResponse.success(reports);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
