// lib/models/user_model.dart
class User {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final List<EmergencyContact> emergencyContacts;

  User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.emergencyContacts = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((c) => EmergencyContact.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
