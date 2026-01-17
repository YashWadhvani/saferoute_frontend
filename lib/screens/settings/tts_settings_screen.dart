// lib/screens/settings/tts_settings_screen.dart
// TTS configuration screen with language selection and speech rate control

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../state/tts_settings.dart';

class TtsSettingsScreen extends StatelessWidget {
  const TtsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        centerTitle: true,
      ),
      body: Consumer<TtsSettings>(
        builder: (context, settings, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.record_voice_over,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Navigation Voice',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize turn-by-turn instructions',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Language Selection
                Text(
                  'Language',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildLanguageTile(
                        context: context,
                        settings: settings,
                        language: 'en-US',
                        title: 'English',
                        subtitle: 'Turn left in 200 meters',
                        icon: '🇺🇸',
                      ),
                      Divider(height: 1, color: AppColors.outline),
                      _buildLanguageTile(
                        context: context,
                        settings: settings,
                        language: 'hi-IN',
                        title: 'हिन्दी (Hindi)',
                        subtitle: 'बाएं मुड़ें 200 मीटर में',
                        icon: '🇮🇳',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Speech Rate
                Text(
                  'Speech Speed',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speed',
                            style: AppTextStyles.bodyLarge,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              settings.rate.toStringAsFixed(2),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 20),
                          Expanded(
                            child: Slider(
                              value: settings.rate,
                              min: 0.2,
                              max: 1.0,
                              divisions: 8,
                              label: settings.rate.toStringAsFixed(2),
                              onChanged: (value) {
                                settings.setRate(value);
                              },
                            ),
                          ),
                          const Icon(Icons.fast_forward, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Slower',
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            'Faster',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Preview Section
                Text(
                  'Preview',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.info.withOpacity(0.1),
                        AppColors.info.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How it sounds',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings.language == 'hi-IN'
                            ? 'बाएं मुड़ें 500 मीटर में'
                            : 'Turn left in 500 meters',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.language == 'hi-IN'
                            ? 'दाएं मुड़ें 200 मीटर में'
                            : 'Turn right in 200 meters',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.language == 'hi-IN'
                            ? 'अब सीधे जाएँ'
                            : 'Now continue straight',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voice settings apply to turn-by-turn navigation announcements',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required TtsSettings settings,
    required String language,
    required String title,
    required String subtitle,
    required String icon,
  }) {
    final isSelected = settings.language == language;

    return ListTile(
      leading: Text(
        icon,
        style: const TextStyle(fontSize: 28),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(
          color: isSelected ? AppColors.primary : AppColors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall,
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: AppColors.primary,
            )
          : Icon(
              Icons.circle_outlined,
              color: AppColors.onSurfaceVariant,
            ),
      onTap: () {
        settings.setLanguage(language);
      },
    );
  }
}
