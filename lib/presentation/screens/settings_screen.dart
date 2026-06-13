import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // දැනට තෝරාගෙන ඇති Theme එක ලබා ගැනීම
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Text(
              'Appearance (පෙනුම)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),

          // System Default Button
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('දුරකථනයේ පවතින Theme එකට ස්වයංක්‍රීයව හැඩගැසේ'),
            value: ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) ref.read(themeProvider.notifier).setTheme(value);
            },
          ),

          // Light Mode Button
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) ref.read(themeProvider.notifier).setTheme(value);
            },
          ),

          // Dark Mode Button
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) ref.read(themeProvider.notifier).setTheme(value);
            },
          ),
        ],
      ),
    );
  }
}