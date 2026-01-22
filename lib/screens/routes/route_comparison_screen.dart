// lib/screens/routes/route_comparison_screen.dart
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import '../../widgets/common/route_card.dart';
import '../navigation/navigation_screen.dart';

class RouteComparisonScreen extends StatefulWidget {
  final LatLng currentLocation;

  const RouteComparisonScreen({super.key, required this.currentLocation});

  @override
  State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
  LatLng? selectedDestination;
  GoogleMapController? mapController;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  // Map type
  MapType _mapType = MapType.normal;
  final List<MapType> _mapCycle = [
    MapType.normal,
    MapType.hybrid,
    MapType.satellite,
    MapType.terrain,
  ];

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<AutocompleteSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  Timer? _debounce;
  String? _sessionToken;

  @override
  void initState() {
    super.initState();
    _generateSessionToken();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  // ---------------- SESSION TOKEN ----------------
  void _generateSessionToken() {
    final rnd = Random();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    _sessionToken = base64Url.encode(bytes).replaceAll('=', '');
  }

  // ---------------- RESET ----------------
  void _resetDestinationAndRoutes() {
    setState(() {
      selectedDestination = null;
      markers.clear();
      polylines.clear();
    });
    context.read<RouteProvider>().clearRoutes();
  }

  // ---------------- MAP TAP ----------------
  void _onMapTap(LatLng location) {
    if (selectedDestination != null) {
      final d = _distanceMeters(selectedDestination!, location);
      if (d < 20) {
        _resetDestinationAndRoutes();
        return;
      }
    }

    setState(() {
      selectedDestination = location;
      _updateMarkers();
    });

    _compareRoutes();
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const r = 6371000;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return 2 * r * asin(sqrt(h));
  }

  void _updateMarkers() {
    markers = {
      if (selectedDestination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: selectedDestination!,
        ),
    };
  }

  // ---------------- ROUTES ----------------
  void _compareRoutes() {
    if (selectedDestination == null) return;
    context
        .read<RouteProvider>()
        .compareRoutes(widget.currentLocation, selectedDestination!);
  }

  void _buildPolylines(List<RouteData> routes) {
    polylines.clear();
    final selectedId = context.read<RouteProvider>().selectedRoute?.id;

    for (final route in routes) {
      final isSelected = route.id == selectedId;
      polylines.add(
        Polyline(
          polylineId: PolylineId(route.id),
          points: route.decodedPoints,
          color:
              _colorFromString(route.color).withAlpha(isSelected ? 220 : 120),
          width: isSelected ? 7 : 5,
          zIndex: isSelected ? 2 : 1,
          consumeTapEvents: true,
          onTap: () {
            context.read<RouteProvider>().selectRoute(route);
            _buildPolylines(routes);
          },
        ),
      );
    }
    setState(() {});
  }

  Color _colorFromString(String c) {
    switch (c.toLowerCase()) {
      case 'green':
        return AppColors.success;
      case 'yellow':
        return AppColors.warning;
      case 'orange':
        return Colors.orange;
      case 'red':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  // ---------------- SEARCH ----------------
  void _onSearchChanged(String q) {
    _debounce?.cancel();

    if (q.trim().isEmpty) {
      _resetDestinationAndRoutes();
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAutocomplete(q);
    });
  }

  Future<void> _fetchAutocomplete(String input) async {
    final apiKey = dotenv.env['ROUTES_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;

    final dio = Dio();
    final res = await dio.post(
      'https://places.googleapis.com/v1/places:autocomplete',
      data: {
        'input': input,
        'sessionToken': _sessionToken,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': widget.currentLocation.latitude,
              'longitude': widget.currentLocation.longitude,
            },
            'radius': 50000.0
          }
        }
      },
      options: Options(headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
      }),
    );

    setState(() {
      _suggestions = (res.data['suggestions'] as List? ?? [])
          .map((e) => AutocompleteSuggestion.fromJson(e))
          .where((s) => s.placeId.isNotEmpty)
          .toList();
      _isSearching = false;
    });
  }

  Future<void> _onSuggestionSelected(AutocompleteSuggestion s) async {
    setState(() {
      _searchController.text = s.mainText;
      _showSuggestions = false;
      _isSearching = true;
    });

    final apiKey = dotenv.env['ROUTES_API_KEY'] ?? '';
    final dio = Dio();

    final res = await dio.get(
      'https://places.googleapis.com/v1/places/${s.placeId}',
      options: Options(headers: {
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location',
      }),
    );

    final loc = res.data['location'];
    final lat = (loc['latitude'] as num).toDouble();
    final lng = (loc['longitude'] as num).toDouble();

    setState(() {
      selectedDestination = LatLng(lat, lng);
      _updateMarkers();
      _isSearching = false;
    });

    _generateSessionToken();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selectedDestination!, 15),
    );

    _compareRoutes();
  }

  // ---------------- MAP TYPE ----------------
  void _rotateMapType() {
    final i = _mapCycle.indexOf(_mapType);
    setState(() {
      _mapType = _mapCycle[(i + 1) % _mapCycle.length];
    });
  }

  Widget _mapTypePreview() {
    String asset;

    switch (_mapType) {
      case MapType.hybrid:
        asset = 'assets/map_types/hybrid.png';
        break;
      case MapType.satellite:
        asset = 'assets/map_types/satellite.png';
        break;
      case MapType.terrain:
        asset = 'assets/map_types/terrain.png';
        break;
      default:
        asset = 'assets/map_types/normal.png';
    }

    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // fallback if asset still fails
            return const Icon(Icons.layers, color: AppColors.primary);
          },
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Safe Route')),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => mapController = c,
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 14,
            ),
            mapType: _mapType,
            markers: markers,
            polylines: polylines,
            onTap: _onMapTap,
            // 🔥 REMOVE DEFAULT CONTROLS
            myLocationEnabled: true, // keeps blue dot
            myLocationButtonEnabled: false, // removes target button
            zoomControlsEnabled: false, // removes + / − buttons
            compassEnabled: false, // removes compass (optional)
            mapToolbarEnabled: false, // removes directions toolbar
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            trafficEnabled: true,
            buildingsEnabled: true,
            padding: const EdgeInsets.only(bottom: 300),
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search destination...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _resetDestinationAndRoutes,
                          )
                        : null,
                  ),
                ),
                if (_showSuggestions)
                  Container(
                    color: Colors.white,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (_, i) {
                              final s = _suggestions[i];
                              return ListTile(
                                title: Text(s.mainText),
                                subtitle: s.secondaryText.isNotEmpty
                                    ? Text(s.secondaryText)
                                    : null,
                                onTap: () => _onSuggestionSelected(s),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // Map type toggle
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _rotateMapType,
              child: Container(
                width: 50,
                height: 50, // ✅ same as search bar
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: _mapTypePreview(),
              ),
            ),
          ),

          // Routes drawer
          Consumer<RouteProvider>(
            builder: (_, rp, __) {
              if (rp.routes.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _buildPolylines(rp.routes),
                );
              }

              if (rp.routes.isEmpty) return const SizedBox();

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  color: Colors.white,
                  child: SizedBox(
                    height: 300,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: rp.routes.length,
                      itemBuilder: (_, i) {
                        final r = rp.routes[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: RouteCard(
                            route: r,
                            isSelected: rp.selectedRoute?.id == r.id,
                            onTap: () => rp.selectRoute(r),
                            onStart: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NavigationScreen(
                                    start: widget.currentLocation,
                                    route: r,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- MODEL ----------------
class AutocompleteSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final List<String> types;

  AutocompleteSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.types,
  });

  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) {
    final p = json['placePrediction'] ?? {};
    return AutocompleteSuggestion(
      placeId: p['placeId'] ?? '',
      mainText: p['structuredFormat']?['mainText']?['text'] ?? '',
      secondaryText: p['structuredFormat']?['secondaryText']?['text'] ?? '',
      types: (p['types'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
