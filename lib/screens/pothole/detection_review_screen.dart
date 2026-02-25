import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/detection_event.dart';
import '../../providers/pothole_provider.dart';
import '../../services/detection_event_store.dart';

class DetectionReviewScreen extends StatefulWidget {
  const DetectionReviewScreen({super.key});

  @override
  State<DetectionReviewScreen> createState() => _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends State<DetectionReviewScreen> {
  List<DetectionEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      await DetectionEventStore.ensureInitialized();
      final items = DetectionEventStore.getAllEvents();
      if (!mounted) return;
      setState(() {
        _events = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load events: $e';
      });
    }
  }

  Color _markerColor(String label) {
    switch (label) {
      case DetectionLabel.pothole:
        return Colors.green;
      case DetectionLabel.speedBreaker:
        return Colors.blue;
      case DetectionLabel.falseDetection:
        return Colors.grey;
      case DetectionLabel.unverified:
      default:
        return Colors.red;
    }
  }

  Future<void> _applyLabel(
    DetectionEvent event,
    String newLabel,
    PotholeProvider provider,
  ) async {
    await DetectionEventStore.updateLabel(event.id, newLabel);

    if (newLabel == DetectionLabel.pothole ||
        newLabel == DetectionLabel.speedBreaker) {
      await provider.submitReviewedDetection(
        eventId: event.id,
        type: newLabel == DetectionLabel.pothole ? 'pothole' : 'speed_breaker',
      );
    }

    await _loadEvents();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _openEventSheet(DetectionEvent event, PotholeProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detection Event',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _detail('Label', event.label),
                _detail('Latitude', event.latitude.toStringAsFixed(6)),
                _detail('Longitude', event.longitude.toStringAsFixed(6)),
                _detail('Speed', '${event.speedKmph.toStringAsFixed(1)} km/h'),
                _detail('Accel Spike', event.accelSpike.toStringAsFixed(3)),
                _detail('Gyro Peak', event.gyroPeak.toStringAsFixed(3)),
                _detail(
                    'Vertical Ratio', event.verticalRatio.toStringAsFixed(3)),
                _detail('Merged Detections', event.detectionCount.toString()),
                _detail('Timestamp', event.timestamp.toIso8601String()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _applyLabel(
                        event,
                        DetectionLabel.pothole,
                        provider,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Pothole'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _applyLabel(
                        event,
                        DetectionLabel.speedBreaker,
                        provider,
                      ),
                      icon: const Icon(Icons.speed),
                      label: const Text('Mark Speed Breaker'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _applyLabel(
                        event,
                        DetectionLabel.falseDetection,
                        provider,
                      ),
                      icon: const Icon(Icons.block_outlined),
                      label: const Text('Mark False Detection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Review'),
      ),
      body: Consumer<PotholeProvider>(
        builder: (context, provider, _) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null) {
            return Center(
              child: Text(_error!, style: AppTextStyles.bodyMedium),
            );
          }

          if (_events.isEmpty) {
            return Center(
              child: Text(
                'No locally stored detection events yet.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          final center =
              LatLng(_events.first.latitude, _events.first.longitude);

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.saferoute_frontend',
              ),
              MarkerLayer(
                markers: _events
                    .map(
                      (event) => Marker(
                        point: LatLng(event.latitude, event.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _openEventSheet(event, provider),
                          child: Icon(
                            Icons.location_on,
                            size: 34,
                            color: _markerColor(event.label),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
