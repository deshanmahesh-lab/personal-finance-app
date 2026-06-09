import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/account_repository_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _transactionType = 'expense';
  int? _selectedCategoryId; // අලුතින් එක් කළ Category ID විචල්‍යය
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);

    // 1. Amount Validation
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount!');
      return;
    }

    // 2. Category Validation
    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Please select a category!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isIncome = _transactionType == 'income';
      final note = _noteController.text.trim().isEmpty ? 'No Note' : _noteController.text.trim();
      final finalAmount = isIncome ? amount : -amount;

      // Database එකට Category ID එකද යැවීම
      final transaction = TransactionsCompanion.insert(
        description: note,
        amount: finalAmount,
        date: DateTime.now(),
        accountId: 1,
        categoryId: drift.Value(_selectedCategoryId!), // <--- drift.Value එකතු කළා
        isRefund: const drift.Value(false),
      );

      await ref.read(accountRepositoryProvider).addTransactionAndUpdateBalance(
        transaction: transaction,
        accountId: 1,
        amount: amount,
        isIncome: isIncome,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Transaction Saved Successfully!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
            elevation: 6,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Error පෙන්වීමේ කේතය වෙනම Function එකකට ගැනීම (Code Cleanliness)
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Database එකේ Query එක සඳහා boolean අගය
    final isIncome = _transactionType == 'income';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_transactionType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _transactionType = newSelection.first;
                  _selectedCategoryId = null; // Income/Expense මාරු වන විට Category එක Reset කිරීම
                });
              },
            ),
            const SizedBox(height: 24),

            // --- අලුත් කොටස: Category Dropdown ---
            StreamBuilder<List<Category>>(
              stream: ref.watch(accountRepositoryProvider).watchCategories(isIncome),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];

                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a category'),
                  items: categories.map((category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (Rs.)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}