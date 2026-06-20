import 'package:drift/drift.dart';
import 'category_table.dart';

@DataClassName('CategoryRule')
class CategoryRules extends Table {
  // SMS එකෙන් වෙන් කරගන්නා පිරිසිදු වචනය (උදා: 'KEELLS SUPER')
  TextColumn get merchantKey => text()();

  // එය අදාළ විය යුතු Category එක (Foreign Key)
  IntColumn get categoryId => integer().references(Categories, #id)();

  // වචනයේ දිග (දිගු වචන වලට ප්‍රමුඛතාවය වැඩියි. උදා: 'KEELLS SUPER' > 'KEELLS')
  IntColumn get priorityScore => integer()();

  // කොපමණ වාර ගණනක් මේ නීතිය සාර්ථකව පාවිච්චි වුණාද (Confidence level)
  IntColumn get matchCount => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {merchantKey};
}