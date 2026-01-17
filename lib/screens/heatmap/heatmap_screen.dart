// lib/screens/heatmap/heatmap_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap')),
      body: Center(
        child: Text('Heatmap coming soon', style: AppTextStyles.bodyLarge),
      ),
    );
  }
}
