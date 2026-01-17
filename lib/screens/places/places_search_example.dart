// lib/screens/places/places_search_example.dart
import 'package:flutter/material.dart';
import '../../services/google_places_service.dart';
import '../../core/theme/app_text_styles.dart';

class PlacesSearchExample extends StatefulWidget {
  const PlacesSearchExample({super.key});

  @override
  State<PlacesSearchExample> createState() => _PlacesSearchExampleState();
}

class _PlacesSearchExampleState extends State<PlacesSearchExample> {
  final _searchController = TextEditingController();
  final _placesService = GooglePlacesService();
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await _placesService.autocomplete(query);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    if (prediction.placeId == null) return;

    try {
      final details = await _placesService.getPlaceDetails(prediction.placeId!);

      if (details != null) {
        // Safe null checking for nested maps
        final geometry = details['geometry'] as Map<String, dynamic>?;
        if (geometry != null) {
          final location = geometry['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat = location['lat'] as double?;
            final lng = location['lng'] as double?;

            if (lat != null && lng != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Selected: ${prediction.description}\nLat: $lat, Lng: $lng'),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Places'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search location',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchPlaces,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    prediction.description ?? 'Unknown location',
                    style: AppTextStyles.bodyMedium,
                  ),
                  onTap: () => _selectPlace(prediction),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
