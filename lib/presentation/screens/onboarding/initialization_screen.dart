import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../main_screen.dart';
import '../lock_screen.dart';
import '../../providers/language_provider.dart';
import '../../providers/database_provider.dart';
import '../../../utils/app_translations.dart';
import '../../../data/datasources/app_database.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;
  final Map<String, double> initialBalances;

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

    // 2. SharedPreferences සැකසීම
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);
    await prefs.setStringList('selectedBanks', widget.selectedBanks);
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

  // [FIXED] Wallet Duplication සහ Balance Reset Bug එක නිවැරදි කිරීම
  Future<void> _setupInitialWallets(AppDatabase db) async {
    final accountDao = db.accountDao;
    final txDao = db.transactionDao;

    // Cash Wallet
    if (widget.initialBalances.containsKey('cash')) {
      final double amount = widget.initialBalances['cash']!;
      // Wallet එක දැනටමත් ඇත්නම් එය ලබාගැනීම (Duplicate වීම වළක්වයි)
      final accId = await accountDao.getOrCreateAccount('My Wallet', 'cash');

      if (amount > 0) {
        await _injectInitialBalanceTransaction(txDao, accId, amount);
      }
    }

    // Bank Wallets
    final Map<String, String> bankOfficialNames = {
      'boc': 'Bank of Ceylon',
      'nsb': 'National Savings Bank',
      'peoples': 'Peoples Bank',
    };

    for (var bankId in widget.selectedBanks) {
      if (widget.initialBalances.containsKey(bankId)) {
        final double amount = widget.initialBalances[bankId]!;
        final bankName = bankOfficialNames[bankId] ?? bankId.toUpperCase();

        final accId = await accountDao.getOrCreateAccount(bankName, 'bank');

        if (amount > 0) {
          await _injectInitialBalanceTransaction(txDao, accId, amount);
        }
      }
    }
  }

  // [CRITICAL FIX] Initial Balance එක System Transaction එකක් ලෙස Database එකට යැවීම
  Future<void> _injectInitialBalanceTransaction(dynamic txDao, int accId, double amount) async {
    // Analytics වලට බලපෑම් නොකිරීම සඳහා isTransfer: true ලෙස යොදා ඇත.
    await txDao.addTransactionAndUpdateBalance(
        TransactionsCompanion.insert(
          description: 'Initial Balance',
          amount: amount,
          date: DateTime.now(),
          accountId: accId,
          isTransfer: const drift.Value(true),
          categoryId: const drift.Value(null),
        ),
        accId
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