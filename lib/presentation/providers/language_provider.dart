import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_prefs_provider.dart'; // [නව වෙනස]

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('selectedLanguage') ?? 'English';
  }

  void setLanguage(String lang) {
    state = lang;
    ref.read(sharedPreferencesProvider).setString('selectedLanguage', lang);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);