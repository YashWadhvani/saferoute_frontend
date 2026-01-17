// lib/screens/routes/route_comparison_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/route_model.dart';
import '../../providers/route_provider.dart';
import '../../widgets/common/route_card.dart';
import '../../widgets/common/empty_state.dart';
import '../navigation/navigation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() {
    markers = {
      Marker(
        markerId: const MarkerId('origin'),
        position: widget.currentLocation,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
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
      polylines.add(
        Polyline(
          polylineId: PolylineId(route.id),
          points: route.decodedPoints,
          color: _colorFromHex(route.color).withAlpha((0.7 * 255).round()),
          width: 5,
        ),
      );
    }
  }

  Color _colorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
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

          // Map Type Toggle button
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'map_type',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      // Cycle through map types similar to Google Maps
                      _mapType = _mapType == MapType.normal
                          ? MapType.hybrid
                          : _mapType == MapType.hybrid
                              ? MapType.satellite
                              : _mapType == MapType.satellite
                                  ? MapType.terrain
                                  : _mapType == MapType.terrain
                                      ? MapType.none
                                      : MapType.normal;
                    });
                  },
                  child: const Icon(Icons.map),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _mapType.toString().split('.').last,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          if (selectedDestination == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Tap on the map to select destination',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Routes Bottom Sheet
          Consumer<RouteProvider>(
            builder: (context, routeProvider, _) {
              if (!routeProvider.isLoading && routeProvider.routes.isEmpty) {
                return const SizedBox.shrink();
              }

              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: routeProvider.isLoading
                      ? 120
                      : (routeProvider.routes.isEmpty ? 0 : 300),
                  child: Material(
                    elevation: 12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: routeProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : routeProvider.error != null
                            ? Center(
                                child: Text(routeProvider.error!),
                              )
                            : ListView.builder(
                                itemCount: routeProvider.routes.length,
                                itemBuilder: (context, index) {
                                  final route = routeProvider.routes[index];
                                  return RouteCard(
                                    route: route,
                                    isSelected:
                                        routeProvider.selectedRoute?.id ==
                                            route.id,
                                    onTap: () {
                                      routeProvider.selectRoute(route);
                                      _buildPolylines([route]);
                                      setState(() {});
                                    },
                                    onStart: () {
                                      // Start navigation: open navigation screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => NavigationScreen(
                                            start: widget.currentLocation,
                                            route: route,
                                          ),
                                        ),
                                      );
                                    },
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

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
