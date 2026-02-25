import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'detection_event_store.dart';

class PotholeBackgroundService {
  PotholeBackgroundService._();

  static final PotholeBackgroundService instance = PotholeBackgroundService._();

  static const String _channelId = 'saferoute_detection_channel';
  static const int _notificationId = 4242;

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'SafeRoute Detection',
      description: 'Foreground service for pothole detection',
      importance: Importance.low,
    );

    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'SafeRoute',
        initialNotificationContent:
            'SafeRoute is monitoring road conditions...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  Future<void> startDetection() async {
    final running = await _service.isRunning();
    if (!running) {
      await _service.startService();
    }
    _service.invoke('start_detection');
  }

  Future<void> stopDetection() async {
    _service.invoke('stop_detection');
    _service.invoke('stop_service');
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await DetectionEventStore.ensureInitialized();

  StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
  StreamSubscription<Position>? positionSubscription;

  final accelerometerBuffer = <double>[];
  final gyroscopeBuffer = <double>[];
  const bufferSize = 20;

  Position? lastPosition;
  DateTime? lastDetectionTime;
  const detectionCooldown = Duration(seconds: 3);

  bool isDetecting = false;
  bool isCheckingPothole = false;

  const magnitudeThreshold = 16.0;
  const deltaThreshold = 8.0;
  const gyroUpperLimit = 5.0;
  const minSpeedKmh = 10.0;

  void emitSensorUpdate({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double accelMagnitude,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double gyroMagnitude,
    required double accelSpike,
    required double gyroPeak,
  }) {
    service.invoke('sensor_update', {
      'timestamp': DateTime.now().toIso8601String(),
      'is_detecting': isDetecting,
      'accel_x': accelX,
      'accel_y': accelY,
      'accel_z': accelZ,
      'accel_magnitude': accelMagnitude,
      'gyro_x': gyroX,
      'gyro_y': gyroY,
      'gyro_z': gyroZ,
      'gyro_magnitude': gyroMagnitude,
      'speed_mps': math.max(0.0, lastPosition?.speed ?? 0.0),
      'latitude': lastPosition?.latitude,
      'longitude': lastPosition?.longitude,
      'accel_spike': accelSpike,
      'gyro_peak': gyroPeak,
    });
  }

  double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double stdDev(List<double> values, double avg) {
    if (values.isEmpty) return 0;
    double sq = 0;
    for (final v in values) {
      sq += math.pow(v - avg, 2);
    }
    return math.sqrt(sq / values.length);
  }

  double calculateSeverity(double accelSpike, double gyroPeak, double spread) {
    double score = 0;
    score += (accelSpike / 5.0).clamp(0.0, 6.0);
    score += (gyroPeak / 2.0).clamp(0.0, 2.0);
    score += (spread / 3.0).clamp(0.0, 2.0);
    return score.clamp(0.0, 10.0);
  }

  Future<void> startStreams() async {
    if (isDetecting) return;

    isDetecting = true;
    accelerometerBuffer.clear();
    gyroscopeBuffer.clear();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    positionSubscription?.cancel();
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      lastPosition = position;
    });

    double lastAccelX = 0;
    double lastAccelY = 0;
    double lastAccelZ = 0;
    double lastAccelMagnitude = 0;

    double lastGyroX = 0;
    double lastGyroY = 0;
    double lastGyroZ = 0;
    double lastGyroMagnitude = 0;

    gyroscopeSubscription?.cancel();
    gyroscopeSubscription = gyroscopeEvents.listen((event) {
      lastGyroX = event.x;
      lastGyroY = event.y;
      lastGyroZ = event.z;
      lastGyroMagnitude =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      gyroscopeBuffer.add(lastGyroMagnitude);
      if (gyroscopeBuffer.length > bufferSize) {
        gyroscopeBuffer.removeAt(0);
      }

      emitSensorUpdate(
        accelX: lastAccelX,
        accelY: lastAccelY,
        accelZ: lastAccelZ,
        accelMagnitude: lastAccelMagnitude,
        gyroX: lastGyroX,
        gyroY: lastGyroY,
        gyroZ: lastGyroZ,
        gyroMagnitude: lastGyroMagnitude,
        accelSpike: 0,
        gyroPeak: lastGyroMagnitude,
      );
    });

    accelerometerSubscription?.cancel();
    accelerometerSubscription = accelerometerEvents.listen((event) async {
      lastAccelX = event.x;
      lastAccelY = event.y;
      lastAccelZ = event.z;
      lastAccelMagnitude =
          math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      accelerometerBuffer.add(lastAccelMagnitude);
      if (accelerometerBuffer.length > bufferSize) {
        accelerometerBuffer.removeAt(0);
      }

      if (accelerometerBuffer.length < 2 ||
          lastPosition == null ||
          isCheckingPothole) {
        emitSensorUpdate(
          accelX: lastAccelX,
          accelY: lastAccelY,
          accelZ: lastAccelZ,
          accelMagnitude: lastAccelMagnitude,
          gyroX: lastGyroX,
          gyroY: lastGyroY,
          gyroZ: lastGyroZ,
          gyroMagnitude: lastGyroMagnitude,
          accelSpike: 0,
          gyroPeak: gyroscopeBuffer.isNotEmpty ? gyroscopeBuffer.last : 0,
        );
        return;
      }

      isCheckingPothole = true;
      try {
        if (lastDetectionTime != null &&
            DateTime.now().difference(lastDetectionTime!) < detectionCooldown) {
          return;
        }

        final currentMag = accelerometerBuffer.last;
        final previousMag = accelerometerBuffer[accelerometerBuffer.length - 2];
        final delta = (currentMag - previousMag).abs();
        final gyroMag = gyroscopeBuffer.isNotEmpty ? gyroscopeBuffer.last : 0.0;
        final speedKmph = (math.max(0.0, lastPosition!.speed) * 3.6).toDouble();

        final detected = currentMag > magnitudeThreshold &&
            delta > deltaThreshold &&
            gyroMag < gyroUpperLimit &&
            speedKmph > minSpeedKmh;

        emitSensorUpdate(
          accelX: lastAccelX,
          accelY: lastAccelY,
          accelZ: lastAccelZ,
          accelMagnitude: lastAccelMagnitude,
          gyroX: lastGyroX,
          gyroY: lastGyroY,
          gyroZ: lastGyroZ,
          gyroMagnitude: lastGyroMagnitude,
          accelSpike: delta,
          gyroPeak: gyroMag,
        );

        if (!detected) {
          return;
        }

        lastDetectionTime = DateTime.now();

        final avg = mean(accelerometerBuffer);
        final spread = stdDev(accelerometerBuffer, avg);
        final severity = calculateSeverity(delta, gyroMag, spread);
        final verticalRatio = currentMag == 0
            ? 0.0
            : (event.z.abs() / currentMag).clamp(0.0, 1.0).toDouble();

        final merged = await DetectionEventStore.addOrMergeCandidate(
          latitude: lastPosition!.latitude,
          longitude: lastPosition!.longitude,
          speedKmph: speedKmph,
          accelMag: currentMag,
          gyroMag: gyroMag,
          accelSpike: delta,
          gyroPeak: gyroMag,
          verticalRatio: verticalRatio,
          timestamp: DateTime.now(),
        );

        service.invoke('candidate_detected', {
          'id': merged.id,
          'latitude': merged.latitude,
          'longitude': merged.longitude,
          'intensity': severity,
        });
      } catch (e) {
        debugPrint('Background detection error: $e');
      } finally {
        isCheckingPothole = false;
      }
    });

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'SafeRoute',
        content: 'SafeRoute is monitoring road conditions...',
      );
    }

    service.invoke('service_status', {
      'status': 'streams_started',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> stopStreams() async {
    isDetecting = false;

    await accelerometerSubscription?.cancel();
    await gyroscopeSubscription?.cancel();
    await positionSubscription?.cancel();

    accelerometerSubscription = null;
    gyroscopeSubscription = null;
    positionSubscription = null;

    accelerometerBuffer.clear();
    gyroscopeBuffer.clear();
  }

  service.on('start_detection').listen((_) {
    unawaited(startStreams());
  });

  service.on('stop_detection').listen((_) {
    unawaited(stopStreams());
  });

  service.on('stop_service').listen((_) async {
    await stopStreams();
    service.stopSelf();
  });

  // Important: start immediately when isolate boots.
  // This avoids a race where the first "start_detection" invoke can arrive
  // before listeners are registered, which leaves all sensor values at defaults.
  unawaited(startStreams());
}
