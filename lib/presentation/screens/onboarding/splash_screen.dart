import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_selection_screen.dart';
import '../main_screen.dart';
import '../lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // අපගේ නවතම වර්ණ මාලාව
  static const Color _primaryBlue = Color(0xFF182D92);
  static const Color _pureWhite = Color(0xFFFCFDFC);

  @override
  void initState() {
    super.initState();

    // 1. ඇනිමේෂන් එක ආරම්භ කිරීම
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuart,
      ),
    );

    _controller.forward();

    // 2. පැරණි කේතයේ තිබූ Routing Logic එක කැඳවීම
    _navigateToNext();
  }

  // අපගේ පැරණි තත්පර 3ක ක්‍රියාවලිය සහ ගමන් කිරීම
  Future<void> _navigateToNext() async {
    // තත්පර 1.5 කින් Animation එක අවසන් වී, තවත් තත්පර 1.5 ක් Logo එක පැහැදිලිව පෙනී සිටී
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingCompleted = prefs.getBool('isOnboardingCompleted') ?? false;

    if (isOnboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LockScreen(child: MainScreen())),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBlue,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: const Center(
            child: Text(
              'PFA',
              style: TextStyle(
                fontFamily: 'Continuum BC',
                fontSize: 76,
                fontWeight: FontWeight.bold,
                color: _pureWhite,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text(
            'POWERED BY NEXIGEN',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              // Premium පෙනුමක් සඳහා Opacity 60% ක් ලබා දී ඇත
              color: _pureWhite.withOpacity(0.6),
              letterSpacing: 3.5,
            ),
          ),
        ),
      ),
    );
  }
}