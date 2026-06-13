import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// [FIX] StateNotifierProvider වෙනුවට අලුත් NotifierProvider භාවිතා කිරීම
final appLockProvider = NotifierProvider<AppLockNotifier, bool>(() {
  return AppLockNotifier();
});

// [FIX] StateNotifier වෙනුවට අලුත් Notifier භාවිතා කිරීම
class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    // ආරම්භක අගය (Initial State) true ලෙස තබයි (Background එකෙන් Load වේ)
    _loadState();
    return true;
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences වලින් අගය ලබාගෙන State එක යාවත්කාලීන කරයි
    state = prefs.getBool('isAppLockEnabled') ?? true;
  }

  Future<void> setLock(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppLockEnabled', value);
  }
}