import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/category_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(AppDatabase db) : super(db);

  Stream<List<Category>> watchCategories(bool isIncome) {
    return (select(categories)
      ..where((c) => c.isIncome.equals(isIncome) & c.isActive.equals(true)))
        .watch();
  }

  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<Category> getCategoryById(int id) {
    return (select(categories)..where((c) => c.id.equals(id))).getSingle();
  }
}