// lib/models/sos_model.dart
class SOSAlert {
  final String id;
  final double latitude;
  final double longitude;
  final String status; // 'triggered', 'sent', 'resolved'
  final List<String> contactsNotified;
  final DateTime createdAt;

  SOSAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.contactsNotified,
    required this.createdAt,
  });

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['_id'] ?? '',
      latitude: json['location']?['lat'] ?? 0.0,
      longitude: json['location']?['lng'] ?? 0.0,
      status: json['status'] ?? 'triggered',
      contactsNotified: List<String>.from(json['contactsNotified'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
    );
  }
}
