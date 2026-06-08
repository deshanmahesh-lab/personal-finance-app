import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().nullable()(); // Stores icon identifier string
  TextColumn get color => text().nullable()(); // Stores Hex color code string
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
}