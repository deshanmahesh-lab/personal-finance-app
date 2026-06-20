import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_selection_screen.dart';
import '../main_screen.dart';
// [නව වෙනස] LockScreen එක Import කිරීම
import '../lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingCompleted = prefs.getBool('isOnboardingCompleted') ?? false;

    if (isOnboardingCompleted) {
      // [නව වෙනස] LockScreen එක මඟින් MainScreen එක විවෘත කිරීම
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.account_balance_wallet_rounded, size: 120, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Personal Finance',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const Spacer(),
            const Text(
              'POWERED BY DESHAN MAHESH',
              style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 2.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}