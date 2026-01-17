// lib/models/report_model.dart
class Report {
  final String id;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final int severity;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      latitude: json['location']?['lat'] ?? 0.0,
      longitude: json['location']?['lng'] ?? 0.0,
      severity: json['severity'] ?? 3,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }
}
