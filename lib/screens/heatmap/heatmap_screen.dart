// lib/screens/heatmap/heatmap_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pothole_provider.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PotholeProvider>().fetchPotholes(
            minLat: -90,
            maxLat: 90,
            minLng: -180,
            maxLng: 180,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap')),
      body: Consumer<PotholeProvider>(
        builder: (context, potholeProvider, _) {
          if (potholeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (potholeProvider.error != null) {
            return Center(
              child: Text(
                potholeProvider.error!,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }

          final potholes = potholeProvider.potholes;
          if (potholes.isEmpty) {
            return Center(
              child: Text('No potholes to display',
                  style: AppTextStyles.bodyLarge),
            );
          }

          final markers = potholes
              .map(
                (p) => Marker(
                  markerId: MarkerId('p_${p.id}'),
                  position: LatLng(p.latitude, p.longitude),
                  infoWindow: InfoWindow(
                    title: 'Pothole',
                    snippet:
                        'Intensity ${p.intensity.toStringAsFixed(1)} • Reports ${p.reports}',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    p.intensity >= 7
                        ? BitmapDescriptor.hueRed
                        : p.intensity >= 4
                            ? BitmapDescriptor.hueOrange
                            : BitmapDescriptor.hueYellow,
                  ),
                ),
              )
              .toSet();

          final first = potholes.first;
          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(first.latitude, first.longitude),
              zoom: 12,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
