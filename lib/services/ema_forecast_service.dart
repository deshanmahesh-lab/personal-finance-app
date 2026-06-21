import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/daos/transaction_dao.dart';
import '../presentation/providers/database_provider.dart';

class ForecastResult {
  final double currentSpent;
  final double forecastedTotal;
  final double currentVelocity; // EMA මගින් ගණනය කළ දෛනික වියදම් වේගය

  ForecastResult({
    required this.currentSpent,
    required this.forecastedTotal,
    required this.currentVelocity,
  });
}

class EmaForecastService {
  final TransactionDao _txDao;

  EmaForecastService(this._txDao);

  Future<ForecastResult> getMonthlyForecast() async {
    final now = DateTime.now();
    // 1. TransactionDao හරහා දෛනික වියදම් ලබාගැනීම
    final dailyExpenses = await _txDao.getDailyExpensesForMonth(now);

    int currentDay = now.day;
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    double totalSpentSoFar = 0.0;
    double ema = 0.0;

    // 2. EMA Smoothing Factor ගණනය (N = 3)
    // N=3 ලෙස ගැනීමෙන් මෑතකදී කළ වියදම් වලට (උදා: ඊයේ සහ පෙරේදා) වැඩි බරක් ලබා දෙයි.
    // මෙය හදිසි වියදම් ඉහළ යාම් (Splurges) ඉක්මනින් හඳුනාගැනීමට උපකාරී වේ.
    int n = 3;
    double alpha = 2.0 / (n + 1);

    // 3. මාසයේ 1 වැනිදා සිට අද දක්වා EMA අගය යාවත්කාලීන කිරීම
    for (int day = 1; day <= currentDay; day++) {
      double dailySpent = dailyExpenses[day] ?? 0.0;
      totalSpentSoFar += dailySpent;

      if (day == 1) {
        ema = dailySpent; // පළමු දිනයේ EMA අගය එහි වියදමම වේ
      } else {
        // EMA සූත්‍රය: (Today_Value * Alpha) + (Yesterday_EMA * (1 - Alpha))
        ema = (dailySpent * alpha) + (ema * (1 - alpha));
      }
    }

    // 4. ඉතිරි දින සඳහා අනුමානය (Forecasting)
    int remainingDays = daysInMonth - currentDay;
    double forecastedTotal = totalSpentSoFar + (ema * remainingDays);

    return ForecastResult(
      currentSpent: totalSpentSoFar,
      forecastedTotal: forecastedTotal,
      currentVelocity: ema,
    );
  }
}

// UI එකට සම්බන්ධ කිරීම සඳහා Riverpod Provider
final emaForecastProvider = Provider<EmaForecastService>((ref) {
  return EmaForecastService(ref.watch(transactionDaoProvider));
});