import 'dart:ui';
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
  static const Color kPrimary = Color(0xFF182D92);
  static const Color kLightBg = Color(0xFFFCFDFC);
  static const Color kDarkBg = Color(0xFF121212);

  int _selectedIndex = 0;

  // අපගේ සැබෑ තිරයන් (Screens) 3
  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    ManageCategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. තේරූ භාෂාව ලබා ගැනීම සහ මාතෘකා/ලේබල් පරිවර්තනය කිරීම
    final currentLang = ref.watch(languageProvider);

    final List<String> titles = [
      AppTranslations.getText('title_dashboard', currentLang),
      AppTranslations.getText('title_analytics', currentLang),
      AppTranslations.getText('title_categories', currentLang),
    ];

    // Navigation Bar එකේ අයිකන සහ ඒවායේ පරිවර්තනය වූ නම්
    final List<_NavItem> navItems = [
      _NavItem(icon: Icons.home_rounded, label: AppTranslations.getText('nav_home', currentLang)),
      _NavItem(icon: Icons.pie_chart_rounded, label: AppTranslations.getText('nav_analytics', currentLang)),
      _NavItem(icon: Icons.category_rounded, label: AppTranslations.getText('nav_categories', currentLang)),
    ];

    // 2. වර්ණ සහ තේමා සැකසුම්
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? kDarkBg : kLightBg;
    final titleColor = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: bg,
      // සම්පූර්ණ තිරයම භාවිත කිරීම සඳහා Bottom SafeArea ඉවත් කර ඇත
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 32.0 : 20.0;

            return Stack(
              children: [
                Column(
                  children: [
                    // අපගේ Custom App Bar එක
                    _buildAppBar(context, isDark, titleColor, horizontalPadding, titles[_selectedIndex]),

                    // සැබෑ තිරයේ අන්තර්ගතය (IndexedStack හරහා)
                    Expanded(
                      child: Padding(
                        // Navigation Bar එකට යටින් අන්තර්ගතය නොපෙනී යාම වැළැක්වීමට පහළට 120px padding එකක් දී ඇත
                        padding: EdgeInsets.fromLTRB(
                          0, // තිරයේ සම්පූර්ණ පළල ලබා ගැනීමට horizontal padding ඉවත් කළෙමි
                          8,
                          0,
                          120,
                        ),
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _screens,
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating Frosted Glass Bottom Navigation Bar එක
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 400 : double.infinity,
                          ),
                          child: _buildBottomNav(isDark, navItems),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // අලංකාර Custom App Bar සැකිල්ල
  Widget _buildAppBar(
      BuildContext context,
      bool isDark,
      Color titleColor,
      double horizontalPadding,
      String currentTitle,
      ) {
    final iconBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 8),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                currentTitle, // පරිවර්තනය වූ මාතෘකාව
                key: ValueKey(currentTitle),
                style: TextStyle(
                  color: titleColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ),

          // Settings බොත්තම
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  // Settings තිරය වෙත යාම
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen())
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(
                    Icons.settings_outlined,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Navigation Bar සැකිල්ල
  Widget _buildBottomNav(bool isDark, List<_NavItem> items) {
    final barBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.75);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: barBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : kPrimary.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: _selectedIndex == i,
                  isDark: isDark,
                  primary: kPrimary,
                  onTap: () => setState(() => _selectedIndex = i), // Tab එක වෙනස් කිරීම
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// Data Model Class
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// Navigation Bar හි ඇති තනි බොත්තමක්
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = isDark ? Colors.white60 : const Color(0xFF8A8F98);
    final activeColor = primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: selected ? activeColor : inactive,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeColor : inactive,
                letterSpacing: 0.1,
              ),
              child: Text(item.label),
            ),
            const SizedBox(height: 5),
            // Active Indicator (කුඩා තිත/ඉර)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: selected ? 1 : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: 4,
                width: selected ? 16 : 0,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}