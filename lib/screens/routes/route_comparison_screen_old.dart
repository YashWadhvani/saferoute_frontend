// // // lib/screens/routes/route_comparison_screen.dart
// // // ignore_for_file: unused_import

// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import '../../core/theme/app_colors.dart';
// // import '../../core/theme/app_text_styles.dart';
// // import '../../models/route_model.dart';
// // import '../../providers/route_provider.dart';
// // import '../../widgets/common/route_card.dart';
// // import '../../widgets/common/empty_state.dart';
// // import '../navigation/navigation_screen.dart';

// // class RouteComparisonScreen extends StatefulWidget {
// //   final LatLng currentLocation;

// //   const RouteComparisonScreen({required this.currentLocation, super.key});

// //   @override
// //   State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
// // }

// // class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
// //   LatLng? selectedDestination;
// //   GoogleMapController? mapController;
// //   Set<Marker> markers = {};
// //   Set<Polyline> polylines = {};
// //   MapType _mapType = MapType.normal;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _updateMarkers();
// //   }

// //   void _updateMarkers() {
// //     markers = {
// //       Marker(
// //         markerId: const MarkerId('origin'),
// //         position: widget.currentLocation,
// //         infoWindow: const InfoWindow(title: 'Your Location'),
// //       ),
// //       if (selectedDestination != null)
// //         Marker(
// //           markerId: const MarkerId('destination'),
// //           position: selectedDestination!,
// //           infoWindow: const InfoWindow(title: 'Destination'),
// //           icon: BitmapDescriptor.defaultMarkerWithHue(
// //             BitmapDescriptor.hueRed,
// //           ),
// //         ),
// //     };
// //   }

// //   void _onMapTap(LatLng location) {
// //     setState(() {
// //       selectedDestination = location;
// //       _updateMarkers();
// //     });

// //     if (selectedDestination != null) {
// //       _compareRoutes();
// //     }
// //   }

// //   void _compareRoutes() {
// //     final routeProvider = context.read<RouteProvider>();
// //     routeProvider.compareRoutes(
// //       widget.currentLocation,
// //       selectedDestination!,
// //     );
// //   }

// //   void _buildPolylines(List<RouteData> routes) {
// //     polylines.clear();
// //     for (int i = 0; i < routes.length; i++) {
// //       final route = routes[i];
// //       polylines.add(
// //         Polyline(
// //           polylineId: PolylineId(route.id),
// //           points: route.decodedPoints,
// //           color: _colorFromHex(route.color).withAlpha((0.7 * 255).round()),
// //           width: 5,
// //         ),
// //       );
// //     }
// //   }

// //   Color _colorFromHex(String hex) {
// //     hex = hex.replaceFirst('#', '');
// //     return Color(int.parse('FF$hex', radix: 16));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Find Safe Route'),
// //         centerTitle: true,
// //       ),
// //       body: Stack(
// //         children: [
// //           // Google Map
// //           GoogleMap(
// //             onMapCreated: (controller) => mapController = controller,
// //             initialCameraPosition: CameraPosition(
// //               target: widget.currentLocation,
// //               zoom: 14,
// //             ),
// //             mapType: _mapType,
// //             markers: markers,
// //             polylines: polylines,
// //             onTap: _onMapTap,
// //             myLocationEnabled: true,
// //             myLocationButtonEnabled: true,
// //           ),

// //           // Map Type Toggle button
// //           Positioned(
// //             top: 16,
// //             right: 16,
// //             child: Column(
// //               children: [
// //                 FloatingActionButton(
// //                   heroTag: 'map_type',
// //                   mini: true,
// //                   onPressed: () {
// //                     setState(() {
// //                       // Cycle through map types similar to Google Maps
// //                       _mapType = _mapType == MapType.normal
// //                           ? MapType.hybrid
// //                           : _mapType == MapType.hybrid
// //                               ? MapType.satellite
// //                               : _mapType == MapType.satellite
// //                                   ? MapType.terrain
// //                                   : _mapType == MapType.terrain
// //                                       ? MapType.none
// //                                       : MapType.normal;
// //                     });
// //                   },
// //                   child: const Icon(Icons.map),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Container(
// //                   padding:
// //                       const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
// //                   decoration: BoxDecoration(
// //                       color: Colors.white,
// //                       borderRadius: BorderRadius.circular(8)),
// //                   child: Text(
// //                     _mapType.toString().split('.').last,
// //                     style: const TextStyle(fontSize: 11),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),

// //           // Instructions
// //           if (selectedDestination == null)
// //             Positioned(
// //               top: 20,
// //               left: 20,
// //               right: 20,
// //               child: Container(
// //                 padding: const EdgeInsets.all(16),
// //                 decoration: BoxDecoration(
// //                   color: AppColors.primary,
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Text(
// //                   'Tap on the map to select destination',
// //                   style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
// //                   textAlign: TextAlign.center,
// //                 ),
// //               ),
// //             ),

// //           // Routes Bottom Sheet
// //           Consumer<RouteProvider>(
// //             builder: (context, routeProvider, _) {
// //               if (!routeProvider.isLoading && routeProvider.routes.isEmpty) {
// //                 return const SizedBox.shrink();
// //               }

// //               return Positioned(
// //                 bottom: 0,
// //                 left: 0,
// //                 right: 0,
// //                 child: AnimatedContainer(
// //                   duration: const Duration(milliseconds: 300),
// //                   height: routeProvider.isLoading
// //                       ? 120
// //                       : (routeProvider.routes.isEmpty ? 0 : 300),
// //                   child: Material(
// //                     elevation: 12,
// //                     borderRadius: const BorderRadius.vertical(
// //                       top: Radius.circular(20),
// //                     ),
// //                     child: routeProvider.isLoading
// //                         ? const Center(
// //                             child: CircularProgressIndicator(),
// //                           )
// //                         : routeProvider.error != null
// //                             ? Center(
// //                                 child: Text(routeProvider.error!),
// //                               )
// //                             : ListView.builder(
// //                                 itemCount: routeProvider.routes.length,
// //                                 itemBuilder: (context, index) {
// //                                   final route = routeProvider.routes[index];
// //                                   return RouteCard(
// //                                     route: route,
// //                                     isSelected:
// //                                         routeProvider.selectedRoute?.id ==
// //                                             route.id,
// //                                     onTap: () {
// //                                       routeProvider.selectRoute(route);
// //                                       _buildPolylines([route]);
// //                                       setState(() {});
// //                                     },
// //                                     onStart: () {
// //                                       // Start navigation: open navigation screen
// //                                       Navigator.push(
// //                                         context,
// //                                         MaterialPageRoute(
// //                                           builder: (_) => NavigationScreen(
// //                                             start: widget.currentLocation,
// //                                             route: route,
// //                                           ),
// //                                         ),
// //                                       );
// //                                     },
// //                                   );
// //                                 },
// //                               ),
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     mapController?.dispose();
// //     super.dispose();
// //   }
// // }

// // lib/screens/routes/enhanced_route_comparison_screen.dart
// // COMPLETE implementation with ALL missing features from old frontend

// // import 'dart:async';
// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:geocoding/geocoding.dart' as geocoding;
// // import 'package:google_place/google_place.dart';
// // import '../../core/theme/app_colors.dart';
// // import '../../core/theme/app_text_styles.dart';
// // import '../../models/route_model.dart';
// // import '../../providers/route_provider.dart';
// // import '../../services/places_service.dart';
// // import '../navigation/active_navigation_screen.dart';

// // class RouteComparisonScreen extends StatefulWidget {
// //   final LatLng currentLocation;

// //   const RouteComparisonScreen({
// //     required this.currentLocation,
// //     super.key,
// //   });

// //   @override
// //   State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
// // }

// // class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
// //   GoogleMapController? mapController;
// //   final PlacesService _placesService = PlacesService();

// //   // Controllers
// //   final TextEditingController _sourceController = TextEditingController();
// //   final TextEditingController _destController = TextEditingController();

// //   // State
// //   MapType _mapType = MapType.normal;
// //   bool _trafficEnabled = false;
// //   Set<Marker> _markers = {};
// //   Set<Polyline> _polylines = {};

// //   // Autocomplete
// //   Timer? _debounceTimer;
// //   List<AutocompletePrediction> _sourceSuggestions = [];
// //   List<AutocompletePrediction> _destSuggestions = [];
// //   bool _loadingSourceSuggestions = false;
// //   bool _loadingDestSuggestions = false;
// //   bool _showSourceSuggestions = false;
// //   bool _showDestSuggestions = false;

// //   // Locations
// //   LatLng? _sourceLocation;
// //   LatLng? _destinationLocation;

// //   // UI State
// //   bool _routePanelExpanded = false;
// //   bool _gettingCurrentLocation = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _sourceLocation = widget.currentLocation;
// //     _updateSourceFromLocation();
// //     _updateMarkers();
// //   }

// //   @override
// //   void dispose() {
// //     _debounceTimer?.cancel();
// //     _sourceController.dispose();
// //     _destController.dispose();
// //     mapController?.dispose();
// //     super.dispose();
// //   }

// //   // ============================================================
// //   // AUTOCOMPLETE IMPLEMENTATION
// //   // ============================================================

// //   void _onSourceChanged(String value) {
// //     if (value.trim().isEmpty) {
// //       setState(() {
// //         _sourceSuggestions = [];
// //         _loadingSourceSuggestions = false;
// //         _showSourceSuggestions = false;
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _loadingSourceSuggestions = true;
// //       _showSourceSuggestions = true;
// //     });

// //     _debounceTimer?.cancel();
// //     _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
// //       try {
// //         final predictions = await _placesService.autocomplete(value);
// //         if (!mounted) return;
// //         setState(() {
// //           _sourceSuggestions = predictions;
// //           _loadingSourceSuggestions = false;
// //         });
// //       } catch (e) {
// //         if (!mounted) return;
// //         setState(() {
// //           _sourceSuggestions = [];
// //           _loadingSourceSuggestions = false;
// //         });
// //       }
// //     });
// //   }

// //   void _onDestChanged(String value) {
// //     if (value.trim().isEmpty) {
// //       setState(() {
// //         _destSuggestions = [];
// //         _loadingDestSuggestions = false;
// //         _showDestSuggestions = false;
// //       });
// //       return;
// //     }

// //     setState(() {
// //       _loadingDestSuggestions = true;
// //       _showDestSuggestions = true;
// //     });

// //     _debounceTimer?.cancel();
// //     _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
// //       try {
// //         final predictions = await _placesService.autocomplete(value);
// //         if (!mounted) return;
// //         setState(() {
// //           _destSuggestions = predictions;
// //           _loadingDestSuggestions = false;
// //         });
// //       } catch (e) {
// //         if (!mounted) return;
// //         setState(() {
// //           _destSuggestions = [];
// //           _loadingDestSuggestions = false;
// //         });
// //       }
// //     });
// //   }

// //   Future<void> _selectSourcePrediction(
// //       AutocompletePrediction prediction) async {
// //     _sourceController.text = prediction.description ?? '';
// //     setState(() => _showSourceSuggestions = false);

// //     if (prediction.placeId != null) {
// //       final details = await _placesService.getPlaceDetails(prediction.placeId!);
// //       final lat = details?.geometry?.location?.lat;
// //       final lng = details?.geometry?.location?.lng;
// //       if (lat != null && lng != null) {
// //         setState(() => _sourceLocation = LatLng(lat, lng));
// //         _updateMarkers();
// //         mapController?.animateCamera(
// //           CameraUpdate.newLatLng(LatLng(lat, lng)),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> _selectDestPrediction(AutocompletePrediction prediction) async {
// //     _destController.text = prediction.description ?? '';
// //     setState(() => _showDestSuggestions = false);

// //     if (prediction.placeId != null) {
// //       final details = await _placesService.getPlaceDetails(prediction.placeId!);
// //       final lat = details?.geometry?.location?.lat;
// //       final lng = details?.geometry?.location?.lng;
// //       if (lat != null && lng != null) {
// //         setState(() => _destinationLocation = LatLng(lat, lng));
// //         _updateMarkers();
// //         mapController?.animateCamera(
// //           CameraUpdate.newLatLng(LatLng(lat, lng)),
// //         );
// //         _compareRoutes();
// //       }
// //     }
// //   }

// //   Future<void> _useCurrentLocation() async {
// //     setState(() => _gettingCurrentLocation = true);
// //     try {
// //       final position = await Geolocator.getCurrentPosition(
// //         locationSettings: const LocationSettings(
// //           accuracy: LocationAccuracy.high,
// //         ),
// //       );

// //       final placemarks = await geocoding.placemarkFromCoordinates(
// //         position.latitude,
// //         position.longitude,
// //       );

// //       String address = 'Current Location';
// //       if (placemarks.isNotEmpty) {
// //         final pm = placemarks.first;
// //         address =
// //             '${pm.name ?? ''} ${pm.street ?? ''}, ${pm.locality ?? ''}'.trim();
// //       }

// //       setState(() {
// //         _sourceLocation = LatLng(position.latitude, position.longitude);
// //         _sourceController.text = address;
// //         _gettingCurrentLocation = false;
// //       });

// //       _updateMarkers();
// //       mapController?.animateCamera(
// //         CameraUpdate.newLatLng(_sourceLocation!),
// //       );
// //     } catch (e) {
// //       setState(() => _gettingCurrentLocation = false);
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Failed to get current location')),
// //         );
// //       }
// //     }
// //   }

// //   void _updateSourceFromLocation() async {
// //     if (_sourceLocation == null) return;
// //     try {
// //       final placemarks = await geocoding.placemarkFromCoordinates(
// //         _sourceLocation!.latitude,
// //         _sourceLocation!.longitude,
// //       );
// //       if (placemarks.isNotEmpty && mounted) {
// //         final pm = placemarks.first;
// //         _sourceController.text =
// //             '${pm.name ?? ''} ${pm.street ?? ''}, ${pm.locality ?? ''}'.trim();
// //       }
// //     } catch (e) {
// //       _sourceController.text = 'Current Location';
// //     }
// //   }

// //   // ============================================================
// //   // MAP & MARKERS
// //   // ============================================================

// //   void _updateMarkers() {
// //     final newMarkers = <Marker>{};

// //     // Destination marker only (Google Maps SDK shows user location blue dot)
// //     if (_destinationLocation != null) {
// //       newMarkers.add(
// //         Marker(
// //           markerId: const MarkerId('destination'),
// //           position: _destinationLocation!,
// //           icon: BitmapDescriptor.defaultMarkerWithHue(
// //             BitmapDescriptor.hueRed,
// //           ),
// //           infoWindow: InfoWindow(
// //             title: 'Destination',
// //             snippet: _destController.text,
// //           ),
// //         ),
// //       );
// //     }

// //     setState(() => _markers = newMarkers);
// //   }

// //   // ============================================================
// //   // POLYLINE RENDERING WITH HIGHLIGHTING
// //   // ============================================================

// //   void _buildPolylines(List<RouteData> routes, String? selectedId) {
// //     final newPolylines = <Polyline>{};

// //     for (int i = 0; i < routes.length; i++) {
// //       final route = routes[i];
// //       final isSelected = route.id == selectedId;

// //       // Parse color
// //       Color baseColor = _parseColor(route.color);

// //       // Shadow for selected route
// //       if (isSelected) {
// //         newPolylines.add(
// //           Polyline(
// //             polylineId: PolylineId('${route.id}_shadow'),
// //             points: route.decodedPoints,
// //             color: Colors.black.withOpacity(0.2),
// //             width: 14,
// //             zIndex: 2,
// //           ),
// //         );
// //       }

// //       // Main polyline
// //       newPolylines.add(
// //         Polyline(
// //           polylineId: PolylineId(route.id),
// //           points: route.decodedPoints,
// //           color: baseColor.withOpacity(isSelected ? 0.95 : 0.5),
// //           width: isSelected ? 10 : 5,
// //           consumeTapEvents: true,
// //           onTap: () => _selectRoute(route),
// //           zIndex: isSelected ? 3 : 1,
// //         ),
// //       );
// //     }

// //     setState(() => _polylines = newPolylines);
// //   }

// //   Color _parseColor(String colorStr) {
// //     try {
// //       if (colorStr.startsWith('#')) {
// //         final hex = colorStr.substring(1);
// //         return Color(int.parse('FF$hex', radix: 16));
// //       }

// //       // Named colors
// //       switch (colorStr.toLowerCase()) {
// //         case 'green':
// //           return Colors.green;
// //         case 'yellow':
// //           return Colors.yellow;
// //         case 'orange':
// //           return Colors.orange;
// //         case 'red':
// //           return Colors.red;
// //         case 'blue':
// //           return Colors.blue;
// //         default:
// //           return Colors.blueGrey;
// //       }
// //     } catch (e) {
// //       return Colors.blueGrey;
// //     }
// //   }

// //   // ============================================================
// //   // ROUTE COMPARISON
// //   // ============================================================

// //   void _compareRoutes() async {
// //     if (_sourceLocation == null || _destinationLocation == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(
// //             content: Text('Please select both source and destination')),
// //       );
// //       return;
// //     }

// //     final routeProvider = context.read<RouteProvider>();
// //     await routeProvider.compareRoutes(_sourceLocation!, _destinationLocation!);

// //     if (!mounted) return;

// //     if (routeProvider.routes.isNotEmpty) {
// //       setState(() => _routePanelExpanded = true);
// //       _buildPolylines(
// //         routeProvider.routes,
// //         routeProvider.selectedRoute?.id,
// //       );

// //       // Fit map to show all routes
// //       if (routeProvider.selectedRoute != null) {
// //         _fitMapToRoute(routeProvider.selectedRoute!);
// //       }
// //     }
// //   }

// //   void _selectRoute(RouteData route) {
// //     final routeProvider = context.read<RouteProvider>();
// //     routeProvider.selectRoute(route);
// //     _buildPolylines(routeProvider.routes, route.id);
// //     _fitMapToRoute(route);
// //   }

// //   void _fitMapToRoute(RouteData route) {
// //     if (route.decodedPoints.isEmpty) return;

// //     final bounds = _calculateBounds(route.decodedPoints);
// //     mapController?.animateCamera(
// //       CameraUpdate.newLatLngBounds(bounds, 80),
// //     );
// //   }

// //   LatLngBounds _calculateBounds(List<LatLng> points) {
// //     double south = points.first.latitude;
// //     double north = points.first.latitude;
// //     double west = points.first.longitude;
// //     double east = points.first.longitude;

// //     for (final point in points) {
// //       south = south < point.latitude ? south : point.latitude;
// //       north = north > point.latitude ? north : point.latitude;
// //       west = west < point.longitude ? west : point.longitude;
// //       east = east > point.longitude ? east : point.longitude;
// //     }

// //     return LatLngBounds(
// //       southwest: LatLng(south, west),
// //       northeast: LatLng(north, east),
// //     );
// //   }

// //   // ============================================================
// //   // UI BUILD
// //   // ============================================================

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           // Map
// //           GoogleMap(
// //             onMapCreated: (controller) => mapController = controller,
// //             initialCameraPosition: CameraPosition(
// //               target: widget.currentLocation,
// //               zoom: 14,
// //             ),
// //             mapType: _mapType,
// //             trafficEnabled: _trafficEnabled,
// //             markers: _markers,
// //             polylines: _polylines,
// //             myLocationEnabled: true,
// //             myLocationButtonEnabled: true,
// //           ),

// //           // Map Type Toggle
// //           _buildMapTypeToggle(),

// //           // Search Controls
// //           _buildSearchControls(),

// //           // Route Panel
// //           _buildRoutePanel(),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildMapTypeToggle() {
// //     return Positioned(
// //       top: MediaQuery.of(context).padding.top + 16,
// //       right: 16,
// //       child: Material(
// //         elevation: 4,
// //         borderRadius: BorderRadius.circular(12),
// //         child: PopupMenuButton<String>(
// //           icon: const Icon(Icons.layers),
// //           tooltip: 'Map Type',
// //           onSelected: (value) {
// //             if (value == 'traffic') {
// //               setState(() => _trafficEnabled = !_trafficEnabled);
// //             } else {
// //               setState(() {
// //                 switch (value) {
// //                   case 'normal':
// //                     _mapType = MapType.normal;
// //                     break;
// //                   case 'hybrid':
// //                     _mapType = MapType.hybrid;
// //                     break;
// //                   case 'satellite':
// //                     _mapType = MapType.satellite;
// //                     break;
// //                   case 'terrain':
// //                     _mapType = MapType.terrain;
// //                     break;
// //                 }
// //               });
// //             }
// //           },
// //           itemBuilder: (context) => [
// //             _buildMapTypeItem('normal', 'Normal', Icons.map),
// //             _buildMapTypeItem('hybrid', 'Hybrid', Icons.satellite_alt),
// //             _buildMapTypeItem('satellite', 'Satellite', Icons.satellite),
// //             _buildMapTypeItem('terrain', 'Terrain', Icons.terrain),
// //             const PopupMenuDivider(),
// //             PopupMenuItem(
// //               value: 'traffic',
// //               child: Row(
// //                 children: [
// //                   if (_trafficEnabled)
// //                     const Icon(Icons.check, size: 18, color: Colors.green)
// //                   else
// //                     const SizedBox(width: 18),
// //                   const SizedBox(width: 8),
// //                   const Icon(Icons.traffic, size: 18),
// //                   const SizedBox(width: 8),
// //                   Text(_trafficEnabled ? 'Hide Traffic' : 'Show Traffic'),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   PopupMenuItem<String> _buildMapTypeItem(
// //     String value,
// //     String label,
// //     IconData icon,
// //   ) {
// //     final isActive = _mapType.toString().split('.').last == value;
// //     return PopupMenuItem(
// //       value: value,
// //       child: Row(
// //         children: [
// //           if (isActive)
// //             const Icon(Icons.check, size: 18, color: Colors.green)
// //           else
// //             const SizedBox(width: 18),
// //           const SizedBox(width: 8),
// //           Icon(icon, size: 18),
// //           const SizedBox(width: 8),
// //           Text(label),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildSearchControls() {
// //     return Positioned(
// //       top: MediaQuery.of(context).padding.top + 80,
// //       left: 16,
// //       right: 80,
// //       child: Material(
// //         elevation: 8,
// //         borderRadius: BorderRadius.circular(16),
// //         child: Container(
// //           padding: const EdgeInsets.all(16),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(16),
// //           ),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               // Source Input
// //               TextField(
// //                 controller: _sourceController,
// //                 decoration: InputDecoration(
// //                   labelText: 'From',
// //                   hintText: 'Enter source location',
// //                   prefixIcon:
// //                       const Icon(Icons.my_location, color: AppColors.primary),
// //                   suffixIcon: _gettingCurrentLocation
// //                       ? const SizedBox(
// //                           width: 24,
// //                           height: 24,
// //                           child: Padding(
// //                             padding: EdgeInsets.all(12.0),
// //                             child: CircularProgressIndicator(strokeWidth: 2),
// //                           ),
// //                         )
// //                       : IconButton(
// //                           icon: const Icon(Icons.gps_fixed),
// //                           onPressed: _useCurrentLocation,
// //                           tooltip: 'Use current location',
// //                         ),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   contentPadding: const EdgeInsets.symmetric(
// //                     horizontal: 16,
// //                     vertical: 12,
// //                   ),
// //                 ),
// //                 onChanged: _onSourceChanged,
// //                 onTap: () => setState(() => _showSourceSuggestions = true),
// //               ),

// //               // Source Suggestions
// //               if (_showSourceSuggestions) _buildSourceSuggestions(),

// //               const SizedBox(height: 12),

// //               // Destination Input
// //               TextField(
// //                 controller: _destController,
// //                 decoration: InputDecoration(
// //                   labelText: 'To',
// //                   hintText: 'Enter destination',
// //                   prefixIcon: const Icon(Icons.location_on, color: Colors.red),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   contentPadding: const EdgeInsets.symmetric(
// //                     horizontal: 16,
// //                     vertical: 12,
// //                   ),
// //                 ),
// //                 onChanged: _onDestChanged,
// //                 onTap: () => setState(() => _showDestSuggestions = true),
// //               ),

// //               // Destination Suggestions
// //               if (_showDestSuggestions) _buildDestSuggestions(),

// //               const SizedBox(height: 16),

// //               // Compare Button
// //               SizedBox(
// //                 width: double.infinity,
// //                 child: ElevatedButton.icon(
// //                   onPressed: _compareRoutes,
// //                   icon: const Icon(Icons.compare_arrows),
// //                   label: const Text('Compare Routes'),
// //                   style: ElevatedButton.styleFrom(
// //                     padding: const EdgeInsets.symmetric(vertical: 16),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSourceSuggestions() {
// //     if (_loadingSourceSuggestions) {
// //       return const Padding(
// //         padding: EdgeInsets.symmetric(vertical: 8.0),
// //         child: Center(child: CircularProgressIndicator()),
// //       );
// //     }

// //     if (_sourceSuggestions.isEmpty) return const SizedBox.shrink();

// //     return Container(
// //       margin: const EdgeInsets.only(top: 8),
// //       constraints: const BoxConstraints(maxHeight: 200),
// //       decoration: BoxDecoration(
// //         border: Border.all(color: AppColors.outline),
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       child: ListView.builder(
// //         shrinkWrap: true,
// //         itemCount: _sourceSuggestions.length,
// //         itemBuilder: (context, index) {
// //           final prediction = _sourceSuggestions[index];
// //           return ListTile(
// //             leading: const Icon(Icons.location_on, size: 20),
// //             title: Text(
// //               prediction.structuredFormatting?.mainText ?? '',
// //               style: AppTextStyles.bodyMedium,
// //             ),
// //             subtitle: Text(
// //               prediction.structuredFormatting?.secondaryText ?? '',
// //               style: AppTextStyles.bodySmall,
// //             ),
// //             onTap: () => _selectSourcePrediction(prediction),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildDestSuggestions() {
// //     if (_loadingDestSuggestions) {
// //       return const Padding(
// //         padding: EdgeInsets.symmetric(vertical: 8.0),
// //         child: Center(child: CircularProgressIndicator()),
// //       );
// //     }

// //     if (_destSuggestions.isEmpty) return const SizedBox.shrink();

// //     return Container(
// //       margin: const EdgeInsets.only(top: 8),
// //       constraints: const BoxConstraints(maxHeight: 200),
// //       decoration: BoxDecoration(
// //         border: Border.all(color: AppColors.outline),
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       child: ListView.builder(
// //         shrinkWrap: true,
// //         itemCount: _destSuggestions.length,
// //         itemBuilder: (context, index) {
// //           final prediction = _destSuggestions[index];
// //           return ListTile(
// //             leading: const Icon(Icons.location_on, size: 20, color: Colors.red),
// //             title: Text(
// //               prediction.structuredFormatting?.mainText ?? '',
// //               style: AppTextStyles.bodyMedium,
// //             ),
// //             subtitle: Text(
// //               prediction.structuredFormatting?.secondaryText ?? '',
// //               style: AppTextStyles.bodySmall,
// //             ),
// //             onTap: () => _selectDestPrediction(prediction),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildRoutePanel() {
// //     return Consumer<RouteProvider>(
// //       builder: (context, routeProvider, _) {
// //         if (!_routePanelExpanded || routeProvider.routes.isEmpty) {
// //           return const SizedBox.shrink();
// //         }

// //         return Positioned(
// //           bottom: 0,
// //           left: 0,
// //           right: 0,
// //           child: AnimatedContainer(
// //             duration: const Duration(milliseconds: 300),
// //             height: 300,
// //             child: Material(
// //               elevation: 12,
// //               borderRadius: const BorderRadius.vertical(
// //                 top: Radius.circular(20),
// //               ),
// //               child: Column(
// //                 children: [
// //                   // Drag Handle
// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(vertical: 12),
// //                     child: Container(
// //                       width: 40,
// //                       height: 4,
// //                       decoration: BoxDecoration(
// //                         color: Colors.grey[300],
// //                         borderRadius: BorderRadius.circular(2),
// //                       ),
// //                     ),
// //                   ),

// //                   // Header
// //                   Padding(
// //                     padding: const EdgeInsets.symmetric(horizontal: 16),
// //                     child: Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text(
// //                           'Available Routes',
// //                           style: AppTextStyles.titleLarge,
// //                         ),
// //                         IconButton(
// //                           icon: const Icon(Icons.close),
// //                           onPressed: () {
// //                             setState(() => _routePanelExpanded = false);
// //                           },
// //                         ),
// //                       ],
// //                     ),
// //                   ),

// //                   // Routes List
// //                   Expanded(
// //                     child: ListView.builder(
// //                       itemCount: routeProvider.routes.length,
// //                       itemBuilder: (context, index) {
// //                         final route = routeProvider.routes[index];
// //                         final isSelected =
// //                             routeProvider.selectedRoute?.id == route.id;

// //                         return _buildRouteCard(route, isSelected);
// //                       },
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildRouteCard(RouteData route, bool isSelected) {
// //     final safetyColor = route.safetyScore >= 7.5
// //         ? AppColors.success
// //         : route.safetyScore >= 5
// //             ? AppColors.warning
// //             : AppColors.danger;

// //     return Container(
// //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
// //         border: Border.all(
// //           color: isSelected ? AppColors.primary : AppColors.outline,
// //           width: isSelected ? 2 : 1,
// //         ),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: ListTile(
// //         onTap: () => _selectRoute(route),
// //         contentPadding: const EdgeInsets.all(12),
// //         leading: Container(
// //           width: 12,
// //           height: 12,
// //           decoration: BoxDecoration(
// //             color: _parseColor(route.color),
// //             shape: BoxShape.circle,
// //           ),
// //         ),
// //         title: Row(
// //           children: [
// //             Text(
// //               'Route ${route.id.hashCode % 10}',
// //               style: AppTextStyles.titleSmall,
// //             ),
// //             const SizedBox(width: 8),
// //             ...route.tags.map((tag) => Padding(
// //                   padding: const EdgeInsets.only(right: 4),
// //                   child: Chip(
// //                     label: Text(tag, style: const TextStyle(fontSize: 10)),
// //                     padding: EdgeInsets.zero,
// //                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                   ),
// //                 )),
// //           ],
// //         ),
// //         subtitle: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             const SizedBox(height: 4),
// //             Row(
// //               children: [
// //                 const Icon(Icons.location_on, size: 14),
// //                 const SizedBox(width: 4),
// //                 Text(route.distance, style: AppTextStyles.bodySmall),
// //                 const SizedBox(width: 12),
// //                 const Icon(Icons.schedule, size: 14),
// //                 const SizedBox(width: 4),
// //                 Text(route.duration, style: AppTextStyles.bodySmall),
// //               ],
// //             ),
// //           ],
// //         ),
// //         trailing: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
// //               decoration: BoxDecoration(
// //                 color: safetyColor.withOpacity(0.1),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Text(
// //                 route.safetyScore.toStringAsFixed(1),
// //                 style: TextStyle(
// //                   fontWeight: FontWeight.bold,
// //                   color: safetyColor,
// //                 ),
// //               ),
// //             ),
// //             const SizedBox(height: 4),
// //             IconButton(
// //               icon: const Icon(Icons.navigation),
// //               onPressed: () {
// //                 if (_sourceLocation != null) {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (_) => ActiveNavigationScreen(
// //                         start: _sourceLocation!,
// //                         route: route,
// //                       ),
// //                     ),
// //                   );
// //                 }
// //               },
// //               iconSize: 20,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // lib/screens/routes/route_comparison_screen_ENHANCED.dart
// // Complete route comparison with autocomplete, polylines, highlighting, and map controls

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';
// import '../../models/route_model.dart';
// import '../../providers/route_provider.dart';
// import '../../services/google_places_service.dart';
// import '../navigation/navigation_screen.dart';

// class RouteComparisonScreen extends StatefulWidget {
//   final LatLng currentLocation;

//   const RouteComparisonScreen({required this.currentLocation, super.key});

//   @override
//   State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
// }

// class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
//   GoogleMapController? _mapController;
//   MapType _mapType = MapType.normal;
//   bool _trafficEnabled = true;

//   // Source/Destination
//   final TextEditingController _sourceController = TextEditingController();
//   final TextEditingController _destController = TextEditingController();
//   LatLng? _sourceLocation;
//   LatLng? _destLocation;

//   // Autocomplete
//   final GooglePlacesService _placesService = GooglePlacesService();
//   Timer? _debounceTimer;
//   List<dynamic> _sourceSuggestions = [];
//   List<dynamic> _destSuggestions = [];
//   bool _loadingSourceSuggestions = false;
//   bool _loadingDestSuggestions = false;
//   bool _showSourceSuggestions = false;
//   bool _showDestSuggestions = false;

//   // Map elements
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};

//   // Route panel
//   bool _routePanelVisible = false;

//   @override
//   void initState() {
//     super.initState();
//     _sourceLocation = widget.currentLocation;
//     _updateSourceFieldWithLocation();
//     _updateMarkers();
//   }

//   Future<void> _updateSourceFieldWithLocation() async {
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         widget.currentLocation.latitude,
//         widget.currentLocation.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final pm = placemarks.first;
//         _sourceController.text =
//             '${pm.name ?? ''} ${pm.street ?? ''}, ${pm.locality ?? ''}'.trim();
//       }
//     } catch (e) {
//       _sourceController.text = 'Current Location';
//     }
//   }

//   void _updateMarkers() {
//     _markers = {
//       if (_destLocation != null)
//         Marker(
//           markerId: const MarkerId('destination'),
//           position: _destLocation!,
//           infoWindow: InfoWindow(
//             title: 'Destination',
//             snippet: _destController.text,
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueRed,
//           ),
//         ),
//     };
//     setState(() {});
//   }

//   // Autocomplete for source
//   void _onSourceTextChanged(String value) {
//     _debounceTimer?.cancel();
//     if (value.trim().isEmpty) {
//       setState(() {
//         _sourceSuggestions = [];
//         _showSourceSuggestions = false;
//       });
//       return;
//     }

//     setState(() {
//       _loadingSourceSuggestions = true;
//       _showSourceSuggestions = true;
//     });

//     _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
//       try {
//         final preds = await _placesService.autocomplete(value);
//         if (!mounted) return;
//         setState(() {
//           _sourceSuggestions = preds.isNotEmpty
//               ? preds
//               : [
//                   {'description': value, 'synthetic': true}
//                 ];
//           _loadingSourceSuggestions = false;
//         });
//       } catch (e) {
//         if (!mounted) return;
//         setState(() {
//           _sourceSuggestions = [
//             {'description': value, 'synthetic': true}
//           ];
//           _loadingSourceSuggestions = false;
//         });
//       }
//     });
//   }

//   // Autocomplete for destination
//   void _onDestTextChanged(String value) {
//     _debounceTimer?.cancel();
//     if (value.trim().isEmpty) {
//       setState(() {
//         _destSuggestions = [];
//         _showDestSuggestions = false;
//       });
//       return;
//     }

//     setState(() {
//       _loadingDestSuggestions = true;
//       _showDestSuggestions = true;
//     });

//     _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
//       try {
//         final preds = await _placesService.autocomplete(value);
//         if (!mounted) return;
//         setState(() {
//           _destSuggestions = preds.isNotEmpty
//               ? preds
//               : [
//                   {'description': value, 'synthetic': true}
//                 ];
//           _loadingDestSuggestions = false;
//         });
//       } catch (e) {
//         if (!mounted) return;
//         setState(() {
//           _destSuggestions = [
//             {'description': value, 'synthetic': true}
//           ];
//           _loadingDestSuggestions = false;
//         });
//       }
//     });
//   }

//   Future<void> _useCurrentLocation() async {
//     try {
//       final position = await Geolocator.getCurrentPosition(
//         locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high,
//         ),
//       );
//       final location = LatLng(position.latitude, position.longitude);
//       setState(() {
//         _sourceLocation = location;
//       });

//       final placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final pm = placemarks.first;
//         _sourceController.text =
//             '${pm.name ?? ''} ${pm.street ?? ''}, ${pm.locality ?? ''}'.trim();
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to get current location')),
//       );
//     }
//   }

//   Future<void> _selectSourceSuggestion(dynamic item) async {
//     setState(() {
//       _sourceSuggestions = [];
//       _showSourceSuggestions = false;
//     });

//     final isSynthetic = item is Map && item['synthetic'] == true;
//     final description =
//         isSynthetic ? item['description'].toString() : (item.description ?? '');

//     _sourceController.text = description;

//     if (isSynthetic) {
//       try {
//         final locations = await locationFromAddress(description);
//         if (locations.isNotEmpty) {
//           final loc = locations.first;
//           setState(() {
//             _sourceLocation = LatLng(loc.latitude, loc.longitude);
//           });
//         }
//       } catch (e) {
//         debugPrint('Geocoding error: $e');
//       }
//     } else if (item.placeId != null) {
//       final details = await _placesService.getPlaceDetails(item.placeId!);
//       final lat =
//           (details['geometry']?['location']?['lat'] as num?)?.toDouble();
//       final lng =
//           (details['geometry']?['location']?['lng'] as num?)?.toDouble();
//       if (lat != null && lng != null) {
//         setState(() {
//           _sourceLocation = LatLng(lat, lng);
//         });
//         _mapController?.animateCamera(
//           CameraUpdate.newLatLng(LatLng(lat, lng)),
//         );
//       }
//     }
//   }

//   Future<void> _selectDestSuggestion(dynamic item) async {
//     setState(() {
//       _destSuggestions = [];
//       _showDestSuggestions = false;
//     });

//     final isSynthetic = item is Map && item['synthetic'] == true;
//     final description =
//         isSynthetic ? item['description'].toString() : (item.description ?? '');

//     _destController.text = description;

//     if (isSynthetic) {
//       try {
//         final locations = await locationFromAddress(description);
//         if (locations.isNotEmpty) {
//           final loc = locations.first;
//           setState(() {
//             _destLocation = LatLng(loc.latitude, loc.longitude);
//           });
//           _updateMarkers();
//         }
//       } catch (e) {
//         debugPrint('Geocoding error: $e');
//       }
//     } else if (item.placeId != null) {
//       final details = await _placesService.getPlaceDetails(item.placeId!);
//       final lat =
//           (details['geometry']?['location']?['lat'] as num?)?.toDouble();
//       final lng =
//           (details['geometry']?['location']?['lng'] as num?)?.toDouble();
//       if (lat != null && lng != null) {
//         setState(() {
//           _destLocation = LatLng(lat, lng);
//         });
//         _updateMarkers();
//         _mapController?.animateCamera(
//           CameraUpdate.newLatLng(LatLng(lat, lng)),
//         );
//       }
//     }

//     // Auto-fetch routes
//     if (_sourceLocation != null && _destLocation != null) {
//       _compareRoutes();
//     }
//   }

//   Future<void> _compareRoutes() async {
//     if (_sourceLocation == null || _destLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select both source and destination'),
//         ),
//       );
//       return;
//     }

//     final routeProvider = context.read<RouteProvider>();
//     await routeProvider.compareRoutes(_sourceLocation!, _destLocation!);

//     if (!mounted) return;
//     if (routeProvider.routes.isNotEmpty) {
//       setState(() {
//         _routePanelVisible = true;
//       });
//       _buildPolylines(routeProvider.routes, routeProvider.selectedRoute);
//     }
//   }

//   void _buildPolylines(List<RouteData> routes, RouteData? selectedRoute) {
//     _polylines.clear();

//     for (int i = 0; i < routes.length; i++) {
//       final route = routes[i];
//       final isSelected = selectedRoute?.id == route.id;
//       final color = _parseColor(route.color);

//       // Shadow for selected route
//       if (isSelected) {
//         _polylines.add(
//           Polyline(
//             polylineId: PolylineId('${route.id}_shadow'),
//             points: route.decodedPoints,
//             color: Colors.black.withOpacity(0.2),
//             width: 14,
//             zIndex: 2,
//             consumeTapEvents: false,
//           ),
//         );
//       }

//       // Main polyline
//       _polylines.add(
//         Polyline(
//           polylineId: PolylineId(route.id),
//           points: route.decodedPoints,
//           color: color.withOpacity(isSelected ? 0.95 : 0.5),
//           width: isSelected ? 10 : 5,
//           zIndex: isSelected ? 3 : 1,
//           consumeTapEvents: true,
//           onTap: () => _selectRoute(route),
//         ),
//       );
//     }

//     setState(() {});
//   }

//   Color _parseColor(String colorStr) {
//     final c = colorStr.toLowerCase();
//     if (c.contains('green')) return Colors.green;
//     if (c.contains('yellow')) return Colors.yellow;
//     if (c.contains('orange')) return Colors.orange;
//     if (c.contains('red')) return Colors.red;
//     if (c.contains('blue')) return Colors.blue;

//     // Try hex
//     if (colorStr.startsWith('#')) {
//       try {
//         final hex = colorStr.substring(1);
//         return Color(int.parse('FF$hex', radix: 16));
//       } catch (e) {
//         return Colors.blueGrey;
//       }
//     }

//     return Colors.blueGrey;
//   }

//   void _selectRoute(RouteData route) {
//     final routeProvider = context.read<RouteProvider>();
//     routeProvider.selectRoute(route);
//     _buildPolylines(routeProvider.routes, route);

//     // Fit camera to route
//     if (route.decodedPoints.isNotEmpty) {
//       final bounds = _boundsFromPoints(route.decodedPoints);
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 48),
//       );
//     }
//   }

//   LatLngBounds _boundsFromPoints(List<LatLng> points) {
//     double south = points.first.latitude;
//     double north = points.first.latitude;
//     double west = points.first.longitude;
//     double east = points.first.longitude;

//     for (final p in points) {
//       if (p.latitude < south) south = p.latitude;
//       if (p.latitude > north) north = p.latitude;
//       if (p.longitude < west) west = p.longitude;
//       if (p.longitude > east) east = p.longitude;
//     }

//     return LatLngBounds(
//       southwest: LatLng(south, west),
//       northeast: LatLng(north, east),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Find Safe Route'),
//         centerTitle: true,
//         actions: [
//           // Map type toggle
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.layers),
//             onSelected: (value) {
//               if (value == 'traffic') {
//                 setState(() => _trafficEnabled = !_trafficEnabled);
//               } else {
//                 setState(() {
//                   _mapType = {
//                     'normal': MapType.normal,
//                     'hybrid': MapType.hybrid,
//                     'satellite': MapType.satellite,
//                     'terrain': MapType.terrain,
//                   }[value]!;
//                 });
//               }
//             },
//             itemBuilder: (context) => [
//               _buildMapTypeItem('normal', 'Normal'),
//               _buildMapTypeItem('hybrid', 'Hybrid'),
//               _buildMapTypeItem('satellite', 'Satellite'),
//               _buildMapTypeItem('terrain', 'Terrain'),
//               const PopupMenuDivider(),
//               PopupMenuItem(
//                 value: 'traffic',
//                 child: Row(
//                   children: [
//                     Icon(
//                       _trafficEnabled ? Icons.check : null,
//                       color: Colors.green,
//                       size: 18,
//                     ),
//                     const SizedBox(width: 12),
//                     const Text('Traffic Layer'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Map
//           GoogleMap(
//             onMapCreated: (controller) => _mapController = controller,
//             initialCameraPosition: CameraPosition(
//               target: widget.currentLocation,
//               zoom: 14,
//             ),
//             mapType: _mapType,
//             trafficEnabled: _trafficEnabled,
//             markers: _markers,
//             polylines: _polylines,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: true,
//           ),

//           // Search controls
//           Positioned(
//             top: 16,
//             left: 16,
//             right: 16,
//             child: Material(
//               elevation: 8,
//               borderRadius: BorderRadius.circular(12),
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     // Source field
//                     TextField(
//                       controller: _sourceController,
//                       decoration: InputDecoration(
//                         hintText: 'Source',
//                         prefixIcon: const Icon(Icons.my_location),
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.gps_fixed),
//                           onPressed: _useCurrentLocation,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       onChanged: _onSourceTextChanged,
//                       onTap: () {
//                         setState(() => _showSourceSuggestions = true);
//                       },
//                     ),

//                     // Source suggestions
//                     if (_showSourceSuggestions && _sourceSuggestions.isNotEmpty)
//                       ..._buildSuggestions(
//                         _sourceSuggestions,
//                         _selectSourceSuggestion,
//                       ),

//                     const SizedBox(height: 8),

//                     // Destination field
//                     TextField(
//                       controller: _destController,
//                       decoration: InputDecoration(
//                         hintText: 'Destination',
//                         prefixIcon: const Icon(Icons.search),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 12,
//                         ),
//                       ),
//                       onChanged: _onDestTextChanged,
//                       onTap: () {
//                         setState(() => _showDestSuggestions = true);
//                       },
//                     ),

//                     // Dest suggestions
//                     if (_showDestSuggestions && _destSuggestions.isNotEmpty)
//                       ..._buildSuggestions(
//                         _destSuggestions,
//                         _selectDestSuggestion,
//                       ),

//                     const SizedBox(height: 12),

//                     // Compare button
//                     if (_sourceLocation != null && _destLocation != null)
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           onPressed: _compareRoutes,
//                           icon: const Icon(Icons.compare_arrows),
//                           label: const Text('Compare Routes'),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // Route panel
//           if (_routePanelVisible)
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: _buildRoutePanel(),
//             ),
//         ],
//       ),
//     );
//   }

//   PopupMenuItem<String> _buildMapTypeItem(String value, String label) {
//     final isActive = _mapType.toString().contains(value);
//     return PopupMenuItem(
//       value: value,
//       child: Row(
//         children: [
//           Icon(
//             isActive ? Icons.check : null,
//             color: Colors.green,
//             size: 18,
//           ),
//           const SizedBox(width: 12),
//           Text(label),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildSuggestions(
//     List<dynamic> suggestions,
//     Function(dynamic) onSelect,
//   ) {
//     return [
//       const SizedBox(height: 8),
//       ConstrainedBox(
//         constraints: const BoxConstraints(maxHeight: 150),
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: suggestions.length,
//           itemBuilder: (context, index) {
//             final item = suggestions[index];
//             final isSynthetic = item is Map && item['synthetic'] == true;
//             final description = isSynthetic
//                 ? item['description'].toString()
//                 : (item.description ?? '');

//             return ListTile(
//               dense: true,
//               title: Text(description),
//               onTap: () => onSelect(item),
//             );
//           },
//         ),
//       ),
//     ];
//   }

//   Widget _buildRoutePanel() {
//     return Consumer<RouteProvider>(
//       builder: (context, routeProvider, _) {
//         if (routeProvider.routes.isEmpty) {
//           return const SizedBox.shrink();
//         }

//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           height: 300,
//           child: Material(
//             elevation: 12,
//             borderRadius: const BorderRadius.vertical(
//               top: Radius.circular(20),
//             ),
//             child: Column(
//               children: [
//                 // Drag handle
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   child: Container(
//                     width: 48,
//                     height: 6,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                 ),

//                 // Header
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Routes',
//                         style: AppTextStyles.titleLarge,
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () {
//                           setState(() => _routePanelVisible = false);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),

//                 const Divider(height: 1),

//                 // Routes list
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: routeProvider.routes.length,
//                     itemBuilder: (context, index) {
//                       final route = routeProvider.routes[index];
//                       final isSelected =
//                           routeProvider.selectedRoute?.id == route.id;

//                       return _buildRouteCard(route, isSelected);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRouteCard(RouteData route, bool isSelected) {
//     final color = _parseColor(route.color);

//     return Container(
//       color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
//       child: ListTile(
//         leading: Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         title: Row(
//           children: [
//             Text('Route ${route.id.hashCode % 10}'),
//             if (isSelected) ...[
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 2,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: const Text(
//                   'SELECTED',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Safety: ${route.safetyScore.toStringAsFixed(1)}'),
//             Text('${route.distance} • ${route.duration}'),
//             if (route.tags.isNotEmpty)
//               Wrap(
//                 spacing: 4,
//                 children: route.tags.map((tag) {
//                   return Chip(
//                     label: Text(tag, style: const TextStyle(fontSize: 10)),
//                     padding: EdgeInsets.zero,
//                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                   );
//                 }).toList(),
//               ),
//           ],
//         ),
//         trailing: IconButton(
//           icon: const Icon(Icons.navigation),
//           onPressed: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (_) => NavigationScreen(
//                   start: _sourceLocation!,
//                   route: route,
//                 ),
//               ),
//             );
//           },
//         ),
//         onTap: () => _selectRoute(route),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _sourceController.dispose();
//     _destController.dispose();
//     super.dispose();
//   }
// }
