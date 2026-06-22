import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../data/datasources/app_database.dart';
import 'add_transaction_screen.dart';
import 'all_transactions_screen.dart';

// ---------- අලංකාර වර්ණ (Design Tokens) ----------
class AppColors {
  static const primary      = Color(0xFF182D92);
  static const primaryDeep  = Color(0xFF0E1B5C);
  static const bgLight      = Color(0xFFF9FAFB);
  static const bgDark       = Color(0xFF121212);
  static const cardLight    = Colors.white;
  static const cardDark     = Color(0xFF1C1C1E);
  static const income       = Color(0xFF10B981);
  static const expense      = Color(0xFFEF4444);
  static const warning      = Color(0xFFF59E0B);
  static const divider      = Color(0xFFEDEFF3); // <--- මෙම පේළිය මඟහැරී තිබුණි
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Security Alert පණිවිඩය
  void _showRestrictionAlert(BuildContext context, String actionStr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.gpp_bad_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Security Alert!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('පැය 24 කට වඩා පැරණි ගනුදෙනු $actionStr නොහැක.', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // පහළින් ඉඩ තබා ඇත
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Greeting(lang: lang),
              const SizedBox(height: 20),

              // Net Balance Card (සජීවී දත්ත සමඟ)
              const _NetWorthAndCashFlowCard(),

              const SizedBox(height: 32),

              // Budget Progress Section (සජීවී දත්ත සමඟ)
              const _BudgetProgressSection(),

              const SizedBox(height: 32),

              // Recent Transactions (සජීවී දත්ත සමඟ)
              _SectionHeader(
                title: AppTranslations.getText('recent_tx', lang),
                action: 'View All',
                onActionTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllTransactionsScreen())
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildRecentTransactions(context, ref, isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTransactionScreen()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // සජීවී Transactions ලැයිස්තුව
  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref, bool isDark) {
    final txDao = ref.watch(transactionDaoProvider);
    final lang = ref.watch(languageProvider);
    final dividerColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.divider;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return StreamBuilder(
      stream: txDao.watchTransactionsWithCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }

        final allTransactions = snapshot.data ?? [];

        if (allTransactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(AppTranslations.getText('no_tx', lang), style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
            ),
          );
        }

        final displayTransactions = allTransactions.take(15).toList();

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dividerColor),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displayTransactions.length,
            separatorBuilder: (context, index) => _TileDivider(color: dividerColor),
            itemBuilder: (context, index) {
              final txItem = displayTransactions[index];
              final tx = txItem.transaction;
              final category = txItem.category;
              final isIncome = tx.amount >= 0;
              final dateStr = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';

              return Dismissible(
                key: ValueKey(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                    decoration: BoxDecoration(color: AppColors.expense, borderRadius: _getBorderRadius(index, displayTransactions.length)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28)
                ),
                confirmDismiss: (direction) async {
                  // පැය 24 Delete සීමාව
                  final difference = DateTime.now().difference(tx.date).inHours;
                  if (difference > 24) {
                    _showRestrictionAlert(context, 'මකා දැමිය (Delete)');
                    return false;
                  }

                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppTranslations.getText('del_tx', lang)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTranslations.getText('cancel', lang))),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: Text(AppTranslations.getText('delete', lang))),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) => txDao.deleteTransactionAndReverseBalance(tx),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: _getBorderRadius(index, displayTransactions.length),
                    onLongPress: () {
                      // පැය 24 Edit සීමාව
                      final difference = DateTime.now().difference(tx.date).inHours;
                      if (difference > 24) {
                        _showRestrictionAlert(context, 'Edit කළ');
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppTranslations.getText('edit_tx', lang)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.getText('cancel', lang))),
                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => AddTransactionScreen(transactionToEdit: txItem))); }, child: Text(AppTranslations.getText('edit', lang))),
                          ],
                        ),
                      );
                    },
                    child: TransactionTile(
                      title: tx.description,
                      category: category?.name ?? 'Uncategorized',
                      date: dateStr,
                      amount: tx.amount.abs(),
                      isIncome: isIncome,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  BorderRadius _getBorderRadius(int index, int length) {
    if (length == 1) return BorderRadius.circular(20);
    if (index == 0) return const BorderRadius.vertical(top: Radius.circular(20));
    if (index == length - 1) return const BorderRadius.vertical(bottom: Radius.circular(20));
    return BorderRadius.zero;
  }
}

// ---------- Sub Components ----------

class _Greeting extends StatelessWidget {
  final String lang;
  const _Greeting({required this.lang});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1020);
    final title = AppTranslations.getText('title_dashboard', lang);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', style: TextStyle(color: textMuted, fontSize: 14)),
            const SizedBox(height: 2),
            Text(title,
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onActionTap;

  const _SectionHeader({required this.title, required this.action, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : const Color(0xFF0B1020))),
        if (onActionTap != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(action,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          ),
      ],
    );
  }
}

// ---------- Component 1: Net Balance Card (Live Logic) ----------
class _NetWorthAndCashFlowCard extends ConsumerWidget {
  const _NetWorthAndCashFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txDao = ref.watch(transactionDaoProvider);
    final accountDao = ref.watch(accountDaoProvider);
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
            totalNetWorth = unique.values.fold(0.0, (sum, acc) => sum + acc.initialBalance);
          }

          return StreamBuilder<Map<String, double>>(
            stream: txDao.watchMonthlyCashFlow(now),
            builder: (context, txSnapshot) {
              final data = txSnapshot.data ?? {'income': 0.0, 'expense': 0.0};
              final income = data['income']!;
              final expense = data['expense']!;

              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const _AccountsBottomSheet(),
                  );
                },
                child: NetBalanceCard(
                  balance: 'Rs. ${totalNetWorth.toStringAsFixed(2)}',
                  income: 'Rs. ${income.toStringAsFixed(0)}',
                  expense: 'Rs. ${expense.toStringAsFixed(0)}',
                ),
              );
            },
          );
        }
    );
  }
}

class NetBalanceCard extends StatelessWidget {
  final String balance;
  final String income;
  final String expense;

  const NetBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep, Color(0xFF060A30)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40, top: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
            ),
          ),
          Positioned(
            right: 30, top: 60,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.touch_app_outlined, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text('Net Balance', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
                    ],
                  ),
                  _GlassPill(child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.diamond_outlined, color: Colors.white, size: 12),
                      SizedBox(width: 6),
                      Text('Total Wealth', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 22),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(balance, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.05)),
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _FlowItem(label: 'Income', value: income, color: AppColors.income, icon: Icons.arrow_downward_rounded)),
                        Container(width: 1, height: 36, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(width: 16),
                        Expanded(child: _FlowItem(label: 'Expense', value: expense, color: AppColors.expense, icon: Icons.arrow_upward_rounded)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), border: Border.all(color: Colors.white.withOpacity(0.25)), borderRadius: BorderRadius.circular(100)),
          child: child,
        ),
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _FlowItem({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Component 2: Budget Progress (Live Logic) ----------
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
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: AppTranslations.getText('monthly_budgets', lang), action: ''),
                    const SizedBox(height: 16),
                    ...budgetCategories.map((cat) {
                      final spent = summary[cat.name] ?? 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: BudgetProgress(category: cat.name, spent: spent, limit: cat.budgetLimit!, isDark: isDark),
                      );
                    }),
                  ],
                );
              }
          );
        }
    );
  }
}

class BudgetProgress extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final bool isDark;

  const BudgetProgress({super.key, required this.category, required this.spent, required this.limit, required this.isDark});

  Color get _color {
    final p = spent / limit;
    if (p > 0.9) return AppColors.expense;
    if (p > 0.7) return AppColors.warning;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (spent / limit).clamp(0.0, 1.0);
    String fmt(double v) => 'Rs. ${v.toStringAsFixed(0)}';

    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final dividerColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.divider;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1020);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  children: [
                    TextSpan(text: fmt(spent)),
                    TextSpan(text: '  /  ${fmt(limit)}', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(height: 12, color: dividerColor),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(colors: [_color.withOpacity(0.85), _color]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Component 3: Transaction Tile ----------
class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final double amount;
  final bool isIncome;
  final bool isDark;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = isIncome ? '+' : '-';
    final textPrimary = isDark ? Colors.white : const Color(0xFF0B1020);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text('$category • $date', style: TextStyle(fontSize: 12.5, color: textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text('$sign Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: color)),
        ],
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  final Color color;
  const _TileDivider({required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 76),
    child: Container(height: 1, color: color),
  );
}

// ---------- Bottom Sheet for Accounts ----------
class _AccountsBottomSheet extends ConsumerWidget {
  const _AccountsBottomSheet();

  Color _getBankColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('boc') || lower.contains('ceylon')) return const Color(0xFFF9A825);
    if (lower.contains('peoples')) return const Color(0xFFC62828);
    if (lower.contains('nsb') || lower.contains('national savings')) return const Color(0xFFFF9800);
    if (lower.contains('combank') || lower.contains('commercial')) return const Color(0xFF1976D2);
    return const Color(0xFF2E7D32); // Default Cash Wallet
  }

  Color _getTextColor(Color bgColor) {
    return bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountDao = ref.watch(accountDaoProvider);
    final lang = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppTranslations.getText('my_accounts', lang), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          StreamBuilder<List<Account>>(
            stream: accountDao.watchAllAccounts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final unique = <String, Account>{};
              for (var acc in snapshot.data ?? <Account>[]) {
                if (!unique.containsKey(acc.name)) unique[acc.name] = acc;
              }
              final accounts = unique.values.toList();

              if (accounts.isEmpty) return Text(AppTranslations.getText('no_accounts', lang), style: TextStyle(color: isDark ? Colors.white54 : Colors.grey));

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final bgColor = _getBankColor(account.name);
                  final textColor = _getTextColor(bgColor);

                  return Card(
                    color: bgColor,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(account.type == 'cash' ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded, color: textColor),
                      ),
                      title: Text(account.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(account.type.toUpperCase(), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                      trailing: Text('Rs. ${account.initialBalance.toStringAsFixed(2)}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}