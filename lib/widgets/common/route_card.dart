// lib/widgets/common/route_card.dart
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/route_model.dart';

class RouteCard extends StatelessWidget {
  final RouteData route;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const RouteCard({
    super.key,
    required this.route,
    required this.isSelected,
    required this.onTap,
    required this.onStart,
  });

  Color _getScoreColor() {
    if (route.safetyScore >= 7.5) return AppColors.success;
    if (route.safetyScore >= 5) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getColorFromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha((0.08 * 255).round())
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((0.2 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route ${route.id.hashCode % 10}',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(route.distance, style: AppTextStyles.labelSmall),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(route.duration, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScoreColor().withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        route.safetyScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _getScoreColor(),
                        ),
                      ),
                      Text(
                        'Safe',
                        style: TextStyle(
                          fontSize: 9,
                          color: _getScoreColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: route.safetyScore / 10,
                backgroundColor:
                    AppColors.outline.withAlpha((0.3 * 255).round()),
                valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (route.tags.contains('safest'))
                  _buildTag('⭐ Safest', AppColors.success),
                if (route.tags.contains('fastest'))
                  _buildTag('⚡ Fastest', AppColors.info),
                if (route.tags.contains('shortest'))
                  _buildTag('📍 Shortest', AppColors.warning),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.navigation),
                label: Text(
                  isSelected ? 'Stop Navigation' : 'Start Navigation',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: color.withAlpha((0.1 * 255).round()),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        side: BorderSide(color: color.withAlpha((0.3 * 255).round())),
      ),
    );
  }
}
