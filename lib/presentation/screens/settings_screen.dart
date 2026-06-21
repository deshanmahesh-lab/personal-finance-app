import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/database_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../services/sms_parser_service.dart';
// [නව වෙනස] Backup Service එක Import කිරීම
import '../../services/google_drive_backup_service.dart';
import 'onboarding/splash_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // [නව වෙනස] Backup/Restore වන විට පෙන්වන Loading තිරය
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false, // Back බොත්තම එබීම වැළැක්වීම
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 24),
                Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        );
      },
    );
  }

  // [නව වෙනස] Backup ක්‍රියාවලිය
  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context, 'Backing up to Google Drive...');
    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.backupDatabase();

      if (context.mounted) {
        Navigator.pop(context); // Loading එක වැසීම
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Backup Successful!' : 'Backup Cancelled.'),
            backgroundColor: success ? Colors.green.shade600 : Colors.orange.shade600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600));
      }
    }
  }

  // [නව වෙනස] Restore ක්‍රියාවලිය
  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context, 'Restoring from Google Drive...');
    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.restoreDatabase();

      if (context.mounted) {
        Navigator.pop(context); // Loading එක වැසීම

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Restore Successful! Restarting app...'), backgroundColor: Colors.green.shade600),
          );

          // Restore කළ පසු අලුත් Database එක Load වීමට App එක Restart කිරීම
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore Cancelled.')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade600));
      }
    }
  }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final db = ref.read(appDatabaseProvider);
      for (final table in db.allTables) {
        await db.delete(table).go();
      }

      ref.invalidate(themeProvider);
      ref.invalidate(languageProvider);
      ref.invalidate(appLockProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factory Reset Successful. Restarting...')));

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

          // [නව වෙනස] Cloud Backup කොටස
          const Text('Cloud Backup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                  title: const Text('Backup to Google Drive'),
                  subtitle: const Text('Save your data securely to the cloud'),
                  onTap: () => _handleBackup(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cloud_download_rounded, color: Colors.green),
                  title: const Text('Restore from Google Drive'),
                  subtitle: const Text('Recover your previous data'),
                  onTap: () => _handleRestore(context, ref),
                ),
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