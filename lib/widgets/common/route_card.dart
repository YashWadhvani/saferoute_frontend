// // lib/widgets/common/route_card.dart
// // ignore_for_file: unused_element

// import 'package:flutter/material.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/theme/app_text_styles.dart';
// import '../../models/route_model.dart';

// class RouteCard extends StatelessWidget {
//   final RouteData route;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final VoidCallback onStart;

//   const RouteCard({
//     super.key,
//     required this.route,
//     required this.isSelected,
//     required this.onTap,
//     required this.onStart,
//   });

//   Color _getScoreColor() {
//     if (route.safetyScore >= 7.5) return AppColors.success;
//     if (route.safetyScore >= 5) return AppColors.warning;
//     return AppColors.danger;
//   }

//   Color _getColorFromHex(String hex) {
//     hex = hex.replaceFirst('#', '');
//     return Color(int.parse('FF$hex', radix: 16));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primary.withAlpha((0.08 * 255).round())
//               : Colors.white,
//           border: Border.all(
//             color: isSelected ? AppColors.primary : AppColors.outline,
//             width: isSelected ? 2 : 1,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: AppColors.primary.withAlpha((0.2 * 255).round()),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   ),
//                 ]
//               : [
//                   BoxShadow(
//                     color: Colors.black.withAlpha((0.05 * 255).round()),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Route ${route.id.hashCode % 10}',
//                         style: AppTextStyles.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             size: 14,
//                             color: AppColors.onSurfaceVariant,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(route.distance, style: AppTextStyles.labelSmall),
//                           const SizedBox(width: 16),
//                           Icon(
//                             Icons.schedule,
//                             size: 14,
//                             color: AppColors.onSurfaceVariant,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(route.duration, style: AppTextStyles.labelSmall),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _getScoreColor().withAlpha((0.1 * 255).round()),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         route.safetyScore.toStringAsFixed(1),
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 18,
//                           color: _getScoreColor(),
//                         ),
//                       ),
//                       Text(
//                         'Safe',
//                         style: TextStyle(
//                           fontSize: 9,
//                           color: _getScoreColor(),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: route.safetyScore / 10,
//                 backgroundColor:
//                     AppColors.outline.withAlpha((0.3 * 255).round()),
//                 valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
//                 minHeight: 5,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 if (route.tags.contains('safest'))
//                   _buildTag('⭐ Safest', AppColors.success),
//                 if (route.tags.contains('fastest'))
//                   _buildTag('⚡ Fastest', AppColors.info),
//                 if (route.tags.contains('shortest'))
//                   _buildTag('📍 Shortest', AppColors.warning),
//               ],
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: onStart,
//                 icon: const Icon(Icons.navigation),
//                 label: Text(
//                   isSelected ? 'Stop Navigation' : 'Start Navigation',
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor:
//                       isSelected ? AppColors.danger : AppColors.primary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTag(String label, Color color) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: Chip(
//         label: Text(label, style: const TextStyle(fontSize: 11)),
//         backgroundColor: color.withAlpha((0.1 * 255).round()),
//         labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
//         side: BorderSide(color: color.withAlpha((0.3 * 255).round())),
//       ),
//     );
//   }
// }

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

  Color _getColorFromHex(String hex) {
    // Handle named colors first
    final lowerHex = hex.toLowerCase().trim();
    switch (lowerHex) {
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
      case 'gray':
      case 'grey':
        return Colors.grey;
    }

    // Handle hex colors
    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) {
      try {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } catch (e) {
        return AppColors.primary;
      }
    }

    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withAlpha((0.08 * 255).round()),
                    AppColors.primaryLight.withAlpha((0.04 * 255).round()),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((0.25 * 255).round()),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.06 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Route name and Safety Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Route indicator with color
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorFromHex(route.color),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getColorFromHex(route.color)
                                  .withAlpha((0.4 * 255).round()),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Route ${route.id.hashCode.abs() % 10 + 1}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Safety Score Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scoreColor.withAlpha((0.15 * 255).round()),
                          scoreColor.withAlpha((0.08 * 255).round()),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scoreColor.withAlpha((0.3 * 255).round()),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 16,
                          color: scoreColor,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.safetyScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: scoreColor,
                                height: 1,
                              ),
                            ),
                            Text(
                              'Safety',
                              style: TextStyle(
                                fontSize: 9,
                                color: scoreColor,
                                fontWeight: FontWeight.w600,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Distance and Duration Row
              Row(
                children: [
                  Icon(
                    Icons.straighten,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    route.distance,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    route.duration,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
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
                      AppColors.outline.withAlpha((0.25 * 255).round()),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 6,
                ),
              ),

              // Tags Row
              if (route.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (route.tags.contains('safest'))
                      _buildTag('⭐ Safest', AppColors.success),
                    if (route.tags.contains('fastest'))
                      _buildTag('⚡ Fastest', AppColors.info),
                    if (route.tags.contains('shortest'))
                      _buildTag('📍 Shortest', AppColors.warning),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: Icon(
                    isSelected ? Icons.navigation : Icons.route,
                    size: 20,
                  ),
                  label: Text(
                    isSelected ? 'Start Navigation' : 'Select Route',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? AppColors.primary : Colors.white,
                    foregroundColor:
                        isSelected ? Colors.white : AppColors.primary,
                    elevation: isSelected ? 4 : 0,
                    side: isSelected
                        ? null
                        : const BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha((0.4 * 255).round()),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
