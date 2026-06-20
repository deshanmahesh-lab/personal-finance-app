import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift; // Database insert සඳහා අවශ්‍යයි
import '../main_screen.dart';
import '../lock_screen.dart';
import '../../providers/language_provider.dart';
import '../../providers/database_provider.dart';
import '../../../utils/app_translations.dart';
import '../../../data/datasources/app_database.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;
  final Map<String, double> initialBalances; // [නව වෙනස] අලුත් Parameter එක

  const InitializationScreen({
    super.key,
    required this.selectedBanks,
    required this.initialBalances,
  });

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
    final db = ref.read(appDatabaseProvider);

    setState(() => _currentStatus = AppTranslations.getText('setting_wallets', currentLanguage));

    // 1. Wallets නිර්මාණය කිරීම සහ Initial Balances ඇතුළත් කිරීම
    await _setupInitialWallets(db);

    setState(() => _currentStatus = AppTranslations.getText('saving_data', currentLanguage));

    // 2. SharedPreferences සැකසීම (Forward Tracking - අදින් පසු පමණක් SMS කියවීම)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);
    await prefs.setStringList('selectedBanks', widget.selectedBanks);
    // [ක්‍රමෝපාය] අද දවස "last_sms_sync_time" ලෙස සටහන් කිරීමෙන් පරණ SMS කියවීම වලක්වයි
    await prefs.setString('last_sms_sync_time', DateTime.now().toIso8601String());

    setState(() => _currentStatus = AppTranslations.getText('ready', currentLanguage));
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen(child: MainScreen())),
          (Route<dynamic> route) => false,
    );
  }

  // අලුත් Wallets DataBase එකට ඇතුලත් කිරීමේ Function එක
  Future<void> _setupInitialWallets(AppDatabase db) async {
    final accountDao = db.accountDao;

    // Cash Wallet
    if (widget.initialBalances.containsKey('cash')) {
      await accountDao.insertAccount(
          AccountsCompanion.insert(
            name: 'My Wallet',
            type: 'cash',
            initialBalance: drift.Value(widget.initialBalances['cash']!),
          )
      );
    }

    // Bank Wallets (නියම බැංකු නම් වලින්)
    final Map<String, String> bankOfficialNames = {
      'boc': 'Bank of Ceylon',
      'nsb': 'National Savings Bank',
      'peoples': 'Peoples Bank',
    };

    for (var bankId in widget.selectedBanks) {
      if (widget.initialBalances.containsKey(bankId)) {
        await accountDao.insertAccount(
            AccountsCompanion.insert(
              name: bankOfficialNames[bankId] ?? bankId.toUpperCase(),
              type: 'bank',
              initialBalance: drift.Value(widget.initialBalances[bankId]!),
            )
        );
      }
    }
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