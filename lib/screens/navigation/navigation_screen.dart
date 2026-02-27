// lib/screens/navigation/navigation_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';
import '../../models/route_model.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/pothole_provider.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng start;
  final RouteData route;

  const NavigationScreen({required this.start, required this.route, super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _controller;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  late FlutterTts _tts;

  Position? _currentPosition;
  Position? _initialPosition;
  int _currentPointIndex = 0;
  double _distanceToNext = 0;
  double _remainingDistance = 0;
  String _currentInstruction = 'Starting navigation...';
  bool _hasStartedMoving = false;
  bool _hasAnnouncedArrival = false;
  bool _bottomPanelCollapsed = false;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;
  double _heading = 0.0; // Phone compass heading
  bool _useSimulation = false; // Set to false for real GPS
  MapType _mapType = MapType.hybrid;
  bool _showMapTypeSelector = false;
  bool _isPotholeDetectionEnabled = false;

  BitmapDescriptor? _carIcon;
  late PotholeProvider _potholeProvider;

  @override
  void initState() {
    super.initState();
    _potholeProvider = context.read<PotholeProvider>();
    _tts = FlutterTts();
    _tts.setLanguage('en-US');
    _setupMapElements();
    _loadCarIcon();
    _startNavigation();
  }

  Future<void> _startPotholeDetection() async {
    try {
      await _potholeProvider.startDetection();
    } catch (e) {
      debugPrint('Failed to start pothole detection in navigation: $e');
    }
  }

  Future<void> _togglePotholeDetection(bool enabled) async {
    setState(() {
      _isPotholeDetectionEnabled = enabled;
    });

    if (enabled) {
      await _startPotholeDetection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pothole detection enabled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      _potholeProvider.stopDetection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pothole detection disabled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car.png',
      );
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load car icon: $e');
      _carIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  @override
  void dispose() {
    _potholeProvider.stopDetection();
    _positionStream?.cancel();
    _compassStream?.cancel();
    _tts.stop();
    _controller?.dispose();
    super.dispose();
  }

  void _setupMapElements() {
    final points = widget.route.decodedPoints;

    // Add destination marker
    if (points.isNotEmpty) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: points.last,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    _updateRoutePolyline();
  }

  void _updateRoutePolyline() {
    _polylines.clear();
    final points = widget.route.decodedPoints;

    if (_currentPointIndex > 0 && _currentPointIndex < points.length) {
      // Remaining route (blue)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_remaining'),
          points: points.sublist(_currentPointIndex),
          color: AppColors.primary.withAlpha((0.8 * 255).round()),
          width: 6,
          zIndex: 2,
        ),
      );

      // Covered route (gray)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_covered'),
          points: points.sublist(0, _currentPointIndex + 1),
          color: Colors.grey.withAlpha((0.4 * 255).round()),
          width: 4,
          zIndex: 1,
        ),
      );
    } else {
      // Full route at start
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_full'),
          points: points,
          color: AppColors.primary.withAlpha((0.8 * 255).round()),
          width: 6,
        ),
      );
    }

    if (mounted) setState(() {});
  }

  void _startNavigation() async {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Start listening to compass for phone heading
    _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        setState(() {
          _heading = event.heading!;
        });
      }
    });

    if (_useSimulation) {
      _startSimulation();
    } else {
      _startRealGPS();
    }
  }

  void _startRealGPS() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position position) {
    _initialPosition ??= position;

    if (_initialPosition != null && !_hasStartedMoving) {
      final movedMeters = Geolocator.distanceBetween(
        _initialPosition!.latitude,
        _initialPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (movedMeters >= 20 || position.speed >= 1.5) {
        _hasStartedMoving = true;
      }
    }

    setState(() {
      _currentPosition = position;
    });

    _updateNavigationInfo();
    _updateCarMarker();
    _moveCamera();
  }

  void _updateNavigationInfo() {
    if (_currentPosition == null) return;

    final points = widget.route.decodedPoints;
    if (points.isEmpty) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );
    final destination = points.last;

    final distanceToDestination = Geolocator.distanceBetween(
      currentLatLng.latitude,
      currentLatLng.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Only mark arrival after actual movement and close proximity to destination
    if (_hasStartedMoving && distanceToDestination <= 25) {
      _currentInstruction = 'You have arrived at your destination';
      _distanceToNext = 0;
      _remainingDistance = 0;
      _currentPointIndex = points.length - 1;
      _updateRoutePolyline();

      if (!_hasAnnouncedArrival) {
        _hasAnnouncedArrival = true;
        _tts.speak(_currentInstruction);
      }
      return;
    }

    // Find nearest point on route
    double minDistance = double.infinity;
    int nearestIndex = _currentPointIndex;

    for (int i = 0; i < points.length; i++) {
      final distance = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        points[i].latitude,
        points[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    _currentPointIndex = nearestIndex;

    // Calculate distance to next point
    if (_currentPointIndex < points.length - 1) {
      _distanceToNext = Geolocator.distanceBetween(
        currentLatLng.latitude,
        currentLatLng.longitude,
        points[_currentPointIndex + 1].latitude,
        points[_currentPointIndex + 1].longitude,
      );

      // Calculate remaining distance
      _remainingDistance = 0;
      for (int i = _currentPointIndex; i < points.length - 1; i++) {
        _remainingDistance += Geolocator.distanceBetween(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude,
        );
      }

      // Generate instruction
      _currentInstruction = _generateInstruction();

      // Update route polyline to show progress
      _updateRoutePolyline();
    } else {
      // Close to final path point but not necessarily arrived physically
      _currentInstruction = _hasStartedMoving
          ? 'Continue to destination'
          : 'Start moving to begin navigation';
      _distanceToNext = 0;
      _remainingDistance = 0;
    }
  }

  String _generateInstruction() {
    final points = widget.route.decodedPoints;
    if (_currentPointIndex >= points.length - 2) {
      return 'Continue to destination';
    }

    final prev = _currentPointIndex > 0
        ? points[_currentPointIndex - 1]
        : points[_currentPointIndex];
    final current = points[_currentPointIndex];
    final next = points[_currentPointIndex + 1];

    final bearing1 = _calculateBearing(prev, current);
    final bearing2 = _calculateBearing(current, next);

    double turnAngle = (bearing2 - bearing1 + 360) % 360;
    if (turnAngle > 180) turnAngle -= 360;

    String instruction;
    if (turnAngle.abs() < 20) {
      instruction = 'Continue straight';
    } else if (turnAngle > 0) {
      if (turnAngle > 45) {
        instruction = 'Turn right';
      } else {
        instruction = 'Bear right';
      }
    } else {
      if (turnAngle < -45) {
        instruction = 'Turn left';
      } else {
        instruction = 'Bear left';
      }
    }

    // Announce at specific distances
    if (_distanceToNext <= 50 && _distanceToNext > 10) {
      final message = '$instruction in ${_distanceToNext.round()} meters';
      _tts.speak(message);
      return message;
    } else if (_distanceToNext <= 10) {
      final message = 'Now $instruction';
      return message;
    }

    return '$instruction in ${_distanceToNext.round()} meters';
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
  double _toDegrees(double radians) => radians * 180 / math.pi;

  void _updateCarMarker() {
    if (_currentPosition == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    _markers.removeWhere((m) => m.markerId.value == 'car');
    _markers.add(
      Marker(
        markerId: const MarkerId('car'),
        position: currentLatLng,
        icon: _carIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: _heading, // Use compass heading instead of calculated bearing
        anchor: const Offset(0.5, 0.5),
        flat: true, // Makes rotation work better
      ),
    );

    if (mounted) setState(() {});
  }

  void _moveCamera() {
    if (_currentPosition == null || _controller == null) return;

    final currentLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLatLng,
          zoom: 18,
          bearing: _heading, // Rotate map based on phone heading
          tilt: 45,
        ),
      ),
    );
  }

  void _startSimulation() {
    // Keep for testing if needed
    int index = 0;
    final points = widget.route.decodedPoints;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || index >= points.length) {
        timer.cancel();
        return;
      }

      final simulatedPosition = Position(
        latitude: points[index].latitude,
        longitude: points[index].longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 5.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      _onPositionUpdate(simulatedPosition);
      index++;
    });
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Safe Route'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: (controller) => _controller = controller,
            initialCameraPosition: CameraPosition(
              target: widget.start,
              zoom: 16,
            ),
            mapType: _mapType,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: false, // We're using custom car marker
            myLocationButtonEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // Top navigation glass panel
          Positioned(
            top: 12,
            left: 12,
            right: 84,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.92 * 255).round()),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.12 * 255).round()),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.12 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getInstructionIcon(),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentInstruction,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDistance(_distanceToNext),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Type Selector
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMapTypeSelector = !_showMapTypeSelector;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
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
                    child: const Icon(
                      Icons.layers,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_showMapTypeSelector)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 140,
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
                    child: Column(
                      children: [
                        _buildMapTypeOption('Default', MapType.normal),
                        const Divider(height: 1),
                        _buildMapTypeOption('Satellite', MapType.satellite),
                        const Divider(height: 1),
                        _buildMapTypeOption('Hybrid', MapType.hybrid),
                        const Divider(height: 1),
                        _buildMapTypeOption('Terrain', MapType.terrain),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Navigation Info Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.98 * 255).round()),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Text('Live Navigation',
                              style: AppTextStyles.titleLarge),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withAlpha((0.12 * 255).round()),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Safety ${widget.route.safetyScore.toStringAsFixed(1)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => setState(() {
                              _bottomPanelCollapsed = !_bottomPanelCollapsed;
                            }),
                            icon: Icon(_bottomPanelCollapsed
                                ? Icons.expand_less
                                : Icons.expand_more),
                            tooltip: _bottomPanelCollapsed
                                ? 'Expand panel'
                                : 'Collapse panel',
                          )
                        ],
                      ),

                      if (!_bottomPanelCollapsed) const SizedBox(height: 14),

                      // Pothole Detection Toggle

                      if (!_bottomPanelCollapsed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sensors,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pothole Detection',
                                  style: AppTextStyles.titleSmall,
                                ),
                              ),
                              Switch.adaptive(
                                value: _isPotholeDetectionEnabled,
                                onChanged: _togglePotholeDetection,
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),

                      if (!_bottomPanelCollapsed) const SizedBox(height: 16),

                      if (!_bottomPanelCollapsed)
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Remaining',
                                _formatDistance(_remainingDistance),
                                Icons.route,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Safety',
                                widget.route.safetyScore.toStringAsFixed(1),
                                Icons.shield,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Consumer<PotholeProvider>(
                                builder: (context, potholeProvider, _) {
                                  return _buildStatCard(
                                    'Potholes',
                                    '${potholeProvider.detectedCount}',
                                    Icons.warning_amber,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                      if (!_bottomPanelCollapsed) const SizedBox(height: 16),

                      // Stop Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.stop),
                          label: const Text('End Navigation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeOption(String label, MapType type) {
    final isSelected = _mapType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapType = type;
          _showMapTypeSelector = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha((0.1 * 255).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha((0.8 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall,
                ),
                Text(
                  value,
                  style: AppTextStyles.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInstructionIcon() {
    if (_currentInstruction.toLowerCase().contains('left')) {
      return Icons.turn_left;
    } else if (_currentInstruction.toLowerCase().contains('right')) {
      return Icons.turn_right;
    } else if (_currentInstruction.toLowerCase().contains('arrived')) {
      return Icons.location_on;
    }
    return Icons.arrow_upward;
  }
}
