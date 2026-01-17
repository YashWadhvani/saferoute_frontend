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
  }) async {
    try {
      final response = await _dio.post(
        '/routes/compare',
        data: {
          'origin': {'lat': origin.latitude, 'lng': origin.longitude},
          'destination': {
            'lat': destination.latitude,
            'lng': destination.longitude
          },
        },
      );

      final routesData = response.data['routes'] as List? ?? [];
      final routes = routesData
          .map((r) {
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
}
