import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/account_table.dart';
import '../../models/transaction_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts, Transactions])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(AppDatabase db) : super(db);

  Stream<List<Account>> watchAllAccounts() {
    return select(accounts).watch();
  }

  Future<int> insertAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  Future<void> deleteAccount(Account account) {
    return delete(accounts).delete(account);
  }

  Future<Account> getAccountById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  // [නව වෙනස] Wallet එකක් Duplicate වීම වැළැක්වීමේ Smart Function එක
  Future<int> getOrCreateAccount(String name, String type) async {
    final existing = await (select(accounts)..where((a) => a.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;

    return await into(accounts).insert(
        AccountsCompanion.insert(name: name, type: type, initialBalance: const Value(0.0))
    );
  }

  Stream<double> watchTotalBalance() {
    return select(accounts).watch().map((accountsList) {
      return accountsList.fold(0.0, (sum, item) => sum + item.initialBalance);
    });
  }

  // [PERFORMANCE FIX] - Dart loops ඉවත් කර සම්පූර්ණ ගණනය කිරීම SQL වලට මාරු කිරීම
  Future<void> recalculateBalance(int accountId) async {
    final query = await customSelect(
      '''
      SELECT 
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE account_id = ?) +
        (SELECT COALESCE(SUM(ABS(amount)), 0) FROM transactions WHERE transfer_to_account_id = ?) 
      AS total_balance
      ''',
      variables: [Variable.withInt(accountId), Variable.withInt(accountId)],
    ).getSingle();

    final calculatedBalance = query.read<double>('total_balance');

    await (update(accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(initialBalance: Value(calculatedBalance)));
  }

  // [නව වෙනස] පැරණි Accounts වල balance එක 0 කරනවා වෙනුවට සම්පූර්ණයෙන්ම මකා දැමීම
  Future<void> resetAllAccounts() async {
    await delete(accounts).go();
  }
}