// lib/models/pothole_model.dart
class PotholeData {
  final String id;
  final double latitude;
  final double longitude;
  final double intensity;
  final int reports;
  final DateTime createdAt;

  PotholeData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.reports,
    required this.createdAt,
  });

  factory PotholeData.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final coordinates = (location?['coordinates'] as List?) ?? const [0.0, 0.0];

    return PotholeData(
      id: json['_id'] ?? '',
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
      intensity: (json['intensity'] as num).toDouble(),
      reports: (json['reports'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
