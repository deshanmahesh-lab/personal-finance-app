import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'manage_categories_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // මුලින්ම විවෘත වන විට පෙන්විය යුතු තිරයේ අංකය (0 = Dashboard)
  int _selectedIndex = 0;

  // පහළ බොත්තම් වලට අදාළ තිර ලැයිස්තුව
  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    ManageCategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack භාවිතා කරන්නේ අප එක් තිරයකින් තව එකකට යන විට
      // පරණ තිරයේ දත්ත Refresh නොවී එලෙසම තබා ගැනීමටයි (State preservation)
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // නවීන Material 3 Bottom Navigation Bar එක
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.pie_chart),
            icon: Icon(Icons.pie_chart_outline),
            label: 'Analytics',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.category),
            icon: Icon(Icons.category_outlined),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}