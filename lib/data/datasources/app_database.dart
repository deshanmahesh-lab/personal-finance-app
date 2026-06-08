import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/category_table.dart';
import '../models/account_table.dart';
import '../models/transaction_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Accounts, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // පළමු වරට Database එක සෑදෙන විට ක්‍රියාත්මක වන කොටස
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // 1. වගු (Tables) සියල්ල නිර්මාණය කිරීම
        await m.createAll();

        // 2. මූලික Categories ඇතුළත් කිරීම (Batch Insert)
        await batch((batch) {
          batch.insertAll(categories, [
            CategoriesCompanion.insert(name: 'Food & Dining', icon: const Value('restaurant'), isIncome: const Value(false)),
            CategoriesCompanion.insert(name: 'Transport', icon: const Value('directions_bus'), isIncome: const Value(false)),
            CategoriesCompanion.insert(name: 'Shopping', icon: const Value('shopping_cart'), isIncome: const Value(false)),
            CategoriesCompanion.insert(name: 'Salary', icon: const Value('payments'), isIncome: const Value(true)),
            CategoriesCompanion.insert(name: 'Other Income', icon: const Value('add_card'), isIncome: const Value(true)),
          ]);
        });

        // 3. මූලික Wallet එක ඇතුළත් කිරීම
        await into(accounts).insert(
            AccountsCompanion.insert(
              name: 'My Wallet',
              type: 'cash',
              initialBalance: const Value(0.0),
            )
        );
      },
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