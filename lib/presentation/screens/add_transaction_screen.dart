import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../services/category_prediction_service.dart';
import '../../data/datasources/daos/transaction_dao.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums & Extensions
// ─────────────────────────────────────────────────────────────────────────────
enum TxType { expense, income, transfer }

extension TxTypeX on TxType {
  Color get color => switch (this) {
    TxType.expense => const Color(0xFFEF4444),
    TxType.income => const Color(0xFF10B981),
    TxType.transfer => const Color(0xFF3B82F6),
  };
  IconData get icon => switch (this) {
    TxType.expense => Icons.south_west_rounded,
    TxType.income => Icons.north_east_rounded,
    TxType.transfer => Icons.swap_horiz_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionWithCategory? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> with TickerProviderStateMixin {

  // State Variables
  TxType _type = TxType.expense;
  String _amount = '0';
  final TextEditingController _noteCtrl = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedWalletId;
  int? _fromWalletId;
  int? _toWalletId;

  bool _isLoading = false;
  bool _isAiSuggested = false;

  Color get _accent => _type.color;

  @override
  void initState() {
    super.initState();

    // Edit Mode Setup
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!.transaction;
      // Amount එක දශම තැන් රහිතව හෝ සහිතව String එකක් ලෙස සැකසීම
      _amount = tx.amount.abs().toStringAsFixed(tx.amount.truncateToDouble() == tx.amount ? 0 : 2);
      _noteCtrl.text = tx.description;

      if (tx.isTransfer) {
        _type = TxType.transfer;
        _fromWalletId = tx.accountId;
        _toWalletId = tx.transferToAccountId;
      } else {
        _type = tx.amount >= 0 ? TxType.income : TxType.expense;
        _selectedCategoryId = tx.categoryId;
        _selectedWalletId = tx.accountId;
      }
    } else {
      _runAiPrediction();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  // --- Backend Logic Functions ---

  Future<void> _runAiPrediction() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final predictionService = ref.read(categoryPredictionProvider);
    final predictedId = await predictionService.predictLikelyCategory();

    if (predictedId != null && mounted) {
      setState(() {
        _selectedCategoryId = predictedId;
        _isAiSuggested = true;
      });
    }
  }

  void _pressKey(String k) {
    HapticFeedback.lightImpact();
    setState(() {
      if (k == '⌫') {
        _amount = _amount.length <= 1 ? '0' : _amount.substring(0, _amount.length - 1);
      } else if (k == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        _amount = _amount == '0' ? k : _amount + k;
      }
    });
  }

  String get _formatted {
    final parts = _amount.split('.');
    final intPart = int.tryParse(parts[0]) ?? 0;
    final s = intPart.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return parts.length > 1 ? '$s.${parts[1]}' : s;
  }

  List<Account> _getUniqueAccounts(List<Account> accounts) {
    final unique = <String, Account>{};
    for (var acc in accounts) {
      if (!unique.containsKey(acc.name)) {
        unique[acc.name] = acc;
      } else {
        if (acc.id == _selectedWalletId || acc.id == _fromWalletId || acc.id == _toWalletId) {
          unique[acc.name] = acc;
        }
      }
    }
    return unique.values.toList();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showBudgetWarningDialog(String categoryName, double limit, double projectedTotal) {
    final lang = ref.read(languageProvider);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                ),
                const SizedBox(height: 20),
                Text(AppTranslations.getText('budget_exceeded', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                    children: [
                      TextSpan(text: '"$categoryName".\n\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Budget Limit: Rs. ${limit.toStringAsFixed(0)}\n', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      TextSpan(text: 'Projected Total: Rs. ${projectedTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text(AppTranslations.getText('cancel', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(AppTranslations.getText('save_anyway', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    final lang = ref.read(languageProvider);
    final amount = double.tryParse(_amount.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showSnackBar(AppTranslations.getText('valid_amount_err', lang), isError: true);
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final txDao = db.transactionDao;
    final catDao = db.categoryDao;
    final ruleDao = db.categoryRuleDao;

    final note = _noteCtrl.text.trim().isEmpty ? 'No Note' : _noteCtrl.text.trim();
    setState(() => _isLoading = true);

    try {
      if (_type == TxType.transfer) {
        if (_fromWalletId == null || _toWalletId == null) {
          _showSnackBar(AppTranslations.getText('wallet_err', lang), isError: true);
          return;
        }
        if (_fromWalletId == _toWalletId) {
          _showSnackBar('Cannot transfer to the same wallet!', isError: true);
          return;
        }

        if (widget.transactionToEdit != null) {
          await txDao.deleteTransactionAndReverseBalance(widget.transactionToEdit!.transaction);
        }
        await txDao.addTransfer(fromAccountId: _fromWalletId!, toAccountId: _toWalletId!, amount: amount, note: note, date: DateTime.now());

      } else {
        if (_selectedWalletId == null) {
          _showSnackBar(AppTranslations.getText('wallet_err', lang), isError: true);
          return;
        }
        if (_selectedCategoryId == null) {
          _showSnackBar(AppTranslations.getText('cat_err', lang), isError: true);
          return;
        }

        final isIncome = _type == TxType.income;
        final finalAmount = isIncome ? amount : -amount;

        if (!isIncome) {
          final category = await catDao.getCategoryById(_selectedCategoryId!);
          if (category.budgetLimit != null && category.budgetLimit! > 0) {
            final currentSpent = await txDao.getCurrentMonthSpentForCategory(_selectedCategoryId!);
            double oldAmount = widget.transactionToEdit != null ? widget.transactionToEdit!.transaction.amount.abs() : 0.0;
            final projectedTotal = currentSpent - oldAmount + amount;

            if (projectedTotal > category.budgetLimit!) {
              final proceed = await _showBudgetWarningDialog(category.name, category.budgetLimit!, projectedTotal);
              if (proceed != true) {
                setState(() => _isLoading = false);
                return;
              }
            }
          }
        }

        if (widget.transactionToEdit != null) {
          final oldTx = widget.transactionToEdit!.transaction;
          final updatedTx = TransactionsCompanion(
              description: drift.Value(note),
              amount: drift.Value(finalAmount),
              accountId: drift.Value(_selectedWalletId!),
              categoryId: drift.Value(_selectedCategoryId!)
          );
          await txDao.updateTransactionAndBalance(oldTx, updatedTx);

          if (!isIncome) {
            final rawMerchant = note.replaceFirst('SMS:', '').trim();
            await ruleDao.learnRule(rawMerchant, _selectedCategoryId!);
          }
        } else {
          final transaction = TransactionsCompanion.insert(
              description: note,
              amount: finalAmount,
              date: DateTime.now(),
              accountId: _selectedWalletId!,
              categoryId: drift.Value(_selectedCategoryId!),
              isRefund: const drift.Value(false)
          );
          await txDao.addTransactionAndUpdateBalance(transaction, _selectedWalletId!);
        }
      }

      if (mounted) {
        _showSnackBar(AppTranslations.getText(widget.transactionToEdit != null ? 'tx_updated' : 'tx_saved', lang), isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Bottom Sheets for Selections ---
  void _showSelectionSheet({
    required String title,
    required List<dynamic> items,
    required int? currentValue,
    required Function(int) onSelected,
    required String Function(dynamic) getName,
    required int Function(dynamic) getId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = getId(item);
                    final name = getName(item);
                    final isSelected = id == currentValue;

                    return ListTile(
                      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? _accent : (isDark ? Colors.white70 : Colors.black87))),
                      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: _accent) : null,
                      onTap: () {
                        onSelected(id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider);

    // Dynamic Colors based on Theme
    final bgColor = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF111827);
    final mutedFg = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Ambient gradient backdrop reacting to tx type
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.8),
                radius: 1.2,
                colors: [_accent.withOpacity(isDark ? 0.35 : 0.15), bgColor],
              ),
            ),
          ),
          // Soft blurred orbs
          Positioned(
            top: -80, right: -60,
            child: _Blur(color: _accent.withOpacity(isDark ? 0.5 : 0.2), size: 260),
          ),
          Positioned(
            top: 120, left: -80,
            child: _Blur(color: _accent.withOpacity(isDark ? 0.25 : 0.1), size: 220),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _topBar(fg, lang),
                    const SizedBox(height: 8),
                    _typeSelector(isDark, fg, lang),
                    const SizedBox(height: 28),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          children: [
                            _heroAmount(fg, mutedFg, isDark, lang),
                            const SizedBox(height: 32),

                            // Database Stream Builders for Wallet & Category
                            StreamBuilder<List<Account>>(
                                stream: ref.watch(accountDaoProvider).watchAllAccounts(),
                                builder: (context, accSnapshot) {
                                  final rawAccounts = accSnapshot.data ?? [];
                                  final accounts = _getUniqueAccounts(rawAccounts);

                                  return StreamBuilder<List<Category>>(
                                    stream: ref.watch(categoryDaoProvider).watchCategories(_type == TxType.income),
                                    builder: (context, catSnapshot) {
                                      final categories = catSnapshot.data ?? [];

                                      // Pre-select first wallet if null
                                      if (accounts.isNotEmpty && _selectedWalletId == null && _type != TxType.transfer) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) setState(() => _selectedWalletId = accounts.first.id);
                                        });
                                      }

                                      // Get Display Names (ආරක්ෂිත ක්‍රමය)
                                      String getWalletName(int? id) {
                                        final match = accounts.where((a) => a.id == id);
                                        return match.isNotEmpty ? match.first.name : AppTranslations.getText('select_wallet', lang);
                                      }
                                      String getCategoryName(int? id) {
                                        final match = categories.where((c) => c.id == id);
                                        return match.isNotEmpty ? match.first.name : AppTranslations.getText('select_category', lang);
                                      }

                                      return _detailsCard(
                                        cardColor: cardColor, fg: fg, mutedFg: mutedFg, isDark: isDark, lang: lang,
                                        walletName: getWalletName(_selectedWalletId),
                                        fromWalletName: getWalletName(_fromWalletId),
                                        toWalletName: getWalletName(_toWalletId),
                                        categoryName: getCategoryName(_selectedCategoryId),
                                        onWalletTap: () => _showSelectionSheet(
                                          title: AppTranslations.getText('select_wallet', lang),
                                          items: accounts, currentValue: _selectedWalletId,
                                          getName: (item) => (item as Account).name, getId: (item) => (item as Account).id,
                                          onSelected: (id) => setState(() => _selectedWalletId = id),
                                        ),
                                        onFromWalletTap: () => _showSelectionSheet(
                                          title: 'From Wallet', items: accounts, currentValue: _fromWalletId,
                                          getName: (item) => (item as Account).name, getId: (item) => (item as Account).id,
                                          onSelected: (id) => setState(() => _fromWalletId = id),
                                        ),
                                        onToWalletTap: () => _showSelectionSheet(
                                          title: 'To Wallet', items: accounts, currentValue: _toWalletId,
                                          getName: (item) => (item as Account).name, getId: (item) => (item as Account).id,
                                          onSelected: (id) => setState(() => _toWalletId = id),
                                        ),
                                        onCategoryTap: () => _showSelectionSheet(
                                          title: AppTranslations.getText('select_category', lang),
                                          items: categories, currentValue: _selectedCategoryId,
                                          getName: (item) => (item as Category).name, getId: (item) => (item as Category).id,
                                          onSelected: (id) => setState(() { _selectedCategoryId = id; _isAiSuggested = false; }),
                                        ),
                                      );
                                    },
                                  );
                                }
                            ),
                            const SizedBox(height: 20),
                            _keypad(fg),
                            const SizedBox(height: 20),
                            _saveButton(lang),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sub UI Widgets ---

  Widget _topBar(Color fg, String lang) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.close_rounded, color: fg.withOpacity(0.7)),
        ),
        const Spacer(),
        Text(widget.transactionToEdit != null ? AppTranslations.getText('edit_tx', lang) : 'New Transaction',
            style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        const Spacer(),
        const SizedBox(width: 48), // Balancing the close button
      ],
    ),
  );

  Widget _typeSelector(bool isDark, Color fg, String lang) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: TxType.values.map((t) {
                final active = t == _type;
                String label = '';
                if (t == TxType.expense) label = AppTranslations.getText('expense', lang);
                if (t == TxType.income) label = AppTranslations.getText('income', lang);
                if (t == TxType.transfer) label = AppTranslations.getText('transfer', lang);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _type = t;
                      if (t == TxType.expense && widget.transactionToEdit == null) _runAiPrediction();
                      else _isAiSuggested = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? t.color.withOpacity(0.18) : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: active ? t.color.withOpacity(0.6) : Colors.transparent),
                      boxShadow: active ? [BoxShadow(color: t.color.withOpacity(0.35), blurRadius: 18, spreadRadius: -2)] : [],
                    ),
                    child: Row(
                      children: [
                        Icon(t.icon, size: 16, color: active ? t.color : fg.withOpacity(0.6)),
                        const SizedBox(width: 6),
                        Text(label, style: TextStyle(color: active ? (isDark ? Colors.white : t.color) : fg.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroAmount(Color fg, Color mutedFg, bool isDark, String lang) {
    return Column(
      children: [
        Text(
          AppTranslations.getText('how_much', lang),
          style: TextStyle(color: mutedFg, fontSize: 14, letterSpacing: 0.4, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
          child: Row(
            key: ValueKey('$_type-$_formatted'),
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text('Rs.', style: TextStyle(color: _accent, fontSize: 22, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  colors: isDark ? [Colors.white, _accent.withOpacity(0.85)] : [fg, _accent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(r),
                child: Text(
                  _formatted,
                  style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard({
    required Color cardColor, required Color fg, required Color mutedFg, required bool isDark, required String lang,
    required String walletName, required String fromWalletName, required String toWalletName, required String categoryName,
    required VoidCallback onWalletTap, required VoidCallback onFromWalletTap, required VoidCallback onToWalletTap, required VoidCallback onCategoryTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _type == TxType.transfer
                    ? Column(
                  children: [
                    _row(icon: Icons.account_balance_wallet_rounded, label: 'From Wallet', value: fromWalletName, accent: _accent, fg: fg, mutedFg: mutedFg, onTap: onFromWalletTap),
                    _divider(isDark),
                    _row(icon: Icons.arrow_downward_rounded, label: 'To Wallet', value: toWalletName, accent: _accent, fg: fg, mutedFg: mutedFg, onTap: onToWalletTap),
                  ],
                )
                    : Column(
                  children: [
                    _row(icon: Icons.account_balance_wallet_rounded, label: 'Wallet', value: walletName, accent: _accent, fg: fg, mutedFg: mutedFg, onTap: onWalletTap),
                    _divider(isDark),
                    _row(icon: Icons.category_rounded, label: 'Category', value: categoryName, accent: _accent, fg: fg, mutedFg: mutedFg, trailing: _isAiSuggested && _type == TxType.expense ? const _AiPill() : null, onTap: onCategoryTap),
                  ],
                ),
              ),
              _divider(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: mutedFg.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.edit_note_rounded, color: mutedFg.withOpacity(0.8), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                        cursorColor: _accent,
                        decoration: InputDecoration(
                          isDense: true, border: InputBorder.none,
                          labelText: 'Note', labelStyle: TextStyle(color: mutedFg.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintText: AppTranslations.getText('add_note', lang), hintStyle: TextStyle(color: mutedFg.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({required IconData icon, required String label, required String value, required Color accent, required Color fg, required Color mutedFg, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: mutedFg, fontSize: 11, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: mutedFg.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04));

  Widget _keypad(Color fg) {
    const keys = ['1','2','3','4','5','6','7','8','9','.','0','⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2),
      itemBuilder: (_, i) {
        final k = keys[i];
        return Material(
          color: fg.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _pressKey(k),
            child: Center(child: Text(k, style: TextStyle(fontSize: k == '⌫' ? 20 : 22, fontWeight: FontWeight.w600, color: fg.withOpacity(0.9)))),
          ),
        );
      },
    );
  }

  Widget _saveButton(String lang) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity, height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.45), blurRadius: 28, spreadRadius: -4, offset: const Offset(0, 12))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isLoading ? null : _saveTransaction,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_type.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(AppTranslations.getText(widget.transactionToEdit != null ? 'edit' : 'save_tx', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiPill extends StatelessWidget {
  const _AiPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.5), blurRadius: 14, spreadRadius: -2)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 11)),
          SizedBox(width: 4),
          Text('AI Suggested', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _Blur extends StatelessWidget {
  final Color color; final double size;
  const _Blur({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 40)]),
      ),
    );
  }
}