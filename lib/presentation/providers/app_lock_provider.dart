import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(() {
  return AppLockNotifier();
});

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadState();
    return false; // [FIX] Default අගය false
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isAppLockEnabled') ?? false; // [FIX] Default අගය false
  }

  Future<void> setLock(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppLockEnabled', value);
  }
}