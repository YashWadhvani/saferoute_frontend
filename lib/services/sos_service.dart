// lib/services/sos_service.dart
import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_response.dart';
import '../models/sos_model.dart';

class SOSService {
  final Dio _dio = ApiClient.dio;

  /// Trigger SOS alert
  Future<ApiResponse<SOSAlert>> triggerSOS({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        '/sos/trigger',
        data: {
          'location': {'lat': latitude, 'lng': longitude},
          'contactsNotified': [],
        },
      );
      final sos = SOSAlert.fromJson(response.data);
      return ApiResponse.success(sos);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }

  /// Resolve SOS alert
  Future<ApiResponse<SOSAlert>> resolveSOS(String sosId) async {
    try {
      final response = await _dio.patch('/sos/$sosId/resolve');
      final sos = SOSAlert.fromJson(response.data);
      return ApiResponse.success(sos);
    } on DioException catch (e) {
      return ApiResponse.fromException(e);
    }
  }
}
