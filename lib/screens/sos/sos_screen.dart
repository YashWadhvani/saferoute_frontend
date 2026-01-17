// lib/screens/sos/sos_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/sos_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/gradient_button.dart';

class SOSScreen extends StatefulWidget {
  final LatLng currentLocation;

  const SOSScreen({required this.currentLocation, super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    context.read<UserProvider>().fetchContacts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will notify your emergency contacts with your location. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmSOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
  }

  void _confirmSOS() async {
    final sosProvider = context.read<SOSProvider>();
    final success = await sosProvider.triggerSOS(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SOS sent! Emergency contacts notified'),
          backgroundColor: AppColors.success,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sosProvider.error ?? 'SOS failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Pulsing SOS Button
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: GestureDetector(
                  onTap: _triggerSOS,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.dangerGradient,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.danger.withAlpha((0.4 * 255).round()),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency_share,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Emergency Mode',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Alert your emergency contacts immediately',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Contacts List
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final contacts = userProvider.contacts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contacts to be notified:',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (contacts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              AppColors.warning.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No emergency contacts. Please add contacts in profile.',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...contacts.map((contact) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary
                                        .withAlpha((0.1 * 255).round()),
                                  ),
                                  child: const Icon(Icons.person),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: AppTextStyles.labelLarge,
                                      ),
                                      Text(
                                        contact.phone,
                                        style: AppTextStyles.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle,
                                    color: AppColors.success),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withAlpha((0.3 * 255).round())),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your location will be shared with your emergency contacts via SMS/Call',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
