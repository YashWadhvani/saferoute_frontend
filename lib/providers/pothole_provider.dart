// lib/providers/pothole_provider.dart
import 'package:flutter/material.dart';
import '../models/pothole_model.dart';
import '../services/pothole_service.dart';
import '../services/pothole_detection_service.dart';

class PotholeProvider with ChangeNotifier {
  final PotholeService _potholeService = PotholeService();
  final PotholeDetectionService _detectionService = PotholeDetectionService();
  String? _authToken;

  List<PotholeData> _potholes = [];
  bool _isLoading = false;
  String? _error;
  bool _isDetecting = false;
  int _detectedCount = 0;

  // Getters
  List<PotholeData> get potholes => _potholes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDetecting => _isDetecting;
  int get detectedCount => _detectedCount;

  /// Explicit auth token initialization hook
  /// (kept for compatibility with screens that initialize providers post-login)
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Start pothole detection
  Future<void> startDetection() async {
    try {
      _isDetecting = true;
      _error = null;
      notifyListeners();

      // Set up callback for when pothole is detected
      _detectionService.onPotholeDetected = (lat, lng, intensity) {
        _detectedCount++;
        notifyListeners();

        // Show notification or feedback to user
        debugPrint(
            '🕳️ Pothole detected at ($lat, $lng) with intensity $intensity');
      };

      await _detectionService.startDetection();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start detection: $e';
      _isDetecting = false;
      notifyListeners();
    }
  }

  /// Stop pothole detection
  void stopDetection() {
    _detectionService.stopDetection();
    _isDetecting = false;
    notifyListeners();
  }

  /// Fetch potholes in bounding box
  Future<void> fetchPotholes({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _potholeService.fetchPotholes(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
    _isLoading = false;

    if (response.isSuccess) {
      _potholes = response.data ?? [];
      _error = null;
    } else {
      _error = response.error ?? 'Failed to fetch potholes';
    }
    notifyListeners();
  }

  /// Get route score
  Future<Map<String, dynamic>?> getRouteScore({
    required List<Map<String, double>> routeCoordinates,
    required double routeDistance,
  }) async {
    final response = await _potholeService.getRouteScore(
      routeCoordinates: routeCoordinates,
      routeDistance: routeDistance,
    );

    if (response.isSuccess) {
      _error = null;
      return response.data;
    } else {
      _error = response.error ?? 'Failed to get route score';
      return null;
    }
  }

  /// Get statistics
  Future<Map<String, dynamic>?> getStatistics() async {
    final response = await _potholeService.getStatistics();

    if (response.isSuccess) {
      _error = null;
      return response.data;
    } else {
      _error = response.error ?? 'Failed to get statistics';
      return null;
    }
  }

  /// Manually report a pothole
  Future<bool> reportPothole({
    required double latitude,
    required double longitude,
    required double intensity,
  }) async {
    final response = await _potholeService.reportPothole(
      latitude: latitude,
      longitude: longitude,
      intensity: intensity,
    );

    if (response.isSuccess) {
      _error = null;
      _detectedCount++;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to report pothole';
      notifyListeners();
      return false;
    }
  }

  /// Reset detected count
  void resetDetectedCount() {
    _detectedCount = 0;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }
}
