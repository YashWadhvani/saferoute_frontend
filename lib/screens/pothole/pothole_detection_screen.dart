// lib/screens/pothole/pothole_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/pothole_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'detection_review_screen.dart';
import 'pothole_sensor_debug_screen.dart';

class PotholeDetectionScreen extends StatefulWidget {
  const PotholeDetectionScreen({super.key});

  @override
  State<PotholeDetectionScreen> createState() => _PotholeDetectionScreenState();
}

class _PotholeDetectionScreenState extends State<PotholeDetectionScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final sensorsStatus = await Permission.sensors.status;

    if (!locationStatus.isGranted || !sensorsStatus.isGranted) {
      await _requestPermissions();
    }
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.sensors,
      Permission.notification,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.sensors]!.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location and sensor permissions are required for pothole detection'),
          ),
        );
      }
    }
  }

  void _toggleDetection() async {
    final provider = context.read<PotholeProvider>();

    if (provider.isDetecting) {
      provider.stopDetection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pothole detection stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Check permissions first
      final locationStatus = await Permission.location.status;
      final sensorsStatus = await Permission.sensors.status;

      if (!locationStatus.isGranted || !sensorsStatus.isGranted) {
        await _requestPermissions();
        return;
      }

      await provider.startDetection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pothole detection started - Drive safely!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pothole Detection'),
        centerTitle: true,
      ),
      body: Consumer<PotholeProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detection Status Card
                _buildDetectionCard(provider),

                const SizedBox(height: 16),

                // Sensor Debug View
                _buildSensorDebugCard(),

                const SizedBox(height: 24),

                _buildDetectionReviewCard(),

                const SizedBox(height: 24),

                // How It Works
                _buildHowItWorksCard(),

                const SizedBox(height: 24),

                // Statistics
                _buildStatisticsCard(provider),

                const SizedBox(height: 24),

                // Tips
                _buildTipsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorDebugCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Debug',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'See raw accelerometer, gyroscope and GPS values before tuning thresholds.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PotholeSensorDebugScreen(),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('Open Live Sensor Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(PotholeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: provider.isDetecting
              ? [AppColors.success, AppColors.success.withOpacity(0.7)]
              : [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (provider.isDetecting ? AppColors.success : AppColors.primary)
                    .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            provider.isDetecting ? Icons.radar : Icons.sensors,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            provider.isDetecting ? 'Detection Active' : 'Detection Inactive',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.isDetecting
                ? 'Monitoring road conditions...'
                : 'Start detection to help improve road safety',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Detection count
          if (provider.isDetecting || provider.detectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.detectedCount} Pothole${provider.detectedCount == 1 ? "" : "s"} Detected',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Toggle Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleDetection,
              icon: Icon(provider.isDetecting ? Icons.stop : Icons.play_arrow),
              label: Text(
                provider.isDetecting ? 'Stop Detection' : 'Start Detection',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    provider.isDetecting ? AppColors.danger : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionReviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Review',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review locally stored candidate events on an OpenStreetMap view and label them.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DetectionReviewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open Detection Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'How It Works',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.sensors,
            'Accelerometer & Gyroscope',
            'Detects sudden jolts and vehicle movements',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.location_on,
            'GPS Location',
            'Records exact pothole coordinates',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.speed,
            'Speed Detection',
            'Only detects while moving (>7 km/h)',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.timeline,
            'Threshold-Based Detection',
            'Uses accelerometer + gyroscope thresholds (no ML yet)',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(PotholeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Your Contribution',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  '${provider.detectedCount}',
                  'Potholes\nDetected',
                  Icons.warning_amber,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  '${provider.detectedCount * 5}',
                  'Points\nEarned',
                  Icons.star,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Tips for Best Results',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Keep your phone steady (avoid holding)'),
          _buildTipItem('Drive at normal speeds (10-60 km/h)'),
          _buildTipItem('Mount phone on dashboard if possible'),
          _buildTipItem('Enable location for accurate detection'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
