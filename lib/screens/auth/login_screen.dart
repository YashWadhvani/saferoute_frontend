// lib/screens/auth/login_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'package:animations/animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late PageController _pageController;
  final identifierController = TextEditingController();
  final otpController = TextEditingController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    identifierController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (identifierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email or phone')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.sendOTP(identifierController.text.trim());

    if (!mounted) return;

    if (authProvider.error == null) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.error!)));
    }
  }

  void _verifyOTP() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter OTP')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(
      identifierController.text.trim(),
      otpController.text.trim(),
    );

    if (mounted && success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Verification failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withAlpha((0.1 * 255).round()),
                  AppColors.primaryLight.withAlpha((0.05 * 255).round()),
                ],
              ),
            ),
          ),

          // Page View
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Page 1: Welcome
              _buildWelcomePage(),

              // Page 2: Phone Input
              _buildPhonePage(),

              // Page 3: OTP Input
              _buildOTPPage(),
            ],
          ),

          // Back Button
          Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
            left: 16,
            child: _currentPage > 0
                ? FloatingActionButton.small(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    backgroundColor: AppColors.background,
                    child: const Icon(Icons.arrow_back),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24) +
            EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
        child: Column(
          children: [
            // Animated Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha((0.3 * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),

            // Title
            Text(
              'Welcome to SafeRoute',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'Your safe navigation companion for every journey',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),

            // Features
            _buildFeature(
              icon: Icons.route,
              title: 'Smart Routes',
              subtitle: 'Compare routes with real-time safety scores',
            ),
            const SizedBox(height: 20),
            _buildFeature(
              icon: Icons.emergency,
              title: 'Emergency SOS',
              subtitle: 'One-tap emergency alerts to your contacts',
            ),
            const SizedBox(height: 20),
            _buildFeature(
              icon: Icons.location_on,
              title: 'Location Safety',
              subtitle: 'Get safety data for any area',
            ),
            const SizedBox(height: 60),

            // Get Started Button
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Get Started',
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutCubic,
                ),
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhonePage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24) +
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
            child: Column(
              children: [
                // Illustration
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: const Icon(
                    Icons.phone_android,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Enter Your Contact',
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'We\'ll send you an OTP to verify your identity',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Email/Phone TextField
                AppTextField(
                  controller: identifierController,
                  label: 'Email or Phone',
                  hint: '+91 98765 43210 or email@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 40),

                // Send OTP Button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: authProvider.isLoading ? 'Sending...' : 'Send OTP',
                    onPressed: authProvider.isLoading ? null : _sendOTP,
                    isLoading: authProvider.isLoading,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOTPPage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24) +
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 60),
            child: Column(
              children: [
                // Illustration
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Verify OTP',
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Enter the 6-digit code sent to\n${identifierController.text}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // OTP TextField
                AppTextField(
                  controller: otpController,
                  label: 'OTP Code',
                  hint: '000000',
                  prefixIcon: Icons.security,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 40),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: authProvider.isLoading
                        ? 'Verifying...'
                        : 'Verify & Continue',
                    onPressed: authProvider.isLoading ? null : _verifyOTP,
                    isLoading: authProvider.isLoading,
                  ),
                ),
                const SizedBox(height: 20),

                // Resend OTP Button
                TextButton(
                  onPressed: _sendOTP,
                  child: Text(
                    'Didn\'t receive OTP? Resend',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
