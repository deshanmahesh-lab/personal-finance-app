import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/app_database.dart';

// Manual Provider - Code Generation අවශ්‍ය නැත
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});