// lib/models/safety_model.dart
class GeoJSONFeatureCollection {
  final List<GeoJSONFeature> features;

  GeoJSONFeatureCollection({required this.features});

  factory GeoJSONFeatureCollection.fromJson(Map<String, dynamic> json) {
    final features = (json['features'] as List?)
            ?.map((f) => GeoJSONFeature.fromJson(f))
            .toList() ??
        [];
    return GeoJSONFeatureCollection(features: features);
  }
}

class GeoJSONFeature {
  final String areaId;
  final double safetyScore;
  final Map<String, dynamic> factors;

  GeoJSONFeature({
    required this.areaId,
    required this.safetyScore,
    required this.factors,
  });

  factory GeoJSONFeature.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] ?? {};
    return GeoJSONFeature(
      areaId: props['areaId'] ?? '',
      safetyScore: _parseDouble(props['score']),
      factors: props['factors'] ?? {},
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
