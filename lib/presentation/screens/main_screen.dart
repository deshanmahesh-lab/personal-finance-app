import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'manage_categories_screen.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    ManageCategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);

    final List<String> titles = [
      AppTranslations.getText('title_dashboard', currentLang),
      AppTranslations.getText('title_analytics', currentLang),
      AppTranslations.getText('title_categories', currentLang),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() { _selectedIndex = index; });
        },
        destinations: [
          NavigationDestination(
            selectedIcon: const Icon(Icons.home), icon: const Icon(Icons.home_outlined),
            label: AppTranslations.getText('nav_home', currentLang),
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.pie_chart), icon: const Icon(Icons.pie_chart_outline),
            label: AppTranslations.getText('nav_analytics', currentLang),
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.category), icon: const Icon(Icons.category_outlined),
            label: AppTranslations.getText('nav_categories', currentLang),
          ),
        ],
      ),
    );
  }
}