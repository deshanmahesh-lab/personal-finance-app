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

  Future<void> addTransactionAndUpdateBalance({
    required TransactionsCompanion transaction,
    required int accountId,
    required double amount,
    required bool isIncome,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(transaction);

      final account = await (_db.select(_db.accounts)
        ..where((a) => a.id.equals(accountId)))
          .getSingle();

      final newBalance = isIncome
          ? account.initialBalance + amount
          : account.initialBalance - amount;

      await (_db.update(_db.accounts)
        ..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(initialBalance: Value(newBalance)));
    });
  }

  Future<void> deleteTransactionAndReverseBalance(Transaction tx) async {
    await _db.transaction(() async {
      final account = await (_db.select(_db.accounts)
        ..where((a) => a.id.equals(tx.accountId)))
          .getSingle();

      final newBalance = account.initialBalance - tx.amount;

      await (_db.update(_db.accounts)
        ..where((a) => a.id.equals(account.id)))
          .write(AccountsCompanion(initialBalance: Value(newBalance)));

      await _db.delete(_db.transactions).delete(tx);
    });
  }

  Stream<List<Category>> watchCategories(bool isIncome) {
    return (_db.select(_db.categories)
      ..where((c) => c.isIncome.equals(isIncome) & c.isActive.equals(true)))
        .watch();
  }

  Stream<List<TransactionWithCategory>> watchTransactionsWithCategories() {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
          _db.categories,
          _db.categories.id.equalsExp(_db.transactions.categoryId)
      ),
    ])..orderBy([OrderingTerm(expression: _db.transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(_db.transactions),
          row.readTableOrNull(_db.categories),
        );
      }).toList();
    });
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return _db.into(_db.categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return _db.update(_db.categories).replace(category);
  }

  Stream<List<TransactionWithCategory>> watchTransactionsByDateRange(DateTime start, DateTime end) {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(
          _db.categories,
          _db.categories.id.equalsExp(_db.transactions.categoryId)
      ),
    ])
      ..where(_db.transactions.date.isBiggerOrEqualValue(start) & _db.transactions.date.isSmallerThanValue(end))
      ..orderBy([OrderingTerm(expression: _db.transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(_db.transactions),
          row.readTableOrNull(_db.categories),
        );
      }).toList();
    });
  }

  Stream<Map<String, double>> watchCategorySummary(bool isIncome, DateTime start, DateTime end) {
    return watchTransactionsByDateRange(start, end).map((items) {
      final Map<String, double> summary = {};

      for (var item in items) {
        final tx = item.transaction;
        final cat = item.category;

        final bool txIsIncome = tx.amount >= 0;

        if (txIsIncome == isIncome) {
          final categoryName = cat?.name ?? 'Uncategorized';
          summary[categoryName] = (summary[categoryName] ?? 0) + tx.amount.abs();
        }
      }
      return summary;
    });
  }

  // --- අලුත් කොටස: වසරකට අදාළව මාස 12 සඳහා දත්ත සාරාංශගත කිරීම (Bar Chart සඳහා) ---
  Stream<Map<int, double>> watchMonthlySummary(int year, bool isIncome) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    return watchTransactionsByDateRange(startOfYear, endOfYear).map((items) {
      // මාස 12 සඳහා මූලිකව බිංදුව (0.0) සකසයි
      final Map<int, double> summary = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var item in items) {
        final tx = item.transaction;
        final bool txIsIncome = tx.amount >= 0;

        if (txIsIncome == isIncome) {
          final month = tx.date.month;
          summary[month] = (summary[month] ?? 0) + tx.amount.abs();
        }
      }
      return summary;
    });
  }
}