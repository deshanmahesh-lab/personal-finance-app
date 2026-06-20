import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/transaction_table.dart';
import '../../models/category_table.dart';
import '../../models/account_table.dart';

part 'transaction_dao.g.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category? category;
  TransactionWithCategory(this.transaction, this.category);
}

@DriftAccessor(tables: [Transactions, Categories, Accounts])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(AppDatabase db) : super(db);

  // --- Core Transaction Logic ---
  Future<void> addTransactionAndUpdateBalance(TransactionsCompanion transaction, int accountId) async {
    await this.transaction(() async {
      await into(transactions).insert(transaction);
      await db.accountDao.recalculateBalance(accountId);
    });
  }

  Future<void> updateTransactionAndBalance(Transaction oldTx, TransactionsCompanion updatedTx) async {
    await this.transaction(() async {
      await (update(transactions)..where((t) => t.id.equals(oldTx.id))).write(updatedTx);
      await db.accountDao.recalculateBalance(oldTx.accountId);

      final newAccountId = updatedTx.accountId.present ? updatedTx.accountId.value : oldTx.accountId;
      if (oldTx.accountId != newAccountId) {
        await db.accountDao.recalculateBalance(newAccountId);
      }
    });
  }

  Future<void> deleteTransactionAndReverseBalance(Transaction tx) async {
    await this.transaction(() async {
      await delete(transactions).delete(tx);
      await db.accountDao.recalculateBalance(tx.accountId);

      if (tx.isTransfer && tx.transferToAccountId != null) {
        await db.accountDao.recalculateBalance(tx.transferToAccountId!);
      }
    });
  }

  // --- Advanced Edge Cases (Transfers & Refunds) ---
  Future<void> addTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    await this.transaction(() async {
      await into(transactions).insert(TransactionsCompanion.insert(
        description: note,
        amount: -amount,
        date: date,
        accountId: fromAccountId,
        isTransfer: const Value(true),
        transferToAccountId: Value(toAccountId),
      ));
      await db.accountDao.recalculateBalance(fromAccountId);
      await db.accountDao.recalculateBalance(toAccountId);
    });
  }

  Future<void> addRefund({
    required int originalTxId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    await this.transaction(() async {
      final origTx = await (select(transactions)..where((t) => t.id.equals(originalTxId))).getSingle();

      await into(transactions).insert(TransactionsCompanion.insert(
        description: note,
        amount: amount,
        date: date,
        accountId: origTx.accountId,
        categoryId: Value(origTx.categoryId),
        isRefund: const Value(true),
        refundedTransactionId: Value(originalTxId),
      ));
      await db.accountDao.recalculateBalance(origTx.accountId);
    });
  }

  // --- Watchers & Base Queries ---
  Stream<List<TransactionWithCategory>> watchTransactionsWithCategories() {
    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])..orderBy([OrderingTerm(expression: transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) => TransactionWithCategory(row.readTable(transactions), row.readTableOrNull(categories))).toList();
    });
  }

  Stream<List<TransactionWithCategory>> watchTransactionsByDateRange(DateTime start, DateTime end) {
    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(transactions.date.isBiggerOrEqualValue(start) & transactions.date.isSmallerThanValue(end))
      ..orderBy([OrderingTerm(expression: transactions.date, mode: OrderingMode.desc)]);

    return query.watch().map((rows) {
      return rows.map((row) => TransactionWithCategory(row.readTable(transactions), row.readTableOrNull(categories))).toList();
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

    final query = select(transactions)
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

    final query = select(transactions)
      ..where((t) => t.date.isBiggerOrEqualValue(startOfMonth) & t.date.isSmallerThanValue(endOfMonth));

    return query.watch().map((txs) {
      double income = 0;
      double expense = 0;
      for (var tx in txs) {
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

  Future<void> resetAllData() async {
    await this.transaction(() async {
      await delete(transactions).go();
      await db.accountDao.resetAllAccounts();
    });
  }

  // --- BUG 1 FIXED: High-Precision Duplicate Checking ---
  Future<bool> isTransactionExists(double amount, String description, DateTime date) async {
    // පළමු අකුරු 5 සහ දවස පරීක්ෂා කිරීම ඉවත් කර ඇත.
    // ඒ වෙනුවට SMS එක පැමිණි නිශ්චිත වේලාව (විනාඩියක පරතරයක් සහිතව) සහ මුදල පරීක්ෂා කරයි.
    final windowStart = date.subtract(const Duration(minutes: 1));
    final windowEnd = date.add(const Duration(minutes: 1));

    final query = select(transactions)
      ..where((t) =>
      t.amount.equals(amount) &
      t.date.isBiggerOrEqualValue(windowStart) &
      t.date.isSmallerThanValue(windowEnd));

    final results = await query.get();
    return results.isNotEmpty;
  }
}