import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import 'add_transaction_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens & Enums
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF182D92);
  static const bgLight = Color(0xFFF9FAFB);
  static const surfaceLight = Color(0xFFFCFDFC);
  static const bgDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1A1A1A);
  static const income = Color(0xFF10B981);
  static const expense = Color(0xFFEF4444);
  static const textLight = Color(0xFF0B1020);
  static const textDark = Color(0xFFF3F4F6);
  static const mutedLight = Color(0xFF6B7280);
  static const mutedDark = Color(0xFF9CA3AF);
  static const dividerLight = Color(0xFFEDEFF2);
  static const dividerDark = Color(0xFF242424);
}

enum TxFilter { all, income, expense }
enum SortOrder { newest, oldest, highest, lowest }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  TxFilter _filter = TxFilter.all;
  SortOrder _sort = SortOrder.newest;
  DateTimeRange? _range;

  // [Security Alert] පැය 24 කට වඩා පැරණි ගනුදෙනු Edit/Delete කිරීම වැළැක්වීම
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

  Future<void> _openSortSheet() async {
    final picked = await showModalBottomSheet<SortOrder>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortSheet(current: _sort),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txDao = ref.watch(transactionDaoProvider);
    final lang = ref.watch(languageProvider);

    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'All Transactions',
          style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                _FilterSortBar(
                  filter: _filter,
                  sort: _sort,
                  range: _range,
                  isDark: isDark,
                  onFilterChanged: (f) => setState(() => _filter = f),
                  onSortTap: _openSortSheet,
                  onDateTap: _pickDateRange,
                  onClearDate: () => setState(() => _range = null),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: txDao.watchTransactionsWithCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allTransactions = snapshot.data ?? [];

                      // 1. Data Filtering Logic
                      var filteredList = allTransactions.where((item) {
                        final tx = item.transaction;
                        final isIncome = tx.amount >= 0;

                        if (_filter == TxFilter.income && !isIncome) return false;
                        if (_filter == TxFilter.expense && isIncome) return false;

                        if (_range != null) {
                          final txDate = tx.date;
                          final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
                          final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);
                          if (txDate.isBefore(start) || txDate.isAfter(end)) return false;
                        }

                        return true;
                      }).toList();

                      // 2. Data Sorting Logic
                      filteredList.sort((a, b) {
                        switch (_sort) {
                          case SortOrder.newest:
                            return b.transaction.date.compareTo(a.transaction.date);
                          case SortOrder.oldest:
                            return a.transaction.date.compareTo(b.transaction.date);
                          case SortOrder.highest:
                            return b.transaction.amount.abs().compareTo(a.transaction.amount.abs());
                          case SortOrder.lowest:
                            return a.transaction.amount.abs().compareTo(b.transaction.amount.abs());
                        }
                      });

                      if (filteredList.isEmpty) {
                        return _EmptyState(muted: muted, text: text);
                      }

                      // 3. UI List Building
                      return Container(
                        margin: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: divider),
                        ),
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => Padding(padding: const EdgeInsets.only(left: 76), child: Container(height: 1, color: divider)),
                          itemBuilder: (context, index) {
                            final txItem = filteredList[index];
                            final tx = txItem.transaction;
                            final category = txItem.category;
                            final isIncome = tx.amount >= 0;

                            BorderRadius getBorderRadius() {
                              if (filteredList.length == 1) return BorderRadius.circular(20);
                              if (index == 0) return const BorderRadius.vertical(top: Radius.circular(20));
                              if (index == filteredList.length - 1) return const BorderRadius.vertical(bottom: Radius.circular(20));
                              return BorderRadius.zero;
                            }

                            return Dismissible(
                              key: ValueKey(tx.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(color: AppColors.expense, borderRadius: getBorderRadius()),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
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
                                  borderRadius: getBorderRadius(),
                                  splashColor: AppColors.primary.withOpacity(0.08),
                                  highlightColor: AppColors.primary.withOpacity(0.04),
                                  onLongPress: () {
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
                                  child: _TransactionTile(
                                    title: tx.description,
                                    category: category?.name ?? 'Uncategorized',
                                    date: tx.date,
                                    amount: tx.amount.abs(),
                                    isIncome: isIncome,
                                    isLast: index == filteredList.length - 1,
                                    isDark: isDark,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter & Sort bar
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSortBar extends StatelessWidget {
  final TxFilter filter;
  final SortOrder sort;
  final DateTimeRange? range;
  final bool isDark;
  final ValueChanged<TxFilter> onFilterChanged;
  final VoidCallback onSortTap;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;

  const _FilterSortBar({
    required this.filter,
    required this.sort,
    required this.range,
    required this.isDark,
    required this.onFilterChanged,
    required this.onSortTap,
    required this.onDateTap,
    required this.onClearDate,
  });

  String get _sortLabel {
    switch (sort) {
      case SortOrder.newest: return 'Newest';
      case SortOrder.oldest: return 'Oldest';
      case SortOrder.highest: return 'Highest';
      case SortOrder.lowest: return 'Lowest';
    }
  }

  String get _dateLabel {
    if (range == null) return 'Date Range';
    String d(DateTime x) => '${x.day}/${x.month}';
    return '${d(range!.start)} – ${d(range!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
            _Chip(
              label: 'Sort: $_sortLabel',
              icon: Icons.swap_vert_rounded,
              onTap: onSortTap,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _Chip(
              label: _dateLabel,
              icon: Icons.calendar_today_rounded,
              onTap: onDateTap,
              onTrailingTap: range != null ? onClearDate : null,
              active: range != null,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 22, color: divider, margin: const EdgeInsets.symmetric(vertical: 8)),
            const SizedBox(width: 12),
            _ChoiceChip(
              label: 'All',
              selected: filter == TxFilter.all,
              onTap: () => onFilterChanged(TxFilter.all),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ChoiceChip(
              label: 'Income',
              selected: filter == TxFilter.income,
              tint: AppColors.income,
              onTap: () => onFilterChanged(TxFilter.income),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _ChoiceChip(
              label: 'Expense',
              selected: filter == TxFilter.expense,
              tint: AppColors.expense,
              onTap: () => onFilterChanged(TxFilter.expense),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onTrailingTap;
  final bool active;
  final bool isDark;

  const _Chip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onTrailingTap,
    this.active = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.textDark : AppColors.textLight;
    final bg = active
        ? AppColors.primary.withOpacity(isDark ? 0.22 : 0.10)
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04));
    final border = active
        ? AppColors.primary.withOpacity(0.45)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: active ? AppColors.primary : fg.withOpacity(0.85)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: active ? AppColors.primary : fg, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: -0.1),
            ),
            if (onTrailingTap != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onTrailingTap,
                child: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? tint;
  final VoidCallback onTap;
  final bool isDark;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? AppColors.primary;
    final fg = isDark ? AppColors.textDark : AppColors.textLight;
    final bg = selected
        ? accent.withOpacity(isDark ? 0.22 : 0.12)
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04));
    final border = selected
        ? accent.withOpacity(0.5)
        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : fg.withOpacity(0.9),
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction tile
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final DateTime date;
  final double amount;
  final bool isIncome;
  final bool isLast;
  final bool isDark;

  const _TransactionTile({
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.isLast,
    required this.isDark,
  });

  static String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = isIncome ? AppColors.income : AppColors.expense;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.2),
                ),
                const SizedBox(height: 2),
                Text(
                  '$category • ${_fmtDate(date)}',
                  style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isIncome ? '+' : '-'}Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15.5, letterSpacing: -0.3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Color muted;
  final Color text;
  const _EmptyState({required this.muted, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text('No transactions found', style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2)),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your filters or date range\nto see more activity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  final SortOrder current;
  const _SortSheet({required this.current});

  static const _options = <(SortOrder, String, IconData)>[
    (SortOrder.newest, 'Newest first', Icons.north_rounded),
    (SortOrder.oldest, 'Oldest first', Icons.south_rounded),
    (SortOrder.highest, 'Highest amount', Icons.trending_up_rounded),
    (SortOrder.lowest, 'Lowest amount', Icons.trending_down_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.12), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: muted.withOpacity(0.35), borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: Row(
                children: [
                  Text('Sort by', style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: muted.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 18, color: muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < _options.length; i++) ...[
              _SortRow(
                option: _options[i].$1,
                label: _options[i].$2,
                icon: _options[i].$3,
                selected: _options[i].$1 == current,
                text: text,
              ),
              if (i != _options.length - 1)
                Container(margin: const EdgeInsets.only(left: 64), height: 1, color: divider),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  final SortOrder option;
  final String label;
  final IconData icon;
  final bool selected;
  final Color text;

  const _SortRow({
    required this.option,
    required this.label,
    required this.icon,
    required this.selected,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1)),
            ),
            if (selected) const Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}