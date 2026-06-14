import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../../data/datasources/app_database.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMyAccounts(ref),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const _CashFlowSummaryCard(),
                  const _BudgetProgressSection(),
                  _buildRecentTransactions(ref),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyAccounts(WidgetRef ref) {
    final accountDao = ref.watch(accountDaoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('My Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<List<Account>>(
          stream: accountDao.watchAllAccounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
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
                    leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.account_balance_wallet, color: Colors.white)),
                    title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(account.type.toUpperCase(), style: const TextStyle(color: Colors.white70)),
                    trailing: Text('Rs. ${account.initialBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(WidgetRef ref) {
    final txDao = ref.watch(transactionDaoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        StreamBuilder(
          stream: txDao.watchTransactionsWithCategories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

            final transactionsWithCat = snapshot.data ?? [];
            if (transactionsWithCat.isEmpty) {
              return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey))));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                final isEditableOrDeletable = difference.inHours < 24;

                final transactionCard = Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onLongPress: () {
                      if (!isEditableOrDeletable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Row(children: [Icon(Icons.lock_clock, color: Colors.white), SizedBox(width: 12), Expanded(child: Text('Transactions older than 24 hours cannot be edited.', style: TextStyle(fontSize: 15)))]), backgroundColor: Colors.orange.shade800, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16), duration: const Duration(seconds: 3)),
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            title: const Row(children: [Icon(Icons.edit_note, color: Colors.blue), SizedBox(width: 8), Text('Edit Transaction?')]),
                            content: const Text('Do you want to edit or update this transaction?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(transactionToEdit: txItem))); }, child: const Text('Edit', style: TextStyle(color: Colors.white))),
                            ],
                          );
                        },
                      );
                    },
                    leading: CircleAvatar(backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100, child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: amountColor)),
                    title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$categoryName • $dateStr'),
                    trailing: Text(displayAmount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor)),
                  ),
                );

                if (isEditableOrDeletable) {
                  return Dismissible(
                    key: ValueKey(tx.id),
                    direction: DismissDirection.endToStart,
                    background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete_outline, color: Colors.white, size: 30)),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Delete Transaction?')]),
                            content: const Text('Are you sure you want to delete this transaction?\n\nYour account balance will be automatically reversed.'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      txDao.deleteTransactionAndReverseBalance(tx);
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
        const SizedBox(height: 80),
      ],
    );
  }
}

class _CashFlowSummaryCard extends ConsumerWidget {
  const _CashFlowSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txDao = ref.watch(transactionDaoProvider);
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final currentMonthName = '${monthNames[now.month - 1]} ${now.year}';

    return StreamBuilder<Map<String, double>>(
      stream: txDao.watchMonthlyCashFlow(now),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'income': 0.0, 'expense': 0.0};
        final income = data['income']!;
        final expense = data['expense']!;
        final balance = income - expense;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(currentMonthName, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  const Icon(Icons.account_balance, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Net Balance', style: TextStyle(color: Colors.white, fontSize: 14)),
              Text('Rs. ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.green.shade400.withOpacity(0.3), radius: 20, child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Income', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Rs. ${income.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: Colors.red.shade400.withOpacity(0.3), radius: 20, child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Expense', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Rs. ${expense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetProgressSection extends ConsumerWidget {
  const _BudgetProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catDao = ref.watch(categoryDaoProvider);
    final txDao = ref.watch(transactionDaoProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return StreamBuilder<List<Category>>(
        stream: catDao.watchCategories(false),
        builder: (context, catSnapshot) {
          if (!catSnapshot.hasData) return const SizedBox.shrink();
          final budgetCategories = catSnapshot.data!.where((c) => c.budgetLimit != null && c.budgetLimit! > 0).toList();
          if (budgetCategories.isEmpty) return const SizedBox.shrink();

          return StreamBuilder<Map<String, double>>(
              stream: txDao.watchCategorySummary(false, startOfMonth, endOfMonth),
              builder: (context, sumSnapshot) {
                final summary = sumSnapshot.data ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Monthly Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    ...budgetCategories.map((cat) {
                      final spent = summary[cat.name] ?? 0.0;
                      final limit = cat.budgetLimit!;
                      final percent = (spent / limit).clamp(0.0, 1.0);
                      Color progressColor = Colors.green.shade600;
                      if (percent >= 0.9) progressColor = Colors.red.shade600;
                      else if (percent >= 0.7) progressColor = Colors.orange.shade600;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                Text('Rs. ${spent.toStringAsFixed(0)} / Rs. ${limit.toStringAsFixed(0)}', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: percent, backgroundColor: Colors.grey.shade300, color: progressColor, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }
          );
        }
    );
  }
}