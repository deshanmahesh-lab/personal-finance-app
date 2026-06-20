import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_screen.dart';
import '../lock_screen.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;

  const InitializationScreen({super.key, required this.selectedBanks});

  @override
  ConsumerState<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen> {
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final currentLanguage = ref.read(languageProvider);

    setState(() => _currentStatus = AppTranslations.getText('scanning_inbox', currentLanguage));
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentStatus = AppTranslations.getText('extracting_tx', currentLanguage));
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentStatus = AppTranslations.getText('setting_wallets', currentLanguage));
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentStatus = AppTranslations.getText('saving_data', currentLanguage));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);
    await prefs.setStringList('selectedBanks', widget.selectedBanks);

    setState(() => _currentStatus = AppTranslations.getText('ready', currentLanguage));
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen(child: MainScreen())),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final pleaseWaitText = AppTranslations.getText('please_wait', currentLanguage);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
              const SizedBox(height: 32),
              Text(
                _currentStatus,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                pleaseWaitText,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}