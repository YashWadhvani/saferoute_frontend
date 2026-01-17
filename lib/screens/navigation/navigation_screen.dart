// lib/screens/navigation/navigation_screen.dart
// Simple navigation screen: draws polyline, simulates movement along route and announces turns via TTS
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/route_model.dart';
import '../../core/theme/app_text_styles.dart';

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

  int _posIndex = 0;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _setupMapElements();
    // start simulation after a short delay
    Future.delayed(const Duration(milliseconds: 800), _startSimulation);
  }

  void _setupMapElements() {
    final points = widget.route.decodedPoints;
    _polylines.add(Polyline(
      polylineId: PolylineId(widget.route.id),
      points: points,
      color: Colors.blue.withAlpha((0.8 * 255).round()),
      width: 6,
    ));

    if (points.isNotEmpty) {
      _markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: widget.start,
        infoWindow: const InfoWindow(title: 'Start'),
      ));
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: points.last,
        infoWindow: const InfoWindow(title: 'Destination'),
      ));
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
      _controller?.animateCamera(CameraUpdate.newLatLng(current));

      // Update moving marker
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'me');
        _markers.add(Marker(
          markerId: const MarkerId('me'),
          position: current,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));
      });

      // Check for a direction change (bearing delta) and announce
      if (_posIndex > 1) {
        final prev = points[_posIndex - 1];
        final prev2 = points[_posIndex - 2];
        final b1 = _bearing(prev2, prev);
        final b2 = _bearing(prev, current);
        final delta = ((_normalize(b2 - b1) + 540) % 360) - 180; // -180..180
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
