import 'dart:math' as math;

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/detection_event.dart';

class DetectionEventStore {
  DetectionEventStore._();

  static const String boxName = 'candidate_detection_events';
  static const Uuid _uuid = Uuid();
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Map>(boxName);
    }
    _initialized = true;
  }

  static Box<Map> _box() {
    return Hive.box<Map>(boxName);
  }

  static List<DetectionEvent> getAllEvents() {
    final events = _box()
        .values
        .map((entry) => DetectionEvent.fromMap(entry))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  static DetectionEvent? getEventById(String id) {
    final map = _box().get(id);
    if (map == null) return null;
    return DetectionEvent.fromMap(map);
  }

  static Future<DetectionEvent> addOrMergeCandidate({
    required double latitude,
    required double longitude,
    required double speedKmph,
    required double accelMag,
    required double gyroMag,
    required double accelSpike,
    required double gyroPeak,
    required double verticalRatio,
    required DateTime timestamp,
  }) async {
    final currentEvents = getAllEvents();
    DetectionEvent? nearby;

    for (final event in currentEvents) {
      final dist = _distanceMeters(
        latitude,
        longitude,
        event.latitude,
        event.longitude,
      );
      if (dist <= 5.0) {
        nearby = event;
        break;
      }
    }

    if (nearby != null) {
      final mergedCount = nearby.detectionCount + 1;
      final mergedEvent = nearby.copyWith(
        latitude: ((nearby.latitude * nearby.detectionCount) + latitude) /
            mergedCount,
        longitude: ((nearby.longitude * nearby.detectionCount) + longitude) /
            mergedCount,
        speedKmph: (nearby.speedKmph + speedKmph) / 2,
        accelMag: math.max(nearby.accelMag, accelMag),
        gyroMag: math.max(nearby.gyroMag, gyroMag),
        accelSpike: math.max(nearby.accelSpike, accelSpike),
        gyroPeak: math.max(nearby.gyroPeak, gyroPeak),
        verticalRatio: math.max(nearby.verticalRatio, verticalRatio),
        timestamp: timestamp,
        detectionCount: mergedCount,
      );

      await _box().put(mergedEvent.id, mergedEvent.toMap());
      return mergedEvent;
    }

    final event = DetectionEvent(
      id: _uuid.v4(),
      latitude: latitude,
      longitude: longitude,
      speedKmph: speedKmph,
      accelMag: accelMag,
      gyroMag: gyroMag,
      accelSpike: accelSpike,
      gyroPeak: gyroPeak,
      verticalRatio: verticalRatio,
      timestamp: timestamp,
      label: DetectionLabel.unverified,
    );

    await _box().put(event.id, event.toMap());
    return event;
  }

  static Future<void> updateLabel(String id, String label) async {
    if (!DetectionLabel.all.contains(label)) {
      throw ArgumentError('Invalid label: $label');
    }

    final map = _box().get(id);
    if (map == null) return;

    final current = DetectionEvent.fromMap(map);
    final updated = current.copyWith(label: label, timestamp: DateTime.now());
    await _box().put(id, updated.toMap());
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
}
