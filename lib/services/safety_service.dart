// lib/services/safety_service.dart
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/safety_model.dart';

class SafetyService {
  final Dio _dio = ApiClient.dio;

  /// Get GeoJSON for safety cells
  Future<ApiResponse<GeoJSONFeatureCollection>> getSafetyGeoJSON(
    List<String> areaIds,
  ) async {
    try {
      final response = await _dio.get(
        '/safety/geojson',
        queryParameters: {'areaIds': areaIds.join(',')},
      );
      final geoJson = GeoJSONFeatureCollection.fromJson(response.data);
      return ApiResponse.success(geoJson);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Get all safety cells (limited)
  Future<ApiResponse<GeoJSONFeatureCollection>> getAllSafetyGeoJSON({
    int limit = 1000,
  }) async {
    try {
      final response = await _dio.get(
        '/safety/all-geojson',
        queryParameters: {'limit': limit},
      );
      final geoJson = GeoJSONFeatureCollection.fromJson(response.data);
      return ApiResponse.success(geoJson);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
