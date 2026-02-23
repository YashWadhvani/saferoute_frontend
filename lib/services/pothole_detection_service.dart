// lib/services/pothole_detection_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api/api_client.dart';

class PotholeDetectionService {
  // Singleton pattern
  static final PotholeDetectionService _instance =
      PotholeDetectionService._internal();
  factory PotholeDetectionService() => _instance;
  PotholeDetectionService._internal();

  // Streams
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Detection state
  bool _isDetecting = false;
  Position? _lastPosition;

  // Sensor data buffers
  final List<double> _accelerometerBuffer = [];
  final List<double> _gyroscopeBuffer = [];
  static const int _bufferSize = 20; // 20 readings (approx 0.5 seconds at 40Hz)

  // Thresholds for pothole detection
  static const double _accelerometerThreshold =
      15.0; // m/s² (sudden vertical jolt)
  static const double _gyroscopeThreshold = 2.5; // rad/s (sudden rotation)
  static const double _minimumSpeed =
      2.0; // m/s (minimum speed to detect, ~7 km/h)

  // Cooldown to prevent duplicate reports
  DateTime? _lastDetectionTime;
  static const Duration _detectionCooldown = Duration(seconds: 3);

  // Callback for when pothole is detected
  Function(double latitude, double longitude, double intensity)?
      onPotholeDetected;

  final Dio _dio = ApiClient.dio;

  /// Start pothole detection
  Future<void> startDetection() async {
    if (_isDetecting) return;

    debugPrint('🔍 Starting pothole detection...');
    _isDetecting = true;

    // Start listening to accelerometer
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _processAccelerometerData(event);
    });

    // Start listening to gyroscope
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _processGyroscopeData(event);
    });

    debugPrint('✅ Pothole detection started');
  }

  /// Stop pothole detection
  void stopDetection() {
    if (!_isDetecting) return;

    debugPrint('🛑 Stopping pothole detection...');
    _isDetecting = false;

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();

    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();

    debugPrint('✅ Pothole detection stopped');
  }

  /// Process accelerometer data
  void _processAccelerometerData(AccelerometerEvent event) {
    // Calculate magnitude of acceleration (total force)
    final magnitude =
        math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Add to buffer
    _accelerometerBuffer.add(magnitude);
    if (_accelerometerBuffer.length > _bufferSize) {
      _accelerometerBuffer.removeAt(0);
    }

    // Check if buffer is full enough for detection
    if (_accelerometerBuffer.length >= 10) {
      _checkForPothole();
    }
  }

  /// Process gyroscope data
  void _processGyroscopeData(GyroscopeEvent event) {
    // Calculate magnitude of rotation
    final magnitude =
        math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Add to buffer
    _gyroscopeBuffer.add(magnitude);
    if (_gyroscopeBuffer.length > _bufferSize) {
      _gyroscopeBuffer.removeAt(0);
    }
  }

  /// Check if current sensor data indicates a pothole
  void _checkForPothole() async {
    // Cooldown check
    if (_lastDetectionTime != null) {
      final timeSinceLastDetection =
          DateTime.now().difference(_lastDetectionTime!);
      if (timeSinceLastDetection < _detectionCooldown) {
        return; // Too soon since last detection
      }
    }

    // Get current speed
    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final speed = _lastPosition?.speed ?? 0;

      // Only detect if moving fast enough
      if (speed < _minimumSpeed) {
        return;
      }
    } catch (e) {
      debugPrint('Error getting position: $e');
      return;
    }

    // Calculate statistics from buffers
    final accelMean = _calculateMean(_accelerometerBuffer);
    final accelStdDev = _calculateStdDev(_accelerometerBuffer, accelMean);
    final accelMax = _accelerometerBuffer.reduce(math.max);

    // Check for sudden spike in acceleration (pothole impact)
    final accelSpike = accelMax - accelMean;

    // Get gyroscope data if available
    double gyroMax = 0;
    if (_gyroscopeBuffer.isNotEmpty) {
      gyroMax = _gyroscopeBuffer.reduce(math.max);
    }

    // Detection logic: sudden spike in acceleration AND/OR high gyroscope reading
    final isAccelSpike = accelSpike > _accelerometerThreshold;
    final isGyroSpike = gyroMax > _gyroscopeThreshold;

    if (isAccelSpike || (isAccelSpike && isGyroSpike)) {
      // Calculate intensity (0-10 scale)
      double intensity = _calculateIntensity(accelSpike, gyroMax, accelStdDev);

      debugPrint(
          '🕳️ POTHOLE DETECTED! Intensity: ${intensity.toStringAsFixed(1)}');
      debugPrint(
          '   Accel spike: ${accelSpike.toStringAsFixed(2)}, Gyro: ${gyroMax.toStringAsFixed(2)}');

      // Mark detection time
      _lastDetectionTime = DateTime.now();

      // Report pothole
      if (_lastPosition != null) {
        _reportPothole(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          intensity,
        );

        // Trigger callback
        onPotholeDetected?.call(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          intensity,
        );
      }
    }
  }

  /// Calculate mean of a list
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate standard deviation
  double _calculateStdDev(List<double> values, double mean) {
    if (values.isEmpty) return 0;

    double sumSquaredDiff = 0;
    for (var value in values) {
      sumSquaredDiff += math.pow(value - mean, 2);
    }

    return math.sqrt(sumSquaredDiff / values.length);
  }

  /// Calculate pothole intensity on 0-10 scale
  double _calculateIntensity(double accelSpike, double gyroMax, double stdDev) {
    // Combine factors with weights
    double intensity = 0;

    // Acceleration spike contributes most (0-6 points)
    intensity += (accelSpike / 5.0).clamp(0.0, 6.0);

    // Gyroscope contributes (0-2 points)
    intensity += (gyroMax / 2.0).clamp(0.0, 2.0);

    // Standard deviation adds variability factor (0-2 points)
    intensity += (stdDev / 3.0).clamp(0.0, 2.0);

    return intensity.clamp(0.0, 10.0);
  }

  /// Report pothole to backend
  Future<void> _reportPothole(
      double latitude, double longitude, double intensity) async {
    try {
      final response = await _dio.post(
        '/potholes',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'intensity': intensity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>?;
        final isNew = data?['isNew'] ?? true;
        debugPrint('✅ Pothole reported: ${isNew ? "NEW" : "UPDATED"}');
      } else {
        debugPrint('❌ Failed to report pothole: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('❌ Error reporting pothole: ${e.message}');
    }
  }

  /// Get detection status
  bool get isDetecting => _isDetecting;

  /// Dispose resources
  void dispose() {
    stopDetection();
  }
}
