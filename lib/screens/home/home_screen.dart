// lib/screens/home/home_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/sos_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../routes/route_comparison_screen.dart';
import '../sos/sos_screen.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation;
  bool isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Default to Ahmedabad
      setState(() {
        currentLocation = const LatLng(23.0225, 72.5714);
      });
    } finally {
      setState(() => isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha((0.05 * 255).round()),
                  AppColors.primaryLight.withAlpha((0.02 * 255).round()),
                ],
              ),
            ),
          ),

          // Main Content
          Column(
            children: [
              // Header
              _buildHeader(),

              // Stats Cards
              _buildStatsSection(),

              // Quick Actions
              _buildActionsSection(),

              // Saved Routes / Recent
              _buildRoutesSection(),
            ],
          ),
        ],
      ),
      floatingActionButton: currentLocation != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RouteComparisonScreen(
                          currentLocation: currentLocation!,
                        ),
                      ),
                    );
                  },
                  heroTag: 'fab_find_route',
                  label: const Text('Find Safe Route'),
                  icon: const Icon(Icons.directions),
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  onPressed: () {
                    // SOSScreen is a Route, push it directly
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SOSScreen(currentLocation: currentLocation!),
                      ),
                    );
                  },
                  heroTag: 'fab_sos',
                  backgroundColor: AppColors.danger,
                  tooltip: 'Emergency SOS',
                  child: const Icon(Icons.emergency_share),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back! 👋', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'SafeRoute',
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 28),
                ),
              ],
            ),
            Row(
              children: [
                badges.Badge(
                  badgeContent: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: AppColors.danger,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final value = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person),
                              SizedBox(width: 8),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings),
                              SizedBox(width: 8),
                              Text('Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    if (!mounted) return;
                    if (value == 'logout') {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    } else if (value == 'profile') {
                      Navigator.of(context).pushNamed('/profile');
                    } else if (value == 'settings') {
                      Navigator.of(context).pushNamed('/settings');
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.route,
              title: 'Routes',
              value: '12',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.shield_outlined,
              title: 'Safety',
              value: '8.2',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.timeline,
              title: 'Km',
              value: '24',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headlineSmall),
          Text(title, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.map_outlined,
                  label: 'Heatmap',
                  onTap: () => Navigator.of(context).pushNamed('/heatmap'),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.warning_amber_rounded,
                  label: 'Reports',
                  onTap: () => Navigator.of(context).pushNamed('/reports'),
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.people,
                  label: 'Contacts',
                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).round()),
                blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Routes', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildRouteItem(
                    title: 'Home to Office',
                    distance: '8.5 km',
                    duration: '22 mins',
                    safety: 8.2,
                  ),
                  const SizedBox(height: 8),
                  _buildRouteItem(
                    title: 'Mall Route',
                    distance: '5.2 km',
                    duration: '14 mins',
                    safety: 7.5,
                  ),
                  const SizedBox(height: 8),
                  _buildRouteItem(
                    title: 'Hospital',
                    distance: '3.8 km',
                    duration: '12 mins',
                    safety: 9.1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem({
    required String title,
    required String distance,
    required String duration,
    required double safety,
  }) {
    Color safetyColor = safety >= 7.5
        ? AppColors.success
        : safety >= 5
            ? AppColors.warning
            : AppColors.danger;

    return GestureDetector(
      onTap: () {
        final origin = currentLocation ?? const LatLng(23.0225, 72.5714);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RouteComparisonScreen(currentLocation: origin),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(distance, style: AppTextStyles.labelSmall),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(duration, style: AppTextStyles.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: safetyColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$safety',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: safetyColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
