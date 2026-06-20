import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';

class ManageAccountsScreen extends ConsumerStatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  ConsumerState<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends ConsumerState<ManageAccountsScreen> {

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank': return Icons.account_balance_rounded;
      case 'mobile': return Icons.phone_iphone_rounded;
      case 'debt': return Icons.money_off_rounded;
      case 'cash': default: return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getAccountColor(String type) {
    switch (type.toLowerCase()) {
      case 'bank': return Colors.blue.shade600;
      case 'mobile': return Colors.purple.shade600;
      case 'debt': return Colors.red.shade600;
      case 'cash': default: return Colors.green.shade600;
    }
  }

  void _showAddEditAccountDialog(BuildContext context, WidgetRef ref, {Account? accountToEdit}) {
    final lang = ref.read(languageProvider);
    final isEditMode = accountToEdit != null;
    final nameController = TextEditingController(text: isEditMode ? accountToEdit.name : '');
    final balanceController = TextEditingController(text: isEditMode ? accountToEdit.initialBalance.toStringAsFixed(0) : '');
    String selectedType = isEditMode ? accountToEdit.type : 'cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditMode ? AppTranslations.getText('edit_wallet', lang) : AppTranslations.getText('new_wallet', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: AppTranslations.getText('wallet_name', lang),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        autofocus: !isEditMode,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isEditMode ? AppTranslations.getText('adj_balance', lang) : AppTranslations.getText('start_balance', lang),
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(AppTranslations.getText('wallet_type', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: const [
                              DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                              DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                              DropdownMenuItem(value: 'mobile', child: Text('Mobile Money (e.g. eZ Cash)')),
                              DropdownMenuItem(value: 'debt', child: Text('Virtual Debt Wallet')),
                            ],
                            onChanged: (value) => setStateDialog(() => selectedType = value!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          onPressed: () {
                            final name = nameController.text.trim();
                            final balanceText = balanceController.text.trim();
                            final balance = double.tryParse(balanceText) ?? 0.0;

                            if (name.isNotEmpty) {
                              if (isEditMode) {
                                ref.read(accountDaoProvider).insertAccount(
                                    AccountsCompanion.insert(id: drift.Value(accountToEdit.id), name: name, type: selectedType, initialBalance: drift.Value(balance))
                                );
                              } else {
                                final newAccount = AccountsCompanion.insert(name: name, type: selectedType, initialBalance: drift.Value(balance));
                                ref.read(accountDaoProvider).insertAccount(newAccount);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: Text(AppTranslations.getText('save_wallet', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Future<bool?> _confirmDeleteAccount(BuildContext context, WidgetRef ref, Account account) async {
    final lang = ref.read(languageProvider);
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.getText('del_wallet_confirm', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${account.name}"?\n\nWarning: This might affect your transaction history.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTranslations.getText('cancel', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                ref.read(accountDaoProvider).deleteAccount(account);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${account.name} deleted.'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              child: Text(AppTranslations.getText('delete', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(title: Text(AppTranslations.getText('my_wallets', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)), centerTitle: true),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
                child: StreamBuilder<List<Account>>(
                  stream: ref.watch(accountDaoProvider).watchAllAccounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));

                    final accounts = snapshot.data ?? [];
                    if (accounts.isEmpty) {
                      return Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text(AppTranslations.getText('no_accounts', lang), style: TextStyle(color: Colors.grey.shade500, fontSize: 16))])));
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: accounts.length,
                        separatorBuilder: (context, index) => Divider(height: 1, indent: 72, endIndent: 16, color: Colors.grey.withOpacity(0.15)),
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final accColor = _getAccountColor(account.type);

                          return Dismissible(
                            key: ValueKey(account.id),
                            direction: DismissDirection.endToStart,
                            background: Container(color: Colors.red.shade600, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 24), child: const Icon(Icons.delete_outline, color: Colors.white, size: 28)),
                            confirmDismiss: (direction) => _confirmDeleteAccount(context, ref, account),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onLongPress: () => _showAddEditAccountDialog(context, ref, accountToEdit: account),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      Container(width: 48, height: 48, decoration: BoxDecoration(color: accColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(_getAccountIcon(account.type), color: accColor, size: 24)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                            const SizedBox(height: 4),
                                            Text(account.type.toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          ],
                                        ),
                                      ),
                                      Text('Rs. ${account.initialBalance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        elevation: 2,
        backgroundColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _showAddEditAccountDialog(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppTranslations.getText('add_wallet', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}