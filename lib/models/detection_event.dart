import 'dart:math' as math;

class DetectionLabel {
  static const String unverified = 'unverified';
  static const String pothole = 'confirmed_pothole';
  static const String speedBreaker = 'speed_breaker';
  static const String falseDetection = 'false_detection';

  static const List<String> all = [
    unverified,
    pothole,
    speedBreaker,
    falseDetection,
  ];
}

class DetectionEvent {
  final String id;
  final double latitude;
  final double longitude;
  final double speedKmph;
  final double accelMag;
  final double gyroMag;
  final double accelSpike;
  final double gyroPeak;
  final double verticalRatio;
  final DateTime timestamp;
  final String label;
  final int detectionCount;

  const DetectionEvent({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speedKmph,
    required this.accelMag,
    required this.gyroMag,
    required this.accelSpike,
    required this.gyroPeak,
    required this.verticalRatio,
    required this.timestamp,
    this.label = DetectionLabel.unverified,
    this.detectionCount = 1,
  });

  DetectionEvent copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? speedKmph,
    double? accelMag,
    double? gyroMag,
    double? accelSpike,
    double? gyroPeak,
    double? verticalRatio,
    DateTime? timestamp,
    String? label,
    int? detectionCount,
  }) {
    return DetectionEvent(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmph: speedKmph ?? this.speedKmph,
      accelMag: accelMag ?? this.accelMag,
      gyroMag: gyroMag ?? this.gyroMag,
      accelSpike: accelSpike ?? this.accelSpike,
      gyroPeak: gyroPeak ?? this.gyroPeak,
      verticalRatio: verticalRatio ?? this.verticalRatio,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      detectionCount: detectionCount ?? this.detectionCount,
    );
  }

  double get severityScore {
    final score =
        (accelSpike * 0.7) + (gyroPeak * 0.2) + (verticalRatio * 10 * 0.1);
    return score.clamp(0.0, 10.0);
  }

  double get confidence {
    final confidence = 0.45 +
        (severityScore / 10.0) * 0.35 +
        (math.min(detectionCount, 5) / 5.0) * 0.2;
    return confidence.clamp(0.5, 0.99);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmph': speedKmph,
      'accel_mag': accelMag,
      'gyro_mag': gyroMag,
      'accel_spike': accelSpike,
      'gyro_peak': gyroPeak,
      'vertical_ratio': verticalRatio,
      'timestamp': timestamp.toIso8601String(),
      'label': label,
      'detection_count': detectionCount,
    };
  }

  factory DetectionEvent.fromMap(Map<dynamic, dynamic> map) {
    return DetectionEvent(
      id: map['id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speedKmph: (map['speed_kmph'] as num).toDouble(),
      accelMag: (map['accel_mag'] as num).toDouble(),
      gyroMag: (map['gyro_mag'] as num).toDouble(),
      accelSpike: (map['accel_spike'] as num).toDouble(),
      gyroPeak: (map['gyro_peak'] as num).toDouble(),
      verticalRatio: (map['vertical_ratio'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      label: (map['label'] as String?) ?? DetectionLabel.unverified,
      detectionCount: (map['detection_count'] as int?) ?? 1,
    );
  }
}
