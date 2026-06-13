import 'package:drift/drift.dart';
import 'category_table.dart';
import 'account_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();

  // මූලික ගිණුම සහ කාණ්ඩය
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)(); // Transfers සඳහා කාණ්ඩයක් නැති නිසා මෙය null විය හැක

  // --- Advanced Edge Cases සඳහා අලුත් තීරු ---

  // 1. Transfers (ATM Withdrawals ආදිය) සඳහා
  BoolColumn get isTransfer => boolean().withDefault(const Constant(false))();
  IntColumn get transferToAccountId => integer().nullable().references(Accounts, #id)();

  // 2. Refunds (මුදල් ආපසු ලැබීම්) සඳහා
  BoolColumn get isRefund => boolean().withDefault(const Constant(false))();
  IntColumn get refundedTransactionId => integer().nullable().references(Transactions, #id)(); // මුල් ගනුදෙනුවට සම්බන්ධ කිරීම
}