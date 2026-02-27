// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/route_service.dart';
import '../routes/route_comparison_screen.dart';
import '../sos/sos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RouteService _routeService = RouteService();
  LatLng? currentLocation;
  bool isLoadingLocation = false;
  List<Map<String, dynamic>> recentRoutes =
      []; // Will be populated from search history

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.fetchProfile();
    await _loadRecentRoutes();
  }

  Future<void> _loadRecentRoutes() async {
    final res = await _routeService.getRecentRoutes();
    if (!mounted) return;
    setState(() {
      recentRoutes = res.isSuccess ? (res.data ?? []) : [];
    });
  }

  bool _looksLikeCoordinates(String value) {
    final v = value.trim();
    final re = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    return re.hasMatch(v);
  }

  String _normalizePlace(String value, {required bool isOrigin}) {
    if (value.trim().isEmpty)
      return isOrigin ? 'Current Location' : 'Destination';
    if (_looksLikeCoordinates(value)) {
      return isOrigin ? 'Current Location' : 'Pinned Destination';
    }
    return value;
  }

  double _parseDistanceKm(String distanceText) {
    final text = distanceText.trim().toLowerCase();
    final numMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(text);
    if (numMatch == null) return 0;
    final raw = double.tryParse(numMatch.group(1)!) ?? 0;
    if (text.contains('km')) return raw;
    if (text.contains('m')) return raw / 1000;
    return raw;
  }

  double _parseSafety(dynamic safety) {
    if (safety is num) return safety.toDouble();
    if (safety is String) return double.tryParse(safety) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        (MediaQuery.of(context).size.height * 0.12).clamp(80.0, 140.0);
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
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // KPIs Section
                  _buildKPIsSection(),

                  // Quick Actions
                  _buildActionsSection(),

                  // Recent Routes
                  _buildRoutesSection(),
                ],
              ),
            ),
          ),

          // Custom positioned FABs
          if (currentLocation != null) ...[
            // Find Route FAB - Bottom Left
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RouteComparisonScreen(
                        currentLocation: currentLocation!,
                      ),
                    ),
                  );
                  await _loadRecentRoutes();
                },
                heroTag: 'fab_find_route',
                label: const Text('Find Route'),
                icon: const Icon(Icons.directions),
                backgroundColor: AppColors.primary,
              ),
            ),

            // SOS FAB - Bottom Right
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
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
                child: const Icon(Icons.emergency_share, size: 28),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final userName = userProvider.user?.name ?? 'User';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome Back,', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: AppTextStyles.displayMedium.copyWith(fontSize: 28),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
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
                    value: 'pothole_detection',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber),
                        SizedBox(width: 8),
                        Text('Pothole Detection'),
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
              } else if (value == 'pothole_detection') {
                Navigator.of(context).pushNamed('/pothole-detection');
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
    );
  }

  Widget _buildKPIsSection() {
    final totalRoutes = recentRoutes.length;
    final avgSafety = totalRoutes == 0
        ? 0.0
        : recentRoutes
                .map((r) => _parseSafety(r['safety']))
                .fold<double>(0, (a, b) => a + b) /
            totalRoutes;
    final totalKm = recentRoutes
        .map((r) => _parseDistanceKm((r['distance'] ?? '').toString()))
        .fold<double>(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Statistics', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.route,
                  title: 'Routes',
                  value: '$totalRoutes',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.shield_outlined,
                  title: 'Safety',
                  value: avgSafety.toStringAsFixed(1),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timeline,
                  title: 'Km',
                  value: totalKm.toStringAsFixed(1),
                  color: AppColors.info,
                ),
              ),
            ],
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
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActionButton(
                icon: Icons.map_outlined,
                label: 'Heatmap',
                onTap: () => Navigator.of(context).pushNamed('/heatmap'),
                color: AppColors.warning,
              ),
              _buildActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Reports',
                onTap: () => Navigator.of(context).pushNamed('/reports'),
                color: AppColors.danger,
              ),
              _buildActionButton(
                icon: Icons.people,
                label: 'Contacts',
                onTap: () => Navigator.of(context).pushNamed('/profile'),
                color: AppColors.info,
              ),
              _buildActionButton(
                icon: Icons.sensors,
                label: 'Potholes',
                onTap: () =>
                    Navigator.of(context).pushNamed('/pothole-detection'),
                color: AppColors.primary,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: AppTextStyles.labelSmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Searches', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          recentRoutes.isEmpty
              ? _buildEmptyRoutesPlaceholder()
              : _buildRecentRoutesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyRoutesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: Icon(
              Icons.search_off,
              size: 50,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent searches',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by finding a safe route',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRoutesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentRoutes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final route = recentRoutes[index];
        final rawOrigin = (route['origin'] ?? 'Unknown').toString();
        final rawDestination = (route['destination'] ?? 'Unknown').toString();
        return _buildRouteItem(
          origin: _normalizePlace(rawOrigin, isOrigin: true),
          destination: _normalizePlace(rawDestination, isOrigin: false),
          distance: route['distance'] ?? '0 km',
          duration: route['duration'] ?? '0 mins',
          safety: _parseSafety(route['safety']),
          onTap: () {
            // TODO: Start navigation for this route
            if (currentLocation != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RouteComparisonScreen(
                    currentLocation: currentLocation!,
                    // TODO: Pass saved destination
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildRouteItem({
    required String origin,
    required String destination,
    required String distance,
    required String duration,
    required double safety,
    required VoidCallback onTap,
  }) {
    Color safetyColor = safety >= 7.5
        ? AppColors.success
        : safety >= 5
            ? AppColors.warning
            : AppColors.danger;

    return GestureDetector(
      onTap: onTap,
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
                  Text(
                    '$origin → $destination',
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                safety.toStringAsFixed(1),
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
