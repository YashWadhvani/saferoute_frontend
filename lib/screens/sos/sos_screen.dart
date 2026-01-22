// lib/screens/sos/sos_screen.dart
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
  Set<String> _selectedContactIds = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    final userProvider = context.read<UserProvider>();
    userProvider.fetchContacts();

    // Pre-select all contacts by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedContactIds = userProvider.contacts.map((c) => c.id).toSet();
      });
    });
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
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.danger),
            const SizedBox(width: 12),
            const Text('Emergency SOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildActionItem(Icons.sms, 'Send SMS to selected contacts'),
            _buildActionItem(Icons.location_on, 'Share your current location'),
            _buildActionItem(Icons.phone, 'Enable emergency call back'),
            const SizedBox(height: 16),
            Text(
              'Selected: ${_selectedContactIds.length} contact(s)',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Send SOS Alert'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
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
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'SOS sent! ${_selectedContactIds.length} contact(s) notified',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(sosProvider.error ?? 'SOS failed'),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
        ),
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
            const SizedBox(height: 20),

            // Pulsing SOS Button
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(
                      parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: GestureDetector(
                  onTap: _selectedContactIds.isEmpty
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one contact',
                              ),
                            ),
                          );
                        }
                      : _triggerSOS,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _selectedContactIds.isEmpty
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                            )
                          : AppColors.dangerGradient,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedContactIds.isEmpty
                              ? Colors.grey.withAlpha((0.3 * 255).round())
                              : AppColors.danger.withAlpha((0.4 * 255).round()),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emergency_share,
                          size: 70,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PRESS FOR\nEMERGENCY',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              'Emergency Alert',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Select contacts to notify in case of emergency',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: AppTextStyles.titleMedium,
                        ),
                        if (contacts.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedContactIds.length ==
                                    contacts.length) {
                                  _selectedContactIds.clear();
                                } else {
                                  _selectedContactIds =
                                      contacts.map((c) => c.id).toSet();
                                }
                              });
                            },
                            child: Text(
                              _selectedContactIds.length == contacts.length
                                  ? 'Deselect All'
                                  : 'Select All',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (contacts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              AppColors.warning.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning
                                .withAlpha((0.3 * 255).round()),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add_alt,
                              size: 40,
                              color: AppColors.warning,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Emergency Contacts',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add emergency contacts in your profile to use SOS feature',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/profile');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Contacts'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...contacts.map((contact) {
                        final isSelected =
                            _selectedContactIds.contains(contact.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedContactIds.remove(contact.id);
                                } else {
                                  _selectedContactIds.add(contact.id);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                        .withAlpha((0.1 * 255).round())
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.primary
                                              .withAlpha((0.1 * 255).round()),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style:
                                              AppTextStyles.labelLarge.copyWith(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          contact.phone,
                                          style: AppTextStyles.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedContactIds.add(contact.id);
                                        } else {
                                          _selectedContactIds
                                              .remove(contact.id);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How it works',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selected contacts will receive an SMS with your current location and a call-back number.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.info),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
