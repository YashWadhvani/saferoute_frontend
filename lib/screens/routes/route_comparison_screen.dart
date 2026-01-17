// lib/screens/routes/route_comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import '../../widgets/common/route_card.dart';
import '../navigation/active_navigation_screen.dart';
import '../../services/google_places_service.dart';

class RouteComparisonScreen extends StatefulWidget {
  final LatLng currentLocation;

  const RouteComparisonScreen({required this.currentLocation, super.key});

  @override
  State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
  LatLng? selectedDestination;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  MapType _mapType = MapType.normal;
  final TextEditingController _searchController = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  bool _isSearching = false;
  final GooglePlacesService _placesService = GooglePlacesService();
  bool _isPanelMinimized = false;
  double _panelHeight = 300;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    markers = {
      if (selectedDestination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: selectedDestination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
    };
  }

  void _onMapTap(LatLng location) {
    setState(() {
      selectedDestination = location;
      _updateMarkers();
    });

    if (selectedDestination != null) {
      _compareRoutes();
    }
  }

  void _compareRoutes() {
    final routeProvider = context.read<RouteProvider>();
    routeProvider.compareRoutes(
      widget.currentLocation,
      selectedDestination!,
    );
  }

  void _buildPolylines(List<RouteData> routes) {
    polylines.clear();
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final isSelected =
          context.read<RouteProvider>().selectedRoute?.id == route.id;
      polylines.add(
        Polyline(
          polylineId: PolylineId(route.id),
          points: route.decodedPoints,
          color: _colorFromString(route.color).withAlpha(
              isSelected ? (0.9 * 255).round() : (0.5 * 255).round()),
          width: isSelected ? 8 : 5,
        ),
      );
    }
  }

  Color _colorFromString(String colorStr) {
    // Handle named colors first
    final colorLower = colorStr.toLowerCase().trim();
    switch (colorLower) {
      case 'green':
        return AppColors.success;
      case 'yellow':
        return AppColors.warning;
      case 'orange':
        return Colors.orange;
      case 'red':
        return AppColors.danger;
      case 'blue':
        return AppColors.primary;
      case 'gray':
      case 'grey':
        return Colors.grey;
      default:
        break;
    }

    // Handle hex colors
    String cleanHex = colorStr.replaceFirst('#', '').trim();
    if (cleanHex.length == 6) {
      try {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } catch (e) {
        return AppColors.primary;
      }
    } else if (cleanHex.length == 8) {
      try {
        return Color(int.parse(cleanHex, radix: 16));
      } catch (e) {
        return AppColors.primary;
      }
    }

    return AppColors.primary;
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final predictions = await _placesService.autocomplete(query);
      setState(() {
        _predictions = predictions;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectPrediction(AutocompletePrediction prediction) async {
    _searchController.text = prediction.description ?? '';
    setState(() {
      _predictions = [];
    });

    if (prediction.placeId == null) return;

    try {
      final details = await _placesService.getPlaceDetails(prediction.placeId!);
      if (details != null) {
        final geometry = details['geometry'] as Map<String, dynamic>?;
        if (geometry != null) {
          final location = geometry['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat = location['lat'] as double?;
            final lng = location['lng'] as double?;
            if (lat != null && lng != null) {
              final latLng = LatLng(lat, lng);
              setState(() {
                selectedDestination = latLng;
                _updateMarkers();
              });
              mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(latLng, 15),
              );
              _compareRoutes();
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

  String _getMapTypeLabel() {
    switch (_mapType) {
      case MapType.normal:
        return 'Normal';
      case MapType.hybrid:
        return 'Hybrid';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      default:
        return 'Normal';
    }
  }

  IconData _getMapTypeIcon() {
    switch (_mapType) {
      case MapType.normal:
        return Icons.map;
      case MapType.hybrid:
        return Icons.map_outlined;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      default:
        return Icons.map;
    }
  }

  void _cycleMapType() {
    setState(() {
      _mapType = _mapType == MapType.normal
          ? MapType.hybrid
          : _mapType == MapType.hybrid
              ? MapType.satellite
              : _mapType == MapType.satellite
                  ? MapType.terrain
                  : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Safe Route'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 14,
            ),
            mapType: _mapType,
            markers: markers,
            polylines: polylines,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 100,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search destination',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _predictions = [];
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _searchPlace,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) return;

                      setState(() {
                        _predictions = [];
                      });

                      try {
                        final locations = await locationFromAddress(value);
                        if (locations.isNotEmpty) {
                          final location = locations.first;
                          final latLng =
                              LatLng(location.latitude, location.longitude);
                          setState(() {
                            selectedDestination = latLng;
                            _updateMarkers();
                          });
                          mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(latLng, 15),
                          );
                          _compareRoutes();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Location not found')),
                          );
                        }
                      }
                    },
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            prediction.description ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectPrediction(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map Type Toggle with Preview Icon
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _cycleMapType,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.15 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getMapTypeIcon(),
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    _getMapTypeLabel(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          if (selectedDestination == null && _predictions.isEmpty)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha((0.3 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Search or tap on the map to select destination',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Routes Bottom Drawer
          Consumer<RouteProvider>(
            builder: (context, routeProvider, _) {
              if (!routeProvider.isLoading && routeProvider.routes.isEmpty) {
                return const SizedBox.shrink();
              }

              if (routeProvider.routes.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _buildPolylines(routeProvider.routes);
                  if (mounted) setState(() {});
                });
              }

              final height = _isPanelMinimized ? 80.0 : _panelHeight;

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (!_isPanelMinimized) {
                      setState(() {
                        _panelHeight = (_panelHeight - details.delta.dy)
                            .clamp(200.0, 500.0);
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: height,
                    child: Material(
                      elevation: 12,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isPanelMinimized = !_isPanelMinimized;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${routeProvider.routes.length} Routes Available',
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        Icon(
                                          _isPanelMinimized
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: AppColors.onSurface,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!_isPanelMinimized) const Divider(height: 1),
                          if (!_isPanelMinimized)
                            Expanded(
                              child: routeProvider.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : routeProvider.error != null
                                      ? Center(
                                          child: Text(routeProvider.error!))
                                      : ListView.builder(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          itemCount:
                                              routeProvider.routes.length,
                                          itemBuilder: (context, index) {
                                            final route =
                                                routeProvider.routes[index];
                                            return RouteCard(
                                              route: route,
                                              isSelected: routeProvider
                                                      .selectedRoute?.id ==
                                                  route.id,
                                              onTap: () {
                                                routeProvider
                                                    .selectRoute(route);
                                                _buildPolylines(
                                                    routeProvider.routes);
                                                setState(() {});
                                              },
                                              onStart: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ActiveNavigationScreen(
                                                      start: widget
                                                          .currentLocation,
                                                      route: route,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                            ),
                        ],
                      ),
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
