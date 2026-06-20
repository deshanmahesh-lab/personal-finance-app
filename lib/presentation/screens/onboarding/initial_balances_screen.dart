// ගොනු නාමය: lib/presentation/screens/onboarding/initial_balances_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'initialization_screen.dart';

class InitialBalancesScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;

  const InitialBalancesScreen({super.key, required this.selectedBanks});

  @override
  ConsumerState<InitialBalancesScreen> createState() => _InitialBalancesScreenState();
}

class _InitialBalancesScreenState extends ConsumerState<InitialBalancesScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _bankNames = {
    'boc': 'Bank of Ceylon (BOC)',
    'nsb': 'National Savings Bank (NSB)',
    'peoples': 'Peoples Bank',
  };

  @override
  void initState() {
    super.initState();
    // Cash Wallet සඳහා controller එකක්
    _controllers['cash'] = TextEditingController(text: '0');

    // තෝරාගත් සෑම බැංකුවක් සඳහාම controller එකක්
    for (var bank in widget.selectedBanks) {
      _controllers[bank] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    // Note: AppTranslations.dart හි මෙම key-value යුගලයන් පසුව අලුතින් එක් කිරීමට සිදුවේ
    final title = AppTranslations.getText('enter_balances', currentLanguage) == 'enter_balances' ? 'Enter Initial Balances' : AppTranslations.getText('enter_balances', currentLanguage);
    final desc = AppTranslations.getText('enter_balances_desc', currentLanguage) == 'enter_balances_desc' ? 'Please enter the current balance for your wallets to start fresh.' : AppTranslations.getText('enter_balances_desc', currentLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildBalanceInput(context, 'cash', 'My Wallet (Cash in Hand)', Icons.account_balance_wallet),
                    const SizedBox(height: 16),
                    ...widget.selectedBanks.map((bankId) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildBalanceInput(context, bankId, _bankNames[bankId] ?? bankId, Icons.account_balance),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // සියලුම අගයන් double ලෙස Map එකකට සකස් කිරීම
                    final Map<String, double> balances = {};
                    _controllers.forEach((key, controller) {
                      balances[key] = double.tryParse(controller.text) ?? 0.0;
                    });

                    // InitializationScreen වෙත ගමන් කිරීම
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InitializationScreen(
                          selectedBanks: widget.selectedBanks,
                          initialBalances: balances,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppTranslations.getText('continue_btn', currentLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceInput(BuildContext context, String key, String title, IconData icon) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: title,
        prefixText: 'Rs. ',
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }
}