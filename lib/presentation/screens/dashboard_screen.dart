import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_repository_provider.dart';
import '../../data/datasources/app_database.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountRepo = ref.watch(accountRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // (මෙහි තිබූ actions කොටස අයින් කරන ලදී)
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('My Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<List<Account>>(
            stream: accountRepo.watchAllAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final accounts = snapshot.data ?? [];
              if (accounts.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('No accounts found.'));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.teal.shade700,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.account_balance_wallet, color: Colors.white),
                      ),
                      title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(account.type.toUpperCase(), style: const TextStyle(color: Colors.white70)),
                      trailing: Text(
                        'Rs. ${account.initialBalance.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder(
              stream: accountRepo.watchTransactionsWithCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final transactionsWithCat = snapshot.data ?? [];
                if (transactionsWithCat.isEmpty) {
                  return const Center(
                    child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: transactionsWithCat.length,
                  itemBuilder: (context, index) {

                    final txItem = transactionsWithCat[index];
                    final tx = txItem.transaction;
                    final category = txItem.category;

                    final isIncome = tx.amount >= 0;
                    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
                    final sign = isIncome ? '+' : '-';
                    final displayAmount = '$sign Rs. ${tx.amount.abs().toStringAsFixed(2)}';
                    final dateStr = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';

                    final categoryName = category?.name ?? 'Uncategorized';
                    final difference = DateTime.now().difference(tx.date);
                    final isDeletable = difference.inHours < 24;

                    final transactionCard = Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: amountColor,
                          ),
                        ),
                        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$categoryName • $dateStr'),
                        trailing: Text(
                          displayAmount,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
                        ),
                      ),
                    );

                    if (isDeletable) {
                      return Dismissible(
                        key: ValueKey(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete Transaction?'),
                                  ],
                                ),
                                content: const Text('Are you sure you want to delete this transaction?\n\nYour account balance will be automatically reversed.'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          accountRepo.deleteTransactionAndReverseBalance(tx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.delete_forever, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Transaction deleted.', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              backgroundColor: Colors.grey.shade800,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: transactionCard,
                      );
                    } else {
                      return transactionCard;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}