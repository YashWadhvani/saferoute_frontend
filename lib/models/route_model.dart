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
  final double safetyScoreExcludingPotholes;
  final double safetyScoreIncludingPotholes;
  final int potholeCount;
  final double potholeIntensity;
  final double potholePenalty;
  final double scoreDropPercent;
  final double? saferThanFastestPercent;
  final double? saferThanShortestPercent;
  final String color; // e.g. "green", "red"
  final List<String> tags; // e.g. ["safest", "fastest"]

  RouteData({
    required this.id,
    required this.polyline,
    required this.decodedPoints,
    required this.distance,
    required this.duration,
    required this.safetyScore,
    required this.safetyScoreExcludingPotholes,
    required this.safetyScoreIncludingPotholes,
    required this.potholeCount,
    required this.potholeIntensity,
    required this.potholePenalty,
    required this.scoreDropPercent,
    this.saferThanFastestPercent,
    this.saferThanShortestPercent,
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

    final distanceValue = json['distance']?['value']?.toString() ?? '';
    final durationValue = json['duration']?['value']?.toString() ?? '';
    final fallbackId = polyline.isNotEmpty
        ? 'route_${polyline.hashCode}_$distanceValue\_$durationValue'
        : DateTime.now().microsecondsSinceEpoch.toString();

    return RouteData(
      id: (json['id']?.toString().isNotEmpty ?? false)
          ? json['id'].toString()
          : fallbackId,
      polyline: polyline,
      decodedPoints: decodedPoints,
      distance: json['distance']?['text'] ?? 'Unknown',
      duration: json['duration']?['text'] ?? 'Unknown',
      safetyScore: _parseDouble(json['safety_score']),
      safetyScoreExcludingPotholes: _parseDouble(
          json['safety_score_excluding_potholes'] ??
              json['comparative_analysis']?['score_excluding_potholes']),
      safetyScoreIncludingPotholes: _parseDouble(
          json['safety_score_including_potholes'] ??
              json['comparative_analysis']?['score_including_potholes'] ??
              json['safety_score']),
      potholeCount: _parseInt(json['pothole_count']),
      potholeIntensity: _parseDouble(json['pothole_intensity'] ??
          json['comparative_analysis']?['pothole_intensity']),
      potholePenalty: _parseDouble(json['pothole_penalty'] ??
          json['comparative_analysis']?['pothole_penalty']),
      scoreDropPercent:
          _parseDouble(json['comparative_analysis']?['score_drop_percent']),
      saferThanFastestPercent: _parseNullableDouble(
          json['additional_comparisons']?['safer_than_fastest_percent']),
      saferThanShortestPercent: _parseNullableDouble(
          json['additional_comparisons']?['safer_than_shortest_percent']),
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

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return _parseDouble(value);
  }
}
