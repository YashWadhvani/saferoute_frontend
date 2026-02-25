// lib/services/pothole_detection_service.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:path_provider/path_provider.dart';

import 'pothole_background_service.dart';

class SensorDebugData {
  final DateTime timestamp;
  final bool isDetecting;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double accelMagnitude;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double gyroMagnitude;
  final double speedMps;
  final double? latitude;
  final double? longitude;
  final double accelSpike;
  final double gyroPeak;

  const SensorDebugData({
    required this.timestamp,
    required this.isDetecting,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.accelMagnitude,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.gyroMagnitude,
    required this.speedMps,
    required this.latitude,
    required this.longitude,
    required this.accelSpike,
    required this.gyroPeak,
  });

  factory SensorDebugData.empty() {
    return SensorDebugData(
      timestamp: DateTime.now(),
      isDetecting: false,
      accelX: 0,
      accelY: 0,
      accelZ: 0,
      accelMagnitude: 0,
      gyroX: 0,
      gyroY: 0,
      gyroZ: 0,
      gyroMagnitude: 0,
      speedMps: 0,
      latitude: null,
      longitude: null,
      accelSpike: 0,
      gyroPeak: 0,
    );
  }

  SensorDebugData copyWith({
    DateTime? timestamp,
    bool? isDetecting,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? accelMagnitude,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    double? gyroMagnitude,
    double? speedMps,
    double? latitude,
    double? longitude,
    double? accelSpike,
    double? gyroPeak,
  }) {
    return SensorDebugData(
      timestamp: timestamp ?? this.timestamp,
      isDetecting: isDetecting ?? this.isDetecting,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      accelMagnitude: accelMagnitude ?? this.accelMagnitude,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      gyroMagnitude: gyroMagnitude ?? this.gyroMagnitude,
      speedMps: speedMps ?? this.speedMps,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accelSpike: accelSpike ?? this.accelSpike,
      gyroPeak: gyroPeak ?? this.gyroPeak,
    );
  }
}

class PotholeDetectionService {
  // Singleton pattern
  static final PotholeDetectionService _instance =
      PotholeDetectionService._internal();
  factory PotholeDetectionService() => _instance;

  // Streams
  StreamSubscription<Map<String, dynamic>?>? _sensorUpdateSubscription;
  StreamSubscription<Map<String, dynamic>?>? _candidateDetectedSubscription;
  final StreamController<SensorDebugData> _sensorDataController =
      StreamController<SensorDebugData>.broadcast();

  // Detection state
  bool _isDetecting = false;
  SensorDebugData _latestSensorData = SensorDebugData.empty();
  Timer? _sensorLogTimer;
  File? _sensorLogFile;
  String? _sensorLogFilePath;
  Future<void> _logWriteQueue = Future<void>.value();

  // Callback for when pothole is detected
  Function(double latitude, double longitude, double intensity)?
      onPotholeDetected;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();

  Stream<SensorDebugData> get sensorDataStream => _sensorDataController.stream;
  SensorDebugData get latestSensorData => _latestSensorData;
  String? get sensorLogFilePath => _sensorLogFilePath;

  void _bindBackgroundEvents() {
    _sensorUpdateSubscription?.cancel();
    _candidateDetectedSubscription?.cancel();

    _sensorUpdateSubscription = _backgroundService
        .on('sensor_update')
        .listen((Map<String, dynamic>? payload) {
      if (payload == null) return;

      _emitSensorData(
        _latestSensorData.copyWith(
          timestamp:
              DateTime.tryParse((payload['timestamp'] ?? '').toString()) ??
                  DateTime.now(),
          isDetecting: payload['is_detecting'] == true,
          accelX: (payload['accel_x'] as num?)?.toDouble() ?? 0,
          accelY: (payload['accel_y'] as num?)?.toDouble() ?? 0,
          accelZ: (payload['accel_z'] as num?)?.toDouble() ?? 0,
          accelMagnitude: (payload['accel_magnitude'] as num?)?.toDouble() ?? 0,
          gyroX: (payload['gyro_x'] as num?)?.toDouble() ?? 0,
          gyroY: (payload['gyro_y'] as num?)?.toDouble() ?? 0,
          gyroZ: (payload['gyro_z'] as num?)?.toDouble() ?? 0,
          gyroMagnitude: (payload['gyro_magnitude'] as num?)?.toDouble() ?? 0,
          speedMps: (payload['speed_mps'] as num?)?.toDouble() ?? 0,
          latitude: (payload['latitude'] as num?)?.toDouble(),
          longitude: (payload['longitude'] as num?)?.toDouble(),
          accelSpike: (payload['accel_spike'] as num?)?.toDouble() ?? 0,
          gyroPeak: (payload['gyro_peak'] as num?)?.toDouble() ?? 0,
        ),
      );
    });

    _candidateDetectedSubscription = _backgroundService
        .on('candidate_detected')
        .listen((Map<String, dynamic>? payload) {
      if (payload == null) return;
      final latitude = (payload['latitude'] as num?)?.toDouble();
      final longitude = (payload['longitude'] as num?)?.toDouble();
      final intensity = (payload['intensity'] as num?)?.toDouble() ?? 0;

      if (latitude == null || longitude == null) return;
      onPotholeDetected?.call(latitude, longitude, intensity);
    });
  }

  PotholeDetectionService._internal() {
    _bindBackgroundEvents();
  }

  /// Start pothole detection
  Future<void> startDetection() async {
    if (_isDetecting) return;

    debugPrint('🔍 Starting pothole detection...');

    final hasLocation = await _ensureLocationPermission();
    if (!hasLocation) {
      throw Exception('Location permission not granted');
    }

    await PotholeBackgroundService.instance.startDetection();

    await _initializeSensorLogFile();
    _startSensorLoggingTimer();

    _isDetecting = true;
    _emitSensorData(
      _latestSensorData.copyWith(
        timestamp: DateTime.now(),
        isDetecting: true,
      ),
    );

    debugPrint('✅ Pothole detection started');
  }

  /// Stop pothole detection
  void stopDetection() {
    if (!_isDetecting) return;

    debugPrint('🛑 Stopping pothole detection...');

    unawaited(PotholeBackgroundService.instance.stopDetection());

    _isDetecting = false;

    _stopSensorLogging();

    _emitSensorData(
      _latestSensorData.copyWith(
        timestamp: DateTime.now(),
        isDetecting: false,
        accelSpike: 0,
        gyroPeak: 0,
      ),
    );

    debugPrint('✅ Pothole detection stopped');
  }

  /// Get detection status
  bool get isDetecting => _isDetecting;

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _emitSensorData(SensorDebugData data) {
    _latestSensorData = data;
    if (!_sensorDataController.isClosed) {
      _sensorDataController.add(data);
    }
  }

  Future<void> _initializeSensorLogFile() async {
    try {
      Directory? baseDirectory;

      if (Platform.isAndroid) {
        baseDirectory = await getExternalStorageDirectory();
      }

      baseDirectory ??= await getApplicationDocumentsDirectory();

      final logsDirectory = Directory(
          '${baseDirectory.path}${Platform.pathSeparator}sensor_logs');

      if (!await logsDirectory.exists()) {
        await logsDirectory.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName = 'pothole_sensors_${_formatDateForFile(now)}.txt';
      final filePath =
          '${logsDirectory.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);

      final header = StringBuffer()
        ..writeln('# SafeRoute Sensor Log')
        ..writeln('# SessionStart: ${now.toIso8601String()}')
        ..writeln(
            '# Fields: timestamp, accel_x, accel_y, accel_z, accel_mag, gyro_x, gyro_y, gyro_z, gyro_mag, speed_mps, speed_kmph, latitude, longitude, accel_spike, gyro_peak, is_detecting')
        ..writeln();

      await file.writeAsString(header.toString(), mode: FileMode.write);

      _sensorLogFile = file;
      _sensorLogFilePath = file.path;

      debugPrint('📝 Sensor logging started: ${file.path}');
    } catch (e) {
      _sensorLogFile = null;
      _sensorLogFilePath = null;
      debugPrint('❌ Failed to initialize sensor logging: $e');
    }
  }

  void _startSensorLoggingTimer() {
    _sensorLogTimer?.cancel();
    _sensorLogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isDetecting) return;
      final file = _sensorLogFile;
      if (file == null) return;

      final snapshot = _latestSensorData;
      final speedKmph = snapshot.speedMps * 3.6;
      final row =
          '${DateTime.now().toIso8601String()},${snapshot.accelX.toStringAsFixed(6)},${snapshot.accelY.toStringAsFixed(6)},${snapshot.accelZ.toStringAsFixed(6)},${snapshot.accelMagnitude.toStringAsFixed(6)},${snapshot.gyroX.toStringAsFixed(6)},${snapshot.gyroY.toStringAsFixed(6)},${snapshot.gyroZ.toStringAsFixed(6)},${snapshot.gyroMagnitude.toStringAsFixed(6)},${snapshot.speedMps.toStringAsFixed(6)},${speedKmph.toStringAsFixed(6)},${snapshot.latitude?.toStringAsFixed(7) ?? 'null'},${snapshot.longitude?.toStringAsFixed(7) ?? 'null'},${snapshot.accelSpike.toStringAsFixed(6)},${snapshot.gyroPeak.toStringAsFixed(6)},${snapshot.isDetecting}\n';

      _logWriteQueue = _logWriteQueue.then((_) async {
        await file.writeAsString(row, mode: FileMode.append, flush: false);
      }).catchError((error) {
        debugPrint('❌ Failed to append sensor log row: $error');
      });
    });
  }

  void _stopSensorLogging() {
    _sensorLogTimer?.cancel();
    _sensorLogTimer = null;

    final file = _sensorLogFile;
    if (file != null) {
      final endLine = '# SessionEnd: ${DateTime.now().toIso8601String()}\n';
      _logWriteQueue = _logWriteQueue.then((_) async {
        await file.writeAsString(endLine, mode: FileMode.append, flush: true);
      }).catchError((error) {
        debugPrint('❌ Failed to finalize sensor log: $error');
      });
    }

    _sensorLogFile = null;
  }

  String _formatDateForFile(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }

  /// Dispose resources
  void dispose() {
    _sensorUpdateSubscription?.cancel();
    _candidateDetectedSubscription?.cancel();
    stopDetection();
  }
}
