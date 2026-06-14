import 'package:drift/drift.dart';
import 'category_table.dart';
import 'account_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();

  // [Fix] ReferenceName එකතු කර ඇත
  @ReferenceName('mainAccount')
  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get categoryId => integer().nullable().references(Categories, #id)();

  BoolColumn get isTransfer => boolean().withDefault(const Constant(false))();

  // [Fix] ReferenceName එකතු කර ඇත
  @ReferenceName('transferAccount')
  IntColumn get transferToAccountId => integer().nullable().references(Accounts, #id)();

  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  IntColumn get refundedTransactionId => integer().nullable().references(Transactions, #id)();
}