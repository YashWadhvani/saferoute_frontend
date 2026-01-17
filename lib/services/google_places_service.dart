// lib/services/google_places_service.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AutocompletePrediction {
  final String? placeId;
  final String? description;

  AutocompletePrediction({this.placeId, this.description});

  factory AutocompletePrediction.fromJson(Map<String, dynamic> json) {
    return AutocompletePrediction(
      placeId: json['place_id'] as String?,
      description: json['description'] as String?,
    );
  }
}

class GooglePlacesService {
  final String _apiKey;

  GooglePlacesService() : _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Autocomplete predictions for input text using Google Places Autocomplete API
  Future<List<AutocompletePrediction>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];

    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        debugPrint(
            'GooglePlacesService.autocomplete: no GOOGLE_MAPS_API_KEY provided');
        return [];
      }

      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey&types=geocode');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List?;

        if (predictions == null) {
          debugPrint(
              'GooglePlacesService.autocomplete: received null predictions');
          return [];
        }

        final result = predictions
            .map((p) =>
                AutocompletePrediction.fromJson(p as Map<String, dynamic>))
            .toList();

        debugPrint(
            'GooglePlacesService.autocomplete: input="$input" -> ${result.length} predictions');
        return result;
      } else {
        debugPrint(
            'GooglePlacesService.autocomplete error: ${response.statusCode}');
        return [];
      }
    } catch (e, st) {
      debugPrint('GooglePlacesService.autocomplete error: $e\n$st');
      return [];
    }
  }

  /// Get place details (especially lat/lng) from a placeId using Google Places Details API
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final apiKey = _apiKey;
      if (apiKey.isEmpty) {
        debugPrint(
            'GooglePlacesService.getPlaceDetails: no GOOGLE_MAPS_API_KEY provided');
        return null;
      }

      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address,name');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'] as Map<String, dynamic>?;

        if (result != null) {
          return {
            'geometry': {
              'location': {
                'lat': result['geometry']?['location']?['lat'],
                'lng': result['geometry']?['location']?['lng'],
              }
            },
            'formatted_address': result['formatted_address'],
            'name': result['name'],
          };
        }
      }
      return null;
    } catch (e, st) {
      debugPrint('GooglePlacesService.getPlaceDetails error: $e\n$st');
      return null;
    }
  }
}
