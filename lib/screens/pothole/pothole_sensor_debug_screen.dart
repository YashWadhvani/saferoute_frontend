import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pothole_provider.dart';
import '../../services/pothole_detection_service.dart';

class PotholeSensorDebugScreen extends StatefulWidget {
  const PotholeSensorDebugScreen({super.key});

  @override
  State<PotholeSensorDebugScreen> createState() =>
      _PotholeSensorDebugScreenState();
}

class _PotholeSensorDebugScreenState extends State<PotholeSensorDebugScreen> {
  final PotholeDetectionService _detectionService = PotholeDetectionService();
  late SensorDebugData _latest;
  StreamSubscription<SensorDebugData>? _subscription;

  @override
  void initState() {
    super.initState();
    _latest = _detectionService.latestSensorData;
    _subscription = _detectionService.sensorDataStream.listen((data) {
      if (!mounted) return;
      setState(() => _latest = data);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleDetection(PotholeProvider provider) async {
    if (provider.isDetecting) {
      provider.stopDetection();
    } else {
      await provider.startDetection();
      if (provider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error!)),
        );
      }
    }
  }

  Future<void> _shareLatestLogFile() async {
    final path = _detectionService.sensorLogFilePath;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sensor log found yet. Start detection first.'),
        ),
      );
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log file not found on device storage.'),
        ),
      );
      return;
    }

    try {
      final xFile = XFile(path);
      await SharePlus.instance.share(
        ShareParams(
          text: 'SafeRoute pothole sensor log',
          files: [xFile],
          subject: 'SafeRoute Sensor Log',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share log file: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Debug'),
      ),
      body: Consumer<PotholeProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusCard(provider),
              const SizedBox(height: 12),
              _sensorCard(
                title: 'Accelerometer (m/s²)',
                x: _latest.accelX,
                y: _latest.accelY,
                z: _latest.accelZ,
                magnitude: _latest.accelMagnitude,
                auxLabel: 'Spike',
                auxValue: _latest.accelSpike,
              ),
              const SizedBox(height: 12),
              _sensorCard(
                title: 'Gyroscope (rad/s)',
                x: _latest.gyroX,
                y: _latest.gyroY,
                z: _latest.gyroZ,
                magnitude: _latest.gyroMagnitude,
                auxLabel: 'Peak',
                auxValue: _latest.gyroPeak,
              ),
              const SizedBox(height: 12),
              _locationCard(),
              const SizedBox(height: 12),
              _notesCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(PotholeProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Detection Control',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  provider.isDetecting ? Icons.radar : Icons.pause_circle,
                  color: provider.isDetecting
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isDetecting ? 'Detecting...' : 'Stopped',
                  style: AppTextStyles.bodyMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _toggleDetection(provider),
                  icon: Icon(
                    provider.isDetecting ? Icons.stop : Icons.play_arrow,
                  ),
                  label:
                      Text(provider.isDetecting ? 'Stop' : 'Start Detection'),
                ),
              ],
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 10),
              Text(
                provider.error!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Log file: ${_detectionService.sensorLogFilePath ?? 'Not started yet'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _shareLatestLogFile,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share Latest Log File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorCard({
    required String title,
    required double x,
    required double y,
    required double z,
    required double magnitude,
    required String auxLabel,
    required double auxValue,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _row('x', x),
            _row('y', y),
            _row('z', z),
            const Divider(),
            _row('magnitude', magnitude),
            _row(auxLabel.toLowerCase(), auxValue),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    final speedKmph = _latest.speedMps * 3.6;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location & Motion',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _row('speed (m/s)', _latest.speedMps),
            _row('speed (km/h)', speedKmph),
            Text(
              'lat: ${_latest.latitude?.toStringAsFixed(6) ?? '--'}',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              'lng: ${_latest.longitude?.toStringAsFixed(6) ?? '--'}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'updated: ${_latest.timestamp.toIso8601String()}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Use this screen to observe raw sensor behavior on your phone before tuning thresholds. '
          'Candidate events are stored locally when spikes cross thresholds and speed is above minimum.',
          style: AppTextStyles.bodySmall,
        ),
      ),
    );
  }

  Widget _row(String key, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(key, style: AppTextStyles.bodySmall)),
          Text(
            value.toStringAsFixed(4),
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
