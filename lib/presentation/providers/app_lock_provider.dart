import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart'; // [නව වෙනස]

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    // [නව වෙනස] UI එක හැදෙන්න කලින්ම නිවැරදි අගය ලබා දෙයි
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('app_lock_enabled') ?? false;
  }

  void setLock(bool isEnabled) {
    state = isEnabled;
    ref.read(sharedPreferencesProvider).setBool('app_lock_enabled', isEnabled);
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, bool>(AppLockNotifier.new);