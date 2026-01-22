// lib/widgets/common/route_card.dart
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

  String _getRouteName() {
    // Priority 1: Use tags to generate meaningful name
    if (route.tags.isNotEmpty) {
      final primaryTag = route.tags.first;
      switch (primaryTag.toLowerCase()) {
        case 'safest':
          return 'Safest Route';
        case 'fastest':
          return 'Fastest Route';
        case 'shortest':
          return 'Shortest Route';
        default:
          return primaryTag
              .split('_')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
      }
    }

    // Priority 2: Use safety score to categorize
    if (route.safetyScore >= 8.0) {
      return 'Highly Safe Route';
    } else if (route.safetyScore >= 6.5) {
      return 'Safe Route';
    } else if (route.safetyScore >= 5.0) {
      return 'Moderate Route';
    } else {
      return 'Alternative Route';
    }
  }

  String _getRouteDescription() {
    final parts = <String>[];

    // Add distance and duration
    if (route.distance.isNotEmpty && route.duration.isNotEmpty) {
      parts.add('${route.distance} • ${route.duration}');
    }

    // Add safety descriptor
    if (route.safetyScore >= 7.5) {
      parts.add('Well-lit areas');
    } else if (route.safetyScore < 5) {
      parts.add('Use caution');
    }

    return parts.join(' • ');
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
              ? AppColors.primary.withAlpha((0.15 * 255).round())
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((0.3 * 255).round()),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                      // Route Name
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _getRouteName(),
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tags
                          ...route.tags.take(2).map((tag) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _buildTagIcon(tag),
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Distance and Duration
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            route.distance,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            route.duration,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Safety Badge
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScoreColor().withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getScoreColor().withAlpha((0.3 * 255).round()),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        route.safetyScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _getScoreColor(),
                        ),
                      ),
                      Text(
                        'Safety',
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

            // Safety Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: route.safetyScore / 10,
                backgroundColor:
                    AppColors.outline.withAlpha((0.3 * 255).round()),
                valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 12),

            // Start Navigation Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: Icon(
                  isSelected ? Icons.navigation : Icons.play_arrow,
                  size: 20,
                ),
                label: Text(
                  isSelected ? 'Start Navigation' : 'Select & Navigate',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? AppColors.primary : AppColors.surface,
                  foregroundColor:
                      isSelected ? Colors.white : AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagIcon(String tag) {
    IconData icon;
    Color color;

    switch (tag.toLowerCase()) {
      case 'safest':
        icon = Icons.shield;
        color = AppColors.success;
        break;
      case 'fastest':
        icon = Icons.speed;
        color = AppColors.info;
        break;
      case 'shortest':
        icon = Icons.straighten;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.info;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 15,
        color: color,
      ),
    );
  }
}
