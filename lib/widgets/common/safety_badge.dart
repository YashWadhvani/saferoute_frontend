// lib/widgets/common/safety_badge.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SafetyBadge extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;

  const SafetyBadge({
    super.key,
    required this.score,
    this.size = 80,
    this.showLabel = true,
  });

  Color _getColor() {
    if (score >= 7.5) return AppColors.success;
    if (score >= 5) return AppColors.warning;
    return AppColors.danger;
  }

  String _getLabel() {
    if (score >= 7.5) return 'Safe';
    if (score >= 5) return 'Caution';
    return 'Unsafe';
  }

  String _getEmoji() {
    if (score >= 7.5) return '😊';
    if (score >= 5) return '⚠️';
    return '🚨';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withAlpha((0.15 * 255).round()),
                  color.withAlpha((0.05 * 255).round())
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha((0.2 * 255).round()),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_getEmoji(), style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (showLabel)
                Text(
                  _getLabel(),
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
