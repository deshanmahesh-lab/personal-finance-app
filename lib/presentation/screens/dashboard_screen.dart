import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../data/datasources/app_database.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const _NetWorthAndCashFlowCard(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMyAccounts(ref),
                    const _BudgetProgressSection(),
                    _buildRecentTransactions(ref),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  // අනුපිටපත් (Duplicates) ඉවත් කිරීමේ logic එක
  List<Account> _getUniqueAccounts(List<Account> accounts) {
    final unique = <String, Account>{};
    for (var acc in accounts) {
      if (!unique.containsKey(acc.name)) {
        unique[acc.name] = acc;
      }
    }
    return unique.values.toList();
  }

  // Master Plan එකට අනුව බැංකුවේ පාට තේරීම
  Color _getBankColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('boc') || lower.contains('ceylon')) return const Color(0xFFFFC107); // BOC Yellow
    if (lower.contains('peoples')) return const Color(0xFFD32F2F); // Peoples Red
    if (lower.contains('nsb') || lower.contains('national savings')) return const Color(0xFFF57F17); // NSB Orange
    if (lower.contains('combank') || lower.contains('commercial')) return const Color(0xFF1976D2); // Combank Blue
    return Colors.teal.shade700; // Default Cash Wallet
  }

  Color _getTextColor(Color bgColor) {
    return bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildMyAccounts(WidgetRef ref) {
    final accountDao = ref.watch(accountDaoProvider);
    return Consumer(builder: (context, ref, child) {
      final lang = ref.watch(languageProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(AppTranslations.getText('my_accounts', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<List<Account>>(
            stream: accountDao.watchAllAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final accounts = _getUniqueAccounts(snapshot.data ?? []);
              if (accounts.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(AppTranslations.getText('no_accounts', lang)));

              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    final bgColor = _getBankColor(account.name);
                    final textColor = _getTextColor(bgColor);

                    return Container(
                      width: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: bgColor,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(account.type == 'cash' ? Icons.account_balance_wallet : Icons.account_balance, color: textColor.withOpacity(0.7)),
                                  Text(account.type.toUpperCase(), style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(account.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('Rs. ${account.initialBalance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }

  Widget _buildRecentTransactions(WidgetRef ref) {
    final txDao = ref.watch(transactionDaoProvider);
    return Consumer(builder: (context, ref, child) {
      final lang = ref.watch(languageProvider);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(AppTranslations.getText('recent_tx', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: txDao.watchTransactionsWithCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final transactionsWithCat = snapshot.data ?? [];
              if (transactionsWithCat.isEmpty) {
                return Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text(AppTranslations.getText('no_tx', lang), style: const TextStyle(color: Colors.grey))));
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
                  final dateStr = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';

                  final transactionCard = Card(
                    elevation: 1, margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppTranslations.getText('edit_tx', lang)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.getText('cancel', lang))),
                              ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(transactionToEdit: txItem))); }, child: Text(AppTranslations.getText('edit', lang))),
                            ],
                          ),
                        );
                      },
                      leading: CircleAvatar(backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100, child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: amountColor)),
                      title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${category?.name ?? 'Uncategorized'} • $dateStr'),
                      trailing: Text('$sign Rs. ${tx.amount.abs().toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor)),
                    ),
                  );

                  return Dismissible(
                    key: ValueKey(tx.id), direction: DismissDirection.endToStart,
                    background: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete_outline, color: Colors.white, size: 30)),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppTranslations.getText('del_tx', lang)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTranslations.getText('cancel', lang))),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppTranslations.getText('delete', lang))),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) => txDao.deleteTransactionAndReverseBalance(tx),
                    child: transactionCard,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      );
    });
  }
}

// Total Wealth සහ මාසික Cashflow පෙන්වන නව කාඩ්පත
class _NetWorthAndCashFlowCard extends ConsumerWidget {
  const _NetWorthAndCashFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txDao = ref.watch(transactionDaoProvider);
    final accountDao = ref.watch(accountDaoProvider);
    final lang = ref.watch(languageProvider);
    final now = DateTime.now();

    return StreamBuilder<List<Account>>(
        stream: accountDao.watchAllAccounts(),
        builder: (context, accSnapshot) {
          double totalNetWorth = 0.0;
          if (accSnapshot.hasData) {
            final unique = <String, Account>{};
            for (var acc in accSnapshot.data!) {
              if (!unique.containsKey(acc.name)) unique[acc.name] = acc;
            }
            // සියලුම Wallets වල එකතුව සෙවීම
            totalNetWorth = unique.values.fold(0.0, (sum, acc) => sum + acc.initialBalance);
          }

          return StreamBuilder<Map<String, double>>(
            stream: txDao.watchMonthlyCashFlow(now),
            builder: (context, txSnapshot) {
              final data = txSnapshot.data ?? {'income': 0.0, 'expense': 0.0};
              final income = data['income']!;
              final expense = data['expense']!;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppTranslations.getText('net_balance', lang), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Total Wealth', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Rs. ${totalNetWorth.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(AppTranslations.getText('income', lang), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ]),
                            const SizedBox(height: 4),
                            Text('Rs. ${income.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                          Container(width: 1, height: 40, color: Colors.white24),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Text(AppTranslations.getText('expense', lang), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ]),
                            const SizedBox(height: 4),
                            Text('Rs. ${expense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
    );
  }
}

class _BudgetProgressSection extends ConsumerWidget {
  const _BudgetProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catDao = ref.watch(categoryDaoProvider);
    final txDao = ref.watch(transactionDaoProvider);
    final lang = ref.watch(languageProvider);
    final now = DateTime.now();

    return StreamBuilder<List<Category>>(
        stream: catDao.watchCategories(false),
        builder: (context, catSnapshot) {
          if (!catSnapshot.hasData) return const SizedBox.shrink();
          final budgetCategories = catSnapshot.data!.where((c) => c.budgetLimit != null && c.budgetLimit! > 0).toList();
          if (budgetCategories.isEmpty) return const SizedBox.shrink();

          return StreamBuilder<Map<String, double>>(
              stream: txDao.watchCategorySummary(false, DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1)),
              builder: (context, sumSnapshot) {
                final summary = sumSnapshot.data ?? {};
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(AppTranslations.getText('monthly_budgets', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    ...budgetCategories.map((cat) {
                      final spent = summary[cat.name] ?? 0.0;
                      final limit = cat.budgetLimit!;
                      final percent = (spent / limit).clamp(0.0, 1.0);
                      Color progressColor = percent >= 0.9 ? Colors.red.shade600 : (percent >= 0.7 ? Colors.orange.shade600 : Colors.green.shade600);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(cat.name), Text('Rs. ${spent.toStringAsFixed(0)} / Rs. ${limit.toStringAsFixed(0)}', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold))]),
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