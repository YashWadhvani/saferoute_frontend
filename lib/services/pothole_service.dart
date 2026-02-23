// lib/services/pothole_service.dart
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/pothole_model.dart';

class PotholeService {
  final Dio _dio = ApiClient.dio;

  /// Fetch potholes in bounding box
  Future<ApiResponse<List<PotholeData>>> fetchPotholes({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final response = await _dio.get(
        '/potholes',
        queryParameters: {
          'minLat': minLat,
          'maxLat': maxLat,
          'minLng': minLng,
          'maxLng': maxLng,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final potholesList = (data['data'] as List? ?? [])
          .map((json) => PotholeData.fromJson(json))
          .toList();

      return ApiResponse.success(potholesList);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get route score for pothole safety
  Future<ApiResponse<Map<String, dynamic>>> getRouteScore({
    required List<Map<String, double>> routeCoordinates,
    required double routeDistance,
  }) async {
    try {
      final response = await _dio.post(
        '/potholes/route-score',
        data: {
          'routeCoordinates': routeCoordinates,
          'routeDistance': routeDistance,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return ApiResponse.success(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      );
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get overall pothole statistics
  Future<ApiResponse<Map<String, dynamic>>> getStatistics() async {
    try {
      final response = await _dio.get('/potholes/stats');
      final data = response.data as Map<String, dynamic>;

      return ApiResponse.success(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      );
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Manually report a pothole
  Future<ApiResponse<bool>> reportPothole({
    required double latitude,
    required double longitude,
    required double intensity,
  }) async {
    try {
      await _dio.post(
        '/potholes',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'intensity': intensity,
        },
      );
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
