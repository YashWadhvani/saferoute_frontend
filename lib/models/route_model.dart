// lib/models/route_model.dart
// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    as GooglePolylineAlgorithm;

class RouteData {
  final String id;
  final String polyline;
  final List<LatLng> decodedPoints;
  final String distance; // e.g. "5.4 km"
  final String duration; // e.g. "12 mins"
  final double safetyScore;
  final String color; // e.g. "green", "red"
  final List<String> tags; // e.g. ["safest", "fastest"]

  RouteData({
    required this.id,
    required this.polyline,
    required this.decodedPoints,
    required this.distance,
    required this.duration,
    required this.safetyScore,
    required this.color,
    required this.tags,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    final polyline = json['polyline'] as String? ?? '';
    final decodedPoints = <LatLng>[];

    if (polyline.isNotEmpty) {
      try {
        final points = GooglePolylineAlgorithm.decodePolyline(polyline);
        decodedPoints.addAll(
          points.map((p) => LatLng(p[0].toDouble(), p[1].toDouble())),
        );
      } catch (e) {
        debugPrint('Failed to decode polyline: $e');
      }
    }

    return RouteData(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      polyline: polyline,
      decodedPoints: decodedPoints,
      distance: json['distance']?['text'] ?? 'Unknown',
      duration: json['duration']?['text'] ?? 'Unknown',
      safetyScore: _parseDouble(json['safety_score']),
      color: json['color'] ?? 'blue',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
