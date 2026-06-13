import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isIncome => boolean()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // --- අලුතින් එක් කළ තීරුව: අයවැය සීමාව (Budget Limit) ---
  RealColumn get budgetLimit => real().nullable()();
}