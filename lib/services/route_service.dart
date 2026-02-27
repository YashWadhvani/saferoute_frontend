// lib/services/route_service.dart
// ignore_for_file: unused_import

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/route_model.dart';

class RouteService {
  final Dio _dio = ApiClient.dio;

  /// Compare routes between origin and destination
  Future<ApiResponse<List<RouteData>>> compareRoutes({
    required LatLng origin,
    required LatLng destination,
    String? originName,
    String? destinationName,
  }) async {
    try {
      final response = await _dio.post(
        '/routes/compare',
        data: {
          'origin': {
            'lat': origin.latitude,
            'lng': origin.longitude,
            if (originName != null && originName.trim().isNotEmpty)
              'name': originName.trim(),
          },
          'destination': {
            'lat': destination.latitude,
            'lng': destination.longitude,
            if (destinationName != null && destinationName.trim().isNotEmpty)
              'name': destinationName.trim(),
          },
        },
      );

      final routesData = response.data['routes'] as List? ?? [];
      final routes = routesData
          .asMap()
          .entries
          .map((entry) {
            final i = entry.key;
            final r = Map<String, dynamic>.from(entry.value as Map);
            final poly = (r['polyline'] ?? '').toString();
            r['id'] = r['id'] ??
                'route_${i}_${poly.hashCode}_${r['distance']?['value'] ?? ''}_${r['duration']?['value'] ?? ''}';
            try {
              return RouteData.fromJson(r);
            } catch (e) {
              debugPrint('Error parsing route: $e');
              return null;
            }
          })
          .whereType<RouteData>()
          .toList();

      return ApiResponse.success(routes);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Fetch recent routes/searches for current authenticated user
  Future<ApiResponse<List<Map<String, dynamic>>>> getRecentRoutes() async {
    try {
      final response = await _dio.get('/routes/recent');
      final recent = List<Map<String, dynamic>>.from(
        (response.data['recentRoutes'] as List?) ?? const [],
      );
      return ApiResponse.success(recent);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
