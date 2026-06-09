import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isIncome => boolean()();

  // අලුතින් එක් කළ තීරුව: Category එක Active ද යන්න සටහන් කරයි
  // Default අගය true වන බැවින් අලුතින් සාදන සියලු Categories සක්‍රීය (Active) වේ.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}