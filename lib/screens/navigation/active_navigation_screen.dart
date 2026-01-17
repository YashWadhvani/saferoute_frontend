// lib/screens/navigation/active_navigation_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/route_model.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../state/tts_settings.dart';

class ActiveNavigationScreen extends StatefulWidget {
  final LatLng start;
  final RouteData route;

  const ActiveNavigationScreen(
      {required this.start, required this.route, super.key});

  @override
  State<ActiveNavigationScreen> createState() => _ActiveNavigationScreenState();
}

class _ActiveNavigationScreenState extends State<ActiveNavigationScreen> {
  GoogleMapController? _controller;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  late FlutterTts _tts;

  int _posIndex = 0;
  Timer? _moveTimer;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  BitmapDescriptor? _carIcon;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupMapElements();
    _loadCarIcon();
    // Load TTS settings
    final ttsSettings = context.read<TtsSettings>();
    _tts.setLanguage(ttsSettings.language);
    _tts.setSpeechRate(ttsSettings.rate);
    // Start real navigation
    Future.delayed(const Duration(milliseconds: 800), _startRealNavigation);
  }

  Future<void> _loadCarIcon() async {
    try {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ??
          View.of(context).devicePixelRatio;
      final config = ImageConfiguration(
          devicePixelRatio: dpr, size: const Size(12, 12)); // Reduced to 1/10th
      final assetIcon =
          await BitmapDescriptor.asset(config, 'assets/images/car.png');
      if (!mounted) return;
      setState(() => _carIcon = assetIcon);
    } catch (e) {
      debugPrint('Failed to load car icon: $e');
    }
  }

  void _setupMapElements() {
    final points = widget.route.decodedPoints;
    _polylines.add(Polyline(
      polylineId: PolylineId(widget.route.id),
      points: points,
      color: _colorFromHex(widget.route.color).withAlpha((0.8 * 255).round()),
      width: 6,
    ));

    if (points.isNotEmpty) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: points.last,
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
    }
  }

  Color _colorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    switch (hex.toLowerCase()) {
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
      default:
        return AppColors.primary;
    }
  }

  void _startRealNavigation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        final loc = LatLng(position.latitude, position.longitude);
        _currentPosition = loc;

        // Find nearest point on route
        final points = widget.route.decodedPoints;
        int nearestIdx = 0;
        double minDist = double.infinity;
        for (int i = 0; i < points.length; i++) {
          final dist = Geolocator.distanceBetween(
            loc.latitude,
            loc.longitude,
            points[i].latitude,
            points[i].longitude,
          );
          if (dist < minDist) {
            minDist = dist;
            nearestIdx = i;
          }
        }

        // Update position and camera
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'me');
          _markers.add(Marker(
            markerId: const MarkerId('me'),
            position: loc,
            icon: _carIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
          ));
        });

        _controller?.animateCamera(CameraUpdate.newLatLng(loc));

        // Check if arrived
        if (nearestIdx >= points.length - 1) {
          _tts.speak('You have arrived at your destination');
          _positionStream?.cancel();
        } else {
          // Check for turns
          _checkForTurns(points, nearestIdx);
        }
      });
    } catch (e) {
      debugPrint('Error starting navigation: $e');
      // Fallback to simulation
      _startSimulation();
    }
  }

  void _checkForTurns(List<LatLng> points, int currentIdx) {
    if (currentIdx < 1 || currentIdx >= points.length - 1) return;

    final prev = points[currentIdx - 1];
    final current = points[currentIdx];
    final next = points[currentIdx + 1];

    final bearing1 = _bearing(prev, current);
    final bearing2 = _bearing(current, next);
    double delta = ((_normalize(bearing2 - bearing1) + 540) % 360) - 180;

    if (delta.abs() > 30) {
      final turn = delta > 0 ? 'turn right' : 'turn left';
      final strength = delta.abs() > 90 ? 'sharply' : 'slightly';
      final instr = 'In a short while, $turn $strength.';
      _tts.speak(instr);
    }
  }

  void _startSimulation() {
    final points = widget.route.decodedPoints;
    if (points.isEmpty) return;

    _posIndex = 0;
    _moveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_posIndex >= points.length) {
        _tts.speak('You have arrived at your destination');
        timer.cancel();
        return;
      }

      final current = points[_posIndex];
      _currentPosition = current;
      _controller?.animateCamera(CameraUpdate.newLatLng(current));

      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'me');
        _markers.add(Marker(
          markerId: const MarkerId('me'),
          position: current,
          icon: _carIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      });

      if (_posIndex > 1) {
        final prev = points[_posIndex - 1];
        final prev2 = points[_posIndex - 2];
        final b1 = _bearing(prev2, prev);
        final b2 = _bearing(prev, current);
        final delta = ((_normalize(b2 - b1) + 540) % 360) - 180;
        if (delta.abs() > 30) {
          final turn = delta > 0 ? 'turn right' : 'turn left';
          final strength = delta.abs() > 90 ? 'sharply' : 'slightly';
          final instr = 'In a short while, $turn $strength.';
          _tts.speak(instr);
        }
      }

      _posIndex++;
    });
  }

  double _bearing(LatLng a, LatLng b) {
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);
    final dLon = _toRad(b.longitude - a.longitude);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x);
    return (_toDeg(brng) + 360) % 360;
  }

  double _toRad(double deg) => deg * pi / 180.0;
  double _toDeg(double rad) => rad * 180.0 / pi;
  double _normalize(double angle) => angle % 360;

  @override
  void dispose() {
    _moveTimer?.cancel();
    _positionStream?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: GoogleMap(
        onMapCreated: (c) => _controller = c,
        initialCameraPosition: CameraPosition(target: widget.start, zoom: 16),
        polylines: _polylines,
        markers: _markers,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${widget.route.distance}',
                    style: AppTextStyles.titleSmall),
                Text('ETA: ${widget.route.duration}',
                    style: AppTextStyles.bodySmall),
              ],
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
