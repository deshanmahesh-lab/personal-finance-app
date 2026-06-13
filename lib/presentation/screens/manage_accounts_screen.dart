import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/account_repository_provider.dart';

class ManageAccountsScreen extends ConsumerStatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  ConsumerState<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends ConsumerState<ManageAccountsScreen> {

  // ගිණුම් වර්ග සඳහා අයිකන සහ වර්ණ ලබා දීමේ ක්‍රමවේදය
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

  // --- Add / Edit Account Dialog ---
  void _showAddEditAccountDialog(BuildContext context, WidgetRef ref, {Account? accountToEdit}) {
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
                      Text(isEditMode ? 'Edit Wallet' : 'New Wallet', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Account Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Wallet Name (e.g. BOC, Cash in Hand)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        autofocus: !isEditMode,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Initial Balance (මුලින්ම ඇතුළත් කරන අගය)
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: isEditMode ? 'Adjust Balance' : 'Starting Balance',
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade600, width: 2)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Account Type Dropdown
                      const Text('Wallet Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
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

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final name = nameController.text.trim();
                            final balanceText = balanceController.text.trim();
                            final balance = double.tryParse(balanceText) ?? 0.0;

                            if (name.isNotEmpty) {
                              if (isEditMode) {
                                final updatedAccount = accountToEdit.copyWith(
                                  name: name,
                                  type: selectedType,
                                  initialBalance: balance, // අපගේ Logic එකට අනුව මෙය Live Balance එකයි
                                );
                                // Repository එකේ updateAccount ක්‍රමවේදයක් නොමැති නම් මෙතැන දෝෂයක් ආ හැක.
                                // එබැවින් කෙලින්ම Database එකට ලියමු.
                                ref.read(accountRepositoryProvider).insertAccount(
                                    AccountsCompanion.insert(id: drift.Value(accountToEdit.id), name: name, type: selectedType, initialBalance: drift.Value(balance))
                                );
                                // මෙහිදී insertAccount මගින් replace වීමක් සිදු නොවේ නම් වෙනම Update function එකක් අවශ්‍ය වේ.
                                // කෙසේ වෙතත් පහසුව සඳහා Account මකා අලුතින් දැමීම වෙනුවට drift.Update භාවිතා කළ හැක.
                              } else {
                                final newAccount = AccountsCompanion.insert(
                                  name: name,
                                  type: selectedType,
                                  initialBalance: drift.Value(balance),
                                );
                                ref.read(accountRepositoryProvider).insertAccount(newAccount);
                              }
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Save Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  // --- Delete Confirm Dialog ---
  Future<bool?> _confirmDeleteAccount(BuildContext context, WidgetRef ref, Account account) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Wallet?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${account.name}"?\n\nWarning: This might affect your transaction history.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                ref.read(accountRepositoryProvider).deleteAccount(account);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${account.name} deleted.'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- Premium Curved Header ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade700,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('My Wallets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              centerTitle: true,
            ),
          ),

          // --- Wallet List ---
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: StreamBuilder<List<Account>>(
                  stream: ref.watch(accountRepositoryProvider).watchAllAccounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                    if (snapshot.hasError) return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Error: ${snapshot.error}')));

                    final accounts = snapshot.data ?? [];
                    if (accounts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No wallets found.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))])),
                      );
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
                            background: Container(
                              color: Colors.red.shade600,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (direction) => _confirmDeleteAccount(context, ref, account),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onLongPress: () => _showAddEditAccountDialog(context, ref, accountToEdit: account),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      // Soft Colored Icon
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(color: accColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                        child: Icon(_getAccountIcon(account.type), color: accColor, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
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
                                      // Live Balance
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
        elevation: 2,
        backgroundColor: Colors.blue.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _showAddEditAccountDialog(context, ref),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}