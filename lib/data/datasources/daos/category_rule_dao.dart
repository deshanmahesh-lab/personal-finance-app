import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/category_rule_table.dart';
import '../../models/category_table.dart';

part 'category_rule_dao.g.dart';

@DriftAccessor(tables: [CategoryRules, Categories])
class CategoryRuleDao extends DatabaseAccessor<AppDatabase> with _$CategoryRuleDaoMixin {
  CategoryRuleDao(AppDatabase db) : super(db);

  // සියලුම Rules ඒවායේ ප්‍රමුඛතාවය (Priority/Length) අනුව අනුපිළිවෙලින් ලබා ගැනීම
  Future<List<CategoryRule>> getAllRulesSorted() async {
    return await (select(categoryRules)
      ..orderBy([(t) => OrderingTerm(expression: t.priorityScore, mode: OrderingMode.desc)]))
        .get();
  }

  // පරිශීලකයා විසින් කාණ්ඩය වෙනස් කළ විට අලුත් Rule එකක් ඉගෙනීම (Self-Learning)
  Future<void> learnRule(String rawMerchant, int categoryId) async {
    // අනවශ්‍ය හිස්තැන් සහ සංකේත ඉවත් කර පිරිසිදු කිරීම
    final normalizedKey = rawMerchant.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s]'), '');

    if (normalizedKey.isEmpty) return;

    await into(categoryRules).insert(
      CategoryRulesCompanion.insert(
        merchantKey: normalizedKey,
        categoryId: categoryId,
        priorityScore: normalizedKey.length, // වචනයේ දිග priority එක ලෙස ගනී
        matchCount: const Value(1),
      ),
      mode: InsertMode.insertOrReplace, // කලින් තිබුණොත් එය Update කරයි
    );
  }

  // Rule එකක් පාවිච්චි කළ සෑම විටම එහි විශ්වාසනීයත්වය (matchCount) වැඩි කිරීම
  Future<void> incrementMatchCount(String merchantKey) async {
    final rule = await (select(categoryRules)..where((t) => t.merchantKey.equals(merchantKey))).getSingleOrNull();
    if (rule != null) {
      await (update(categoryRules)..where((t) => t.merchantKey.equals(merchantKey)))
          .write(CategoryRulesCompanion(matchCount: Value(rule.matchCount + 1)));
    }
  }
}