import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Riverpod 3.0+ සඳහා නවීන Notifier Class එක
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    // App එක ආරම්භයේදීම Save කර ඇති Theme එක Load කිරීමට උපදෙස් ලබා දෙයි
    _loadTheme();
    // ආරම්භක අගය ලෙස System Theme එක ලබා දෙයි
    return ThemeMode.system;
  }

  // දුරකථනයේ Save කර ඇති Theme එක කියවීම
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? 0;
    state = ThemeMode.values[index]; // State එක යාවත්කාලීන කිරීම
  }

  // අලුත් Theme එකක් තෝරාගත් විට එය Update කර Save කිරීම
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}

// නවීන NotifierProvider එක
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});