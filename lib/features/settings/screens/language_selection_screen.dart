import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/settings_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Widget _buildLanguageButton(BuildContext context, String title, String flag, Locale locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      child: InkWell(
        onTap: () async {
          // Si Français (langue native), on démarre direct
          if (locale.languageCode == 'fr') {
            await context.setLocale(locale);
            if (context.mounted) {
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              await settings.setHasSelectedLanguage(true);
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            }
          } else {
            // Sinon, on va vers le traducteur IA d'Onboarding
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/onboarding-translator',
                arguments: {'code': locale.languageCode, 'name': title},
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: TdcColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TdcColors.border, width: 1),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  color: TdcColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: TdcColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdcColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo
                Image.asset('assets/logo.png', width: 120, height: 120),
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  tr('language.select_title'),
                  style: const TextStyle(
                    color: TdcColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your preferred language',
                  style: TextStyle(
                    color: TdcColors.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Language Options
                _buildLanguageButton(context, 'Français', '🇫🇷', const Locale('fr')),
                _buildLanguageButton(context, 'English', '🇬🇧', const Locale('en')),
                _buildLanguageButton(context, 'Español', '🇪🇸', const Locale('es')),
                _buildLanguageButton(context, 'Deutsch', '🇩🇪', const Locale('de')),
                _buildLanguageButton(context, 'العربية', '🇸🇦', const Locale('ar')),
                _buildLanguageButton(context, '中文', '🇨🇳', const Locale('zh')),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
