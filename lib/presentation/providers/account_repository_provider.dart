import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/account_repository.dart';
import 'database_provider.dart';

// Manual Provider - Code Generation අවශ්‍ය නැත
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountRepository(db);
});