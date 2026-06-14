import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/app_database.dart';
import '../../data/datasources/daos/account_dao.dart';
import '../../data/datasources/daos/category_dao.dart';
import '../../data/datasources/daos/transaction_dao.dart';

// 1. Core Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close()); // Proper cleanup
  return db;
});

// 2. Account DAO Provider
final accountDaoProvider = Provider<AccountDao>((ref) {
  return ref.watch(appDatabaseProvider).accountDao;
});

// 3. Category DAO Provider
final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(appDatabaseProvider).categoryDao;
});

// 4. Transaction DAO Provider
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(appDatabaseProvider).transactionDao;
});