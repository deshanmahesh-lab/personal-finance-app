import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/main_screen.dart';

void main() {
  // Riverpod State Management ක්‍රියාත්මක වීමට නම්,
  // මුළු App එකම ProviderScope එකකින් ආවරණය කිරීම අනිවාර්ය වේ.
  runApp(
    const ProviderScope(
      child: PersonalFinanceApp(),
    ),
  );
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextGen Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // ප්‍රධාන වර්ණය
        useMaterial3: true,
      ),
      home: const MainScreen(), // මුල් පිටුව
    );
  }
}