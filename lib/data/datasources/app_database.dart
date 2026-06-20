import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/category_table.dart';
import '../models/account_table.dart';
import '../models/transaction_table.dart';
import '../models/category_rule_table.dart'; // [නව වෙනස] අලුත් Table එක import කිරීම

import 'daos/account_dao.dart';
import 'daos/category_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/category_rule_dao.dart'; // [නව වෙනස] අලුත් DAO එක import කිරීම

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Categories, Accounts, Transactions, CategoryRules], // [නව වෙනස]
  daos: [AccountDao, CategoryDao, TransactionDao, CategoryRuleDao], // [නව වෙනස]
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  // [නව වෙනස] පැරණි අගය 2 වූ බැවින්, මෙය 3 ලෙස යාවත්කාලීන කර ඇත
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.addColumn(transactions, transactions.isTransfer);
          await m.addColumn(transactions, transactions.transferToAccountId);
          await m.addColumn(transactions, transactions.isRefund);
          await m.addColumn(transactions, transactions.refundedTransactionId);
        }
        // [නව වෙනස] Version 3 වෙත Update වීමේදී අලුත් Table එක නිර්මාණය කිරීම
        if (from < 3) {
          await m.createTable(categoryRules);
        }
      },
    );
  }

  Future<void> _seedInitialData() async {
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(name: 'Food & Dining', icon: const Value('restaurant'), isIncome: false),
        CategoriesCompanion.insert(name: 'Transport', icon: const Value('directions_bus'), isIncome: false),
        CategoriesCompanion.insert(name: 'Shopping', icon: const Value('shopping_cart'), isIncome: false),
        CategoriesCompanion.insert(name: 'Salary', icon: const Value('payments'), isIncome: true),
        CategoriesCompanion.insert(name: 'Other Income', icon: const Value('add_card'), isIncome: true),
      ]);
    });

    await into(accounts).insert(
        AccountsCompanion.insert(
          name: 'My Wallet',
          type: 'cash',
          initialBalance: const Value(0.0),
        )
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}