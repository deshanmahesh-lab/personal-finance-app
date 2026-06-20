import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'bank_setup_screen.dart';

class ThemeConfigurationScreen extends ConsumerStatefulWidget {
  const ThemeConfigurationScreen({super.key});

  @override
  ConsumerState<ThemeConfigurationScreen> createState() => _ThemeConfigurationScreenState();
}

class _ThemeConfigurationScreenState extends ConsumerState<ThemeConfigurationScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    final mainTitle = AppTranslations.getText('choose_theme', currentLanguage);
    final subTitle = AppTranslations.getText('choose_theme_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    final lightText = AppTranslations.getText('light_mode', currentLanguage);
    final darkText = AppTranslations.getText('dark_mode', currentLanguage);
    final systemText = AppTranslations.getText('system_default', currentLanguage);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 24), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ),
              const SizedBox(height: 24),

              Text(mainTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              Text(subTitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              _ThemeOptionCard(
                title: lightText,
                icon: Icons.light_mode,
                isSelected: _selectedTheme == ThemeMode.light,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.light);
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                },
              ),
              const SizedBox(height: 16),

              _ThemeOptionCard(
                title: darkText,
                icon: Icons.dark_mode,
                isSelected: _selectedTheme == ThemeMode.dark,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.dark);
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                },
              ),
              const SizedBox(height: 16),

              _ThemeOptionCard(
                title: systemText,
                icon: Icons.settings_system_daydream,
                isSelected: _selectedTheme == ThemeMode.system,
                onTap: () {
                  setState(() => _selectedTheme = ThemeMode.system);
                  ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BankSetupScreen()));
                  },
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                  child: Text(btnText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionCard({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Theme.of(context).primaryColor : null)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}