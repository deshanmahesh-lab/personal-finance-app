import 'package:drift/drift.dart';
import '../datasources/app_database.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category? category;

  TransactionWithCategory(this.transaction, this.category);
}

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  Stream<List<Account>> watchAllAccounts() {
    return _db.select(_db.accounts).watch();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }

  Future<void> deleteAccount(Account account) {
    return _db.delete(_db.accounts).delete(account);
  }

  Future<Account> getAccountById(int id) {
    return (_db.select(_db.accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  Stream<double> watchTotalBalance() {
    return _db.select(_db.accounts).watch().map((accounts) {
      return accounts.fold(0.0, (previousValue, element) {
        return previousValue + element.initialBalance;
      });
    });
  }

  // ===========================================================================
  // [NEW] RESET APP DATA
  // ===========================================================================
  Future<void> resetAllData() async {
    await _db.transaction(() async {
      // 1. සියලුම ගනුදෙනු සම්පූර්ණයෙන්ම මකා දැමීම
      await _db.delete(_db.transactions).go();

      // 2. සියලුම ගිණුම්වල ශේෂය නැවත 0.0 බවට පත් කිරීම
      await _db.update(_db.accounts).write(const AccountsCompanion(initialBalance: Value(0.0)));
    });
  }

  // ===========================================================================
  // DYNAMIC BALANCE CALCULATION
  // ===========================================================================
  Future<void> _recalculateBalance(int accountId) async {
    final outgoingTxs = await (_db.select(_db.transactions)
      ..where((t) => t.accountId.equals(accountId))).get();

    final incomingTransfers = await (_db.select(_db.transactions)
      ..where((t) => t.transferToAccountId.equals(accountId))).get();

    double calculatedBalance = 0.0;

    for (var tx in outgoingTxs) {
      calculatedBalance += tx.amount;
    }

    for (var tx in incomingTransfers) {
      calculatedBalance += tx.amount.abs();
    }

    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(initialBalance: Value(calculatedBalance)));
  }

  // ===========================================================================
  // CORE TRANSACTION LOGIC
  // ===========================================================================

  Future<void> addTransactionAndUpdateBalance({
    required TransactionsCompanion transaction,
    required int accountId,
    required double amount,
    required bool isIncome,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(transaction);
      await _recalculateBalance(accountId);
    });
  }

  Future<void> updateTransactionAndBalance({
    required Transaction oldTx,
    required TransactionsCompanion updatedTx,
    required double newAmountAbs,
    required bool isIncome,
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.transactions)
        ..where((t) => t.id.equals(oldTx.id)))
          .write(updatedTx);

      await _recalculateBalance(oldTx.accountId);

      final newAccountId = updatedTx.accountId.present ? updatedTx.accountId.value : oldTx.accountId;
      if (oldTx.accountId != newAccountId) {
        await _recalculateBalance(newAccountId);
      }
    });
  }

  Future<void> deleteTransactionAndReverseBalance(Transaction tx) async {
    await _db.transaction(() async {
      await _db.delete(_db.transactions).delete(tx);
      await _recalculateBalance(tx.accountId);

      if (tx.isTransfer && tx.transferToAccountId != null) {
        await _recalculateBalance(tx.transferToAccountId!);
      }
    });
  }

  // ===========================================================================
  // ADVANCED EDGE CASES (Transfers & Refunds)
  // ===========================================================================

  Future<void> addTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        description: note,
        amount: -amount,
        date: date,
        accountId: fromAccountId,
        isTransfer: const Value(true),
        transferToAccountId: Value(toAccountId),
      ));

      await _recalculateBalance(fromAccountId);
      await _recalculateBalance(toAccountId);
    });
  }

  Future<void> addRefund({
    required int originalTxId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    await _db.transaction(() async {
      final origTx = await (_db.select(_db.transactions)..where((t) => t.id.equals(originalTxId))).getSingle();

      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        description: note,
        amount: amount,
        date: date,
        accountId: origTx.accountId,
        categoryId: Value(origTx.categoryId),
        isRefund: const Value(true),
        refundedTransactionId: Value(originalTxId),
      ));

      await _recalculateBalance(origTx.accountId);
    });
  }

  // ===========================================================================
  // CATEGORY & SUMMARY QUERIES
  // ===========================================================================

  Stream<List<Category>> watchCategories(bool isIncome) {
    return (_db.select(_db.categories)
      ..where((c) => c.isIncome.equals(isIncome) & c.isActive.equals(true)))
        .watch();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Future<Category> getCategoryById(int id) {
    return (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingle();
  }

  Stream<List<TransactionWithCategory>> watchTransactionsWithCategories() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ])..orderBy([OrderingTerm(expression: _db.transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(row.readTable(_db.transactions), row.readTableOrNull(_db.categories));
      }).toList();
    });
  }

  Stream<List<TransactionWithCategory>> watchTransactionsByDateRange(DateTime start, DateTime end) {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ])
      ..where(_db.transactions.date.isBiggerOrEqualValue(start) & _db.transactions.date.isSmallerThanValue(end))
      ..orderBy([OrderingTerm(expression: _db.transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(row.readTable(_db.transactions), row.readTableOrNull(_db.categories));
      }).toList();
    });
  }

  Stream<Map<String, double>> watchCategorySummary(bool isIncome, DateTime start, DateTime end) {
    return watchTransactionsByDateRange(start, end).map((items) {
      final Map<String, double> summary = {};

      for (var item in items) {
        final tx = item.transaction;
        final cat = item.category;

        if (tx.isTransfer) continue;

        final categoryName = cat?.name ?? 'Uncategorized';

        if (tx.isRefund && !isIncome) {
          summary[categoryName] = (summary[categoryName] ?? 0) - tx.amount.abs();
        } else if (!tx.isRefund) {
          final bool txIsIncome = tx.amount >= 0;
          if (txIsIncome == isIncome) {
            summary[categoryName] = (summary[categoryName] ?? 0) + tx.amount.abs();
          }
        }
      }
      summary.removeWhere((key, value) => value <= 0);
      return summary;
    });
  }

  Stream<Map<int, double>> watchMonthlySummary(int year, bool isIncome) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    return watchTransactionsByDateRange(startOfYear, endOfYear).map((items) {
      final Map<int, double> summary = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var item in items) {
        final tx = item.transaction;
        if (tx.isTransfer) continue;

        final month = tx.date.month;

        if (tx.isRefund && !isIncome) {
          summary[month] = (summary[month] ?? 0) - tx.amount.abs();
        } else if (!tx.isRefund) {
          final bool txIsIncome = tx.amount >= 0;
          if (txIsIncome == isIncome) {
            summary[month] = (summary[month] ?? 0) + tx.amount.abs();
          }
        }
      }
      return summary;
    });
  }

  Future<double> getCurrentMonthSpentForCategory(int categoryId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final query = _db.select(_db.transactions)
      ..where((t) =>
      t.categoryId.equals(categoryId) &
      t.date.isBiggerOrEqualValue(startOfMonth) &
      t.date.isSmallerThanValue(endOfMonth));

    final result = await query.get();
    double totalSpent = 0.0;

    for (var tx in result) {
      if (tx.isTransfer) continue;
      if (tx.isRefund) {
        totalSpent -= tx.amount.abs();
      } else if (tx.amount < 0) {
        totalSpent += tx.amount.abs();
      }
    }
    return totalSpent < 0 ? 0 : totalSpent;
  }

  Stream<Map<String, double>> watchMonthlyCashFlow(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    final query = _db.select(_db.transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(startOfMonth) & t.date.isSmallerThanValue(endOfMonth));

    return query.watch().map((transactions) {
      double income = 0;
      double expense = 0;
      for (var tx in transactions) {
        if (tx.isTransfer) continue;

        if (tx.isRefund) {
          expense -= tx.amount.abs();
        } else if (tx.amount >= 0) {
          income += tx.amount;
        } else {
          expense += tx.amount.abs();
        }
      }

      if (expense < 0) expense = 0;
      return {'income': income, 'expense': expense};
    });
  }
}