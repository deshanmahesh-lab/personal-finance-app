import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/account_repository_provider.dart';
import '../providers/app_lock_provider.dart'; // [නව වෙනස]

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showResetConfirmationDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 12),
              const Text('Reset All Data?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Are you absolutely sure you want to delete all your transactions?\n\nThis action cannot be undone. Your wallets and categories will remain, but all balances will be reset to Rs. 0.', style: TextStyle(fontSize: 15, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Yes, Reset Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(accountRepositoryProvider).resetAllData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Row(children: [Icon(Icons.check_circle_outline, color: Colors.white), SizedBox(width: 12), Expanded(child: Text('All data has been successfully reset.', style: TextStyle(fontWeight: FontWeight.bold)))]), backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
        }
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resetting data: $e'), backgroundColor: Colors.red.shade600));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isAppLockEnabled = ref.watch(appLockProvider); // [නව වෙනස]

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // --- SECTION 1: APPEARANCE ---
            const Text('Appearance (පෙනුම)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('දුරකථනයේ පවතින Theme එකට ස්වයංක්‍රීයව හැඩගැසේ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)), value: ThemeMode.system, groupValue: currentTheme, activeColor: Colors.blue.shade600, onChanged: (value) { if (value != null) ref.read(themeProvider.notifier).setTheme(value); }),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.1)),
                    RadioListTile<ThemeMode>(title: const Text('Light Mode', style: TextStyle(fontWeight: FontWeight.w600)), value: ThemeMode.light, groupValue: currentTheme, activeColor: Colors.blue.shade600, onChanged: (value) { if (value != null) ref.read(themeProvider.notifier).setTheme(value); }),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.1)),
                    RadioListTile<ThemeMode>(title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)), value: ThemeMode.dark, groupValue: currentTheme, activeColor: Colors.blue.shade600, onChanged: (value) { if (value != null) ref.read(themeProvider.notifier).setTheme(value); }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- SECTION 2: SECURITY & DATA ---
            const Text('Security & Data (ආරක්ෂාව සහ දත්ත)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // [නව වෙනස] App Lock Toggle Button
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      secondary: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.fingerprint_rounded, color: Colors.blue.shade600)),
                      title: const Text('App Lock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Require Fingerprint or PIN to open', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      value: isAppLockEnabled,
                      activeColor: Colors.blue.shade600,
                      onChanged: (bool value) {
                        ref.read(appLockProvider.notifier).setLock(value);
                      },
                    ),
                    Divider(height: 1, indent: 64, endIndent: 20, color: Colors.grey.withOpacity(0.1)),

                    // Factory Reset Button
                    InkWell(
                      onTap: () => _showResetConfirmationDialog(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade600)),
                            const SizedBox(width: 16),
                            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Factory Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Delete all transactions & reset balances', style: TextStyle(fontSize: 13, color: Colors.grey))])),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}