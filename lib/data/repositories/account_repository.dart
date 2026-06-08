import '../datasources/app_database.dart';

class AccountRepository {
  final AppDatabase _db;

  AccountRepository(this._db);

  // සජීවීව සියලුම ගිණුම් ලබා ගැනීම (Reactive Stream)
  Stream<List<Account>> watchAllAccounts() {
    return _db.select(_db.accounts).watch();
  }

  // අලුත් ගිණුමක් එකතු කිරීම
  Future<int> insertAccount(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }

  // ගිණුමක් මකා දැමීම
  Future<void> deleteAccount(Account account) {
    return _db.delete(_db.accounts).delete(account);
  }
}