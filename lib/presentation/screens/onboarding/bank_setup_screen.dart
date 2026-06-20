import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'initial_balances_screen.dart'; // [නව වෙනස] අලුත් ගොනුව import කිරීම

class BankSetupScreen extends ConsumerStatefulWidget {
  const BankSetupScreen({super.key});

  @override
  ConsumerState<BankSetupScreen> createState() => _BankSetupScreenState();
}

class _BankSetupScreenState extends ConsumerState<BankSetupScreen> {
  final List<Map<String, dynamic>> _supportedBanks = [
    {'id': 'boc', 'name': 'Bank of Ceylon (BOC)', 'icon': Icons.account_balance},
    {'id': 'nsb', 'name': 'National Savings Bank (NSB)', 'icon': Icons.savings},
    {'id': 'peoples', 'name': 'Peoples Bank', 'icon': Icons.account_balance_wallet},
  ];

  final Map<String, bool> _selectedBanks = {};

  @override
  void initState() {
    super.initState();
    for (var bank in _supportedBanks) {
      _selectedBanks[bank['id']] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    final mainTitle = AppTranslations.getText('select_banks', currentLanguage);
    final subTitle = AppTranslations.getText('select_banks_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    final bool canProceed = _selectedBanks.values.contains(true);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 24), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ),
              const SizedBox(height: 24),

              Text(mainTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              Text(subTitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 40),

              Expanded(
                child: ListView.builder(
                  itemCount: _supportedBanks.length,
                  itemBuilder: (context, index) {
                    final bank = _supportedBanks[index];
                    final bankId = bank['id'];
                    final isSelected = _selectedBanks[bankId]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300, width: 2),
                      ),
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() { _selectedBanks[bankId] = value ?? false; });
                        },
                        title: Text(bank['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
                        secondary: Icon(bank['icon'], color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                        activeColor: Theme.of(context).primaryColor,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canProceed ? () {
                    final selectedList = _selectedBanks.entries.where((e) => e.value).map((e) => e.key).toList();
                    // [නව වෙනස] InitialBalancesScreen වෙත ගමන් කිරීම
                    Navigator.push(context, MaterialPageRoute(builder: (context) => InitialBalancesScreen(selectedBanks: selectedList)));
                  } : null,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300),
                  child: Text(btnText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}