import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../services/sms_parser_service.dart';
import 'onboarding/splash_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showResetConfirmationDialog(BuildContext context, WidgetRef ref, String lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppTranslations.getText('reset_confirm_title', lang)),
          content: Text(AppTranslations.getText('factory_reset_desc', lang)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTranslations.getText('cancel', lang))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text(AppTranslations.getText('delete', lang))),
          ],
        );
      },
    );

    if (confirmed == true) {
      // 1. SharedPreferences (Hard Drive / Storage) සම්පූර්ණයෙන්ම මකා දැමීම
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Database එකේ ඇති සියලුම Tables 100% ක් හිස් කිරීම
      final db = ref.read(appDatabaseProvider);
      for (final table in db.allTables) {
        await db.delete(table).go();
      }

      // 3. [නව වෙනස] RAM එකේ (Riverpod) තියෙන Settings ටික බලහත්කාරයෙන් Reset කිරීම
      ref.invalidate(themeProvider);
      ref.invalidate(languageProvider);
      ref.invalidate(appLockProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factory Reset Successful. Restarting...')));

        // 4. App එක මුල සිට ආරම්භ කිරීම
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SplashScreen()),
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLanguage) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('English'); Navigator.pop(context); }),
                ListTile(title: const Text('සිංහල', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('සිංහල'); Navigator.pop(context); }),
                ListTile(title: const Text('தமிழ்', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { ref.read(languageProvider.notifier).setLanguage('தமிழ்'); Navigator.pop(context); }),
              ],
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isAppLockEnabled = ref.watch(appLockProvider);
    final currentLang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppTranslations.getText('settings', currentLang))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppTranslations.getText('preferences', currentLang), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Card(
            child: Column(
              children: [
                ListTile(leading: const Icon(Icons.language), title: Text(AppTranslations.getText('language', currentLang)), subtitle: Text(currentLang), onTap: () => _showLanguagePicker(context, ref, currentLang)),
                const Divider(),
                RadioListTile<ThemeMode>(title: Text(AppTranslations.getText('system_default', currentLang)), value: ThemeMode.system, groupValue: currentTheme, onChanged: (v) => ref.read(themeProvider.notifier).setTheme(v!)),
                RadioListTile<ThemeMode>(title: Text(AppTranslations.getText('light_mode', currentLang)), value: ThemeMode.light, groupValue: currentTheme, onChanged: (v) => ref.read(themeProvider.notifier).setTheme(v!)),
                RadioListTile<ThemeMode>(title: Text(AppTranslations.getText('dark_mode', currentLang)), value: ThemeMode.dark, groupValue: currentTheme, onChanged: (v) => ref.read(themeProvider.notifier).setTheme(v!)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(AppTranslations.getText('security_data', currentLang), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Card(
            child: Column(
              children: [
                SwitchListTile(title: Text(AppTranslations.getText('enable_app_lock', currentLang)), value: isAppLockEnabled, onChanged: (v) => ref.read(appLockProvider.notifier).setLock(v)),
                const Divider(),

                ListTile(
                    leading: const Icon(Icons.sms),
                    title: Text(AppTranslations.getText('sync_sms', currentLang)),
                    subtitle: Text(AppTranslations.getText('sync_sms_desc', currentLang)),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing background SMS...')));

                      final prefs = await SharedPreferences.getInstance();
                      final selectedBanks = prefs.getStringList('selectedBanks') ?? [];
                      await SmsParserService(ref.read(appDatabaseProvider)).syncRecentBankSms(selectedBanks);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS Sync Completed!')));
                      }
                    }
                ),

                const Divider(),
                ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: Text(AppTranslations.getText('factory_reset', currentLang), style: const TextStyle(color: Colors.red)), subtitle: Text(AppTranslations.getText('factory_reset_desc', currentLang)), onTap: () => _showResetConfirmationDialog(context, ref, currentLang)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}