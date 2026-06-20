import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [නව වෙනස] SharedPreferences import කිරීම
import 'package:workmanager/workmanager.dart';
import 'utils/notification_service.dart';
import 'data/datasources/app_database.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/screens/onboarding/splash_screen.dart';
import 'presentation/providers/shared_prefs_provider.dart'; // [නව වෙනස] අලුත් provider එක import කිරීම

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final now = DateTime.now();
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

      if (now.day == lastDayOfMonth && now.hour >= 18) {
        await NotificationService().init();

        final db = AppDatabase();
        final txDao = db.transactionDao;

        final cashFlowStream = txDao.watchMonthlyCashFlow(now);
        final data = await cashFlowStream.first;

        final income = data['income'] ?? 0.0;
        final expense = data['expense'] ?? 0.0;
        final balance = income - expense;

        final monthName = _getMonthName(now.month);
        final title = '📊 $monthName Summary';
        final body = 'Income: Rs. ${income.toStringAsFixed(0)} | Expense: Rs. ${expense.toStringAsFixed(0)}\nNet Balance: Rs. ${balance.toStringAsFixed(0)}';

        await NotificationService().showMonthlySummary(title, body);

        await db.close();
      }
    } catch (e) {
      debugPrint("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}

// [නව වෙනස] main ශ්‍රිතය async කිරීම
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [නව වෙනස] App එක පෙන්වන්න කලින් Memory එක කියවා අවසන් කරයි
  final prefs = await SharedPreferences.getInstance();

  _initServicesBackground();

  runApp(
    ProviderScope(
      overrides: [
        // [නව වෙනස] කියවාගත් Memory එක මුළු App එකටම ලබා දෙයි
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PersonalFinanceApp(),
    ),
  );
}

Future<void> _initServicesBackground() async {
  await NotificationService().init();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "monthly_summary_task_id",
    "monthly_summary_task",
    frequency: const Duration(hours: 12),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: true,
    ),
  );
}

class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Personal Finance',
      themeMode: themeMode,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}