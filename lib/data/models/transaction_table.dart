import 'package:drift/drift.dart';
import 'category_table.dart';
import 'account_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text().withLength(min: 1, max: 255)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();

  // Foreign Keys (සම්බන්ධිත වගු)
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();

  // මුදල් පිටවන ගිණුම (Source Account)
  @ReferenceName('outgoingTransactions')
  IntColumn get accountId => integer().references(Accounts, #id)();

  // මුදල් ලැබෙන ගිණුම (Destination Account - Transfers/Debts සඳහා පමණි)
  @ReferenceName('incomingTransactions')
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();

  // Refunds කළමනාකරණය සඳහා
  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  IntColumn get parentTransactionId => integer().nullable()();
}