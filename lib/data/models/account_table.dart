import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 100)(); // e.g., 'BOC Salary Account', 'My Wallet', 'Kamal Debt'

  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();

  TextColumn get type => text()(); // e.g., 'bank', 'cash', 'debt_virtual'
}