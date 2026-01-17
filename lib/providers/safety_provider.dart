// lib/providers/safety_provider.dart
import 'package:flutter/material.dart';

import '../models/safety_model.dart';
import '../services/safety_service.dart';

class SafetyProvider extends ChangeNotifier {
  final SafetyService _safetyService = SafetyService();

  bool _isLoading = false;
  String? _error;
  GeoJSONFeatureCollection? _safetyGeoJSON;

  bool get isLoading => _isLoading;
  String? get error => _error;
  GeoJSONFeatureCollection? get safetyGeoJSON => _safetyGeoJSON;

  /// Fetch safety heatmap
  Future<void> fetchSafetyHeatmap(List<String> areaIds) async {
    if (areaIds.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _safetyService.getSafetyGeoJSON(areaIds);
    _isLoading = false;

    if (response.isSuccess) {
      _safetyGeoJSON = response.data;
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch safety data';
    }
    notifyListeners();
  }

  /// Fetch all safety cells (for visualization)
  Future<void> fetchAllSafetyData({int limit = 1000}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _safetyService.getAllSafetyGeoJSON(limit: limit);
    _isLoading = false;

    if (response.isSuccess) {
      _safetyGeoJSON = response.data;
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch safety data';
    }
    notifyListeners();
  }
}
