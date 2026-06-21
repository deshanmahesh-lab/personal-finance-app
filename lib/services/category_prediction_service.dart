import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/daos/transaction_dao.dart';
import '../data/datasources/daos/category_dao.dart';
import '../presentation/providers/database_provider.dart';

class CategoryPredictionService {
  final TransactionDao _txDao;
  final CategoryDao _catDao;

  CategoryPredictionService(this._txDao, this._catDao);

  Future<int?> predictLikelyCategory() async {
    final categories = await _catDao.watchCategories(false).first; // වියදම් කාණ්ඩ පමණි
    if (categories.isEmpty) return null;

    final now = DateTime.now();
    final currentHour = now.hour;

    // 1. අතීත ගනුදෙනු ලබාගැනීම (මාසයක් ඇතුළත)
    final recentTransactions = await _txDao.watchTransactionsByDateRange(
        now.subtract(const Duration(days: 30)),
        now
    ).first;

    // 2. අදාළ කාල සීමාව (Time Window) තුළ සිදුවූ වියදම්වල Category IDs වෙන් කරගැනීම (Time-based History)
    // උදා: දැන් වෙලාව දවල් 1 නම්, දවල් 11 ත් හවස 3 ත් අතර අතීතයේ සිදුවූ වියදම් සෙවීම
    Map<int, int> categoryFrequency = {};

    for (var item in recentTransactions) {
      final tx = item.transaction;
      if (tx.isTransfer || tx.amount >= 0 || tx.categoryId == null) continue;

      final txHour = tx.date.hour;
      // පැය 4ක පරාසයක් (Time Window: ±2 hours)
      if ((txHour - currentHour).abs() <= 2) {
        int catId = tx.categoryId!;
        categoryFrequency[catId] = (categoryFrequency[catId] ?? 0) + 1;
      }
    }

    // 3. අදාළ කාලය තුළ ඉහළම වාර ගණනක් (Most Frequent) භාවිතා කළ Category එක තේරීම
    if (categoryFrequency.isNotEmpty) {
      var sortedEntries = categoryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)); // වැඩිම එක උඩට ගැනීම

      return sortedEntries.first.key;
    }

    // 4. Fallback (අතීත දත්ත නොමැති අලුත් User කෙනෙක් නම් වේලාවට අදාළව සාමාන්‍ය අනුමානයක් කිරීම)
    String keywordToMatch = '';
    if (currentHour >= 6 && currentHour <= 10) {
      keywordToMatch = 'transport'; // උදෑසන ගමන් බිමන්
    } else if (currentHour >= 12 && currentHour <= 14) {
      keywordToMatch = 'food'; // දවල් කෑම
    } else if (currentHour >= 17 && currentHour <= 21) {
      keywordToMatch = 'grocery'; // හවස බඩු ගෙනීම
    } else {
      keywordToMatch = 'food'; // සාමාන්‍ය අගය
    }

    // Keyword එකට ගැලපෙන Category එකක් Database එකේ ඇත්දැයි බැලීම
    try {
      final fallbackCategory = categories.firstWhere(
              (c) => c.name.toLowerCase().contains(keywordToMatch)
      );
      return fallbackCategory.id;
    } catch (_) {
      // කිසිවක් ගැලපෙන්නේ නැත්නම් පළමු Category එක තේරීම
      return categories.first.id;
    }
  }
}

// UI එකට සම්බන්ධ කිරීමට Provider එක
final categoryPredictionProvider = Provider<CategoryPredictionService>((ref) {
  return CategoryPredictionService(
    ref.watch(transactionDaoProvider),
    ref.watch(categoryDaoProvider),
  );
});