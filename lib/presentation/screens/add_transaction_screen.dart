import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import '../../data/datasources/daos/transaction_dao.dart';
// [නව වෙනස] Prediction Service එක import කිරීම
import '../../services/category_prediction_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionWithCategory? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _transactionType = 'expense';
  int? _selectedCategoryId;
  int? _selectedWalletId;
  int? _fromWalletId;
  int? _toWalletId;

  bool _isLoading = false;
  bool _isAiSuggested = false; // [නව වෙනස] AI ලේබලය පෙන්වීමට

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!.transaction;
      _amountController.text = tx.amount.abs().toStringAsFixed(0);
      _noteController.text = tx.description;

      if (tx.isTransfer) {
        _transactionType = 'transfer';
        _fromWalletId = tx.accountId;
        _toWalletId = tx.transferToAccountId;
      } else {
        _transactionType = tx.amount >= 0 ? 'income' : 'expense';
        _selectedCategoryId = tx.categoryId;
        _selectedWalletId = tx.accountId;
      }
    } else {
      // [නව වෙනස] අලුත් වියදමක් නම් AI මගින් Category එක අනුමාන කිරීම
      _runAiPrediction();
    }
  }

  // [නව වෙනස] AI Prediction Function එක
  Future<void> _runAiPrediction() async {
    // ගණනය කිරීම් සඳහා කුඩා වේලාවක් ලබා දීම
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
                Text(AppTranslations.getText('budget_exceeded', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar(AppTranslations.getText('valid_amount_err', lang), isError: true);
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final txDao = db.transactionDao;
    final catDao = db.categoryDao;
    final ruleDao = db.categoryRuleDao;

    final note = _noteController.text.trim().isEmpty ? 'No Note' : _noteController.text.trim();
    setState(() { _isLoading = true; });

    try {
      if (_transactionType == 'transfer') {
        if (_fromWalletId == null || _toWalletId == null) {
          _showSnackBar(AppTranslations.getText('wallet_err', lang), isError: true);
          return;
        }
        if (_fromWalletId == _toWalletId) {
          _showSnackBar('Cannot transfer to the same wallet!', isError: true);
          return;
        }

        if (widget.transactionToEdit != null) await txDao.deleteTransactionAndReverseBalance(widget.transactionToEdit!.transaction);

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

        final isIncome = _transactionType == 'income';
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
                setState(() { _isLoading = false; });
                return;
              }
            }
          }
        }

        if (widget.transactionToEdit != null) {
          final oldTx = widget.transactionToEdit!.transaction;
          final updatedTx = TransactionsCompanion(description: drift.Value(note), amount: drift.Value(finalAmount), accountId: drift.Value(_selectedWalletId!), categoryId: drift.Value(_selectedCategoryId!));
          await txDao.updateTransactionAndBalance(oldTx, updatedTx);

          if (!isIncome) {
            final rawMerchant = note.replaceFirst('SMS:', '').trim();
            await ruleDao.learnRule(rawMerchant, _selectedCategoryId!);
          }
        } else {
          final transaction = TransactionsCompanion.insert(description: note, amount: finalAmount, date: DateTime.now(), accountId: _selectedWalletId!, categoryId: drift.Value(_selectedCategoryId!), isRefund: const drift.Value(false));
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
      if (mounted) setState(() { _isLoading = false; });
    }
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    Color primaryColor;
    if (_transactionType == 'income') primaryColor = Colors.green.shade600;
    else if (_transactionType == 'transfer') primaryColor = Colors.blue.shade600;
    else primaryColor = Colors.red.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Expanded(child: _buildSimpleTab(AppTranslations.getText('expense', lang), _transactionType == 'expense', () {
                setState(() {
                  _transactionType = 'expense';
                  // Type එක මාරු කරද්දී අලුතින්ම AI Prediction එකක් ගන්නවා
                  if (widget.transactionToEdit == null) _runAiPrediction();
                });
              })),
              Expanded(child: _buildSimpleTab(AppTranslations.getText('income', lang), _transactionType == 'income', () {
                setState(() {
                  _transactionType = 'income';
                  _isAiSuggested = false; // Income වලට AI නෑ
                });
              })),
              Expanded(child: _buildSimpleTab(AppTranslations.getText('transfer', lang), _transactionType == 'transfer', () {
                setState(() {
                  _transactionType = 'transfer';
                  _isAiSuggested = false; // Transfers වලට AI නෑ
                });
              })),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                children: [
                  Text(AppTranslations.getText('how_much', lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: primaryColor),
                    decoration: InputDecoration(
                      border: InputBorder.none, hintText: '0',
                      prefixText: 'Rs. ',
                      prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primaryColor.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                    child: Column(
                      children: [
                        StreamBuilder<List<Account>>(
                          stream: ref.watch(accountDaoProvider).watchAllAccounts(),
                          builder: (context, snapshot) {
                            final rawAccounts = snapshot.data ?? [];
                            final accounts = _getUniqueAccounts(rawAccounts);

                            if (_transactionType == 'transfer') {
                              return Column(
                                children: [
                                  DropdownButtonFormField<int>(
                                    value: _fromWalletId,
                                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.account_balance_wallet_outlined), contentPadding: EdgeInsets.all(16)),
                                    hint: Text(AppTranslations.getText('from_wallet', lang)),
                                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                                    onChanged: (v) => setState(() => _fromWalletId = v),
                                  ),
                                  Divider(height: 1, indent: 56, color: Colors.grey.withOpacity(0.2)),
                                  DropdownButtonFormField<int>(
                                    value: _toWalletId,
                                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.account_balance_rounded), contentPadding: EdgeInsets.all(16)),
                                    hint: Text(AppTranslations.getText('to_wallet', lang)),
                                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                                    onChanged: (v) => setState(() => _toWalletId = v),
                                  ),
                                ],
                              );
                            } else {
                              if (accounts.isNotEmpty && _selectedWalletId == null) {
                                _selectedWalletId = accounts.first.id;
                              }

                              return Column(
                                children: [
                                  DropdownButtonFormField<int>(
                                    value: _selectedWalletId,
                                    decoration: const InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.account_balance_wallet_outlined), contentPadding: EdgeInsets.all(16)),
                                    hint: Text(AppTranslations.getText('select_wallet', lang)),
                                    items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                                    onChanged: (v) => setState(() => _selectedWalletId = v),
                                  ),
                                  Divider(height: 1, indent: 56, color: Colors.grey.withOpacity(0.2)),
                                  StreamBuilder<List<Category>>(
                                    stream: ref.watch(categoryDaoProvider).watchCategories(_transactionType == 'income'),
                                    builder: (context, catSnapshot) {
                                      final categories = catSnapshot.data ?? [];
                                      return DropdownButtonFormField<int>(
                                        value: _selectedCategoryId,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(Icons.category_outlined),
                                          contentPadding: const EdgeInsets.all(16),
                                          // [නව වෙනස] AI ලේබලය පෙන්වීම
                                          suffix: _isAiSuggested && _transactionType == 'expense'
                                              ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                            child: const Text('✨ AI Suggested', style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                              : null,
                                        ),
                                        hint: Text(AppTranslations.getText('select_category', lang)),
                                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedCategoryId = v;
                                            _isAiSuggested = false; // User විසින් වෙනස් කළහොත් AI ලේබලය මකා දමයි
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        Divider(height: 1, indent: 56, color: Colors.grey.withOpacity(0.2)),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(border: InputBorder.none, prefixIcon: const Icon(Icons.notes_rounded), hintText: AppTranslations.getText('add_note', lang), contentPadding: const EdgeInsets.all(16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  onPressed: _isLoading ? null : _saveTransaction,
                  child: Text(AppTranslations.getText('save_tx', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.grey.shade600)),
            ),
          ),
        ),
      ),
    );
  }
}