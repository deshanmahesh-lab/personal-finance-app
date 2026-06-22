import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../main_screen.dart';
import '../lock_screen.dart';
import '../../providers/language_provider.dart';
import '../../providers/database_provider.dart';
import '../../../utils/app_translations.dart';
import '../../../data/datasources/app_database.dart';

class InitializationScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;
  final Map<String, double> initialBalances;

  const InitializationScreen({
    super.key,
    required this.selectedBanks,
    required this.initialBalances,
  });

  @override
  ConsumerState<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with TickerProviderStateMixin {

  static const Color kPrimaryBlue = Color(0xFF182D92);
  static const Color kLightBg = Color(0xFFFCFDFC);
  static const Color kDarkBg = Color(0xFF121212);

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  Timer? _progressTimer;

  double _progress = 0.0;
  String _currentStatus = ''; // Dynamic Status Text

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // AI හි තිබූ බොරු ටයිමරය (Mock processing) වෙනුවට අපගේ සැබෑ Database ක්‍රියාවලිය කැඳවමු
    _startActualInitialization();
  }

  // අපගේ සැබෑ (Actual) Database ලොජික් එක
  Future<void> _startActualInitialization() async {
    final currentLanguage = ref.read(languageProvider);
    final db = ref.read(appDatabaseProvider);

    // ප්‍රගති තීරුව (Progress Bar) පිරවීම සඳහා වූ Timer එක
    const tick = Duration(milliseconds: 40);
    const totalEstimatedMs = 3500; // සම්පූර්ණ ක්‍රියාවලිය තත්පර 3.5ක් පමණ ගනී යැයි උපකල්පනය කරමු
    final increment = tick.inMilliseconds / totalEstimatedMs;

    _progressTimer = Timer.periodic(tick, (t) {
      if (mounted) {
        setState(() {
          _progress += increment;
          if (_progress >= 0.95) { // 95% ට පමණක් සීමා කරමු, අවසානයේ 100% කරමු
            _progress = 0.95;
          }
        });
      }
    });

    // 1. Wallets නිර්මාණය කිරීම ආරම්භය
    if (mounted) {
      setState(() => _currentStatus = AppTranslations.getText('setting_wallets', currentLanguage));
    }
    await _setupInitialWallets(db);

    // 2. දත්ත සුරැකීමේ පියවර
    if (mounted) {
      setState(() => _currentStatus = AppTranslations.getText('saving_data', currentLanguage));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboardingCompleted', true);
    await prefs.setStringList('selectedBanks', widget.selectedBanks);
    await prefs.setString('last_sms_sync_time', DateTime.now().toIso8601String());

    // 3. අවසන් කිරීම
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _progress = 1.0; // 100%
        _currentStatus = AppTranslations.getText('ready', currentLanguage);
      });
    }

    // සුමට බව පෙන්වීමට 100% වූ පසු සුළු වෙලාවක් (තත්පර 1ක් පමණ) රැඳී සිටිමු
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    // Navigation Stack එක හිස් කර Main Screen එකට යාම
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LockScreen(child: MainScreen())),
          (Route<dynamic> route) => false,
    );
  }

  // Wallet Duplication සහ Balance Reset Bug එක නිවැරදි කර ඇති පැරණි ශ්‍රිතය
  Future<void> _setupInitialWallets(AppDatabase db) async {
    final accountDao = db.accountDao;
    final txDao = db.transactionDao;

    // Cash Wallet
    if (widget.initialBalances.containsKey('cash')) {
      final double amount = widget.initialBalances['cash']!;
      final accId = await accountDao.getOrCreateAccount('My Wallet', 'cash');

      if (amount > 0) {
        await _injectInitialBalanceTransaction(txDao, accId, amount);
      }
    }

    // Bank Wallets
    final Map<String, String> bankOfficialNames = {
      'boc': 'Bank of Ceylon',
      'nsb': 'National Savings Bank',
      'peoples': 'Peoples Bank',
    };

    for (var bankId in widget.selectedBanks) {
      if (widget.initialBalances.containsKey(bankId)) {
        final double amount = widget.initialBalances[bankId]!;
        final bankName = bankOfficialNames[bankId] ?? bankId.toUpperCase();

        final accId = await accountDao.getOrCreateAccount(bankName, 'bank');

        if (amount > 0) {
          await _injectInitialBalanceTransaction(txDao, accId, amount);
        }
      }
    }
  }

  // Initial Balance එක System Transaction එකක් ලෙස Database එකට යැවීම
  Future<void> _injectInitialBalanceTransaction(dynamic txDao, int accId, double amount) async {
    await txDao.addTransactionAndUpdateBalance(
        TransactionsCompanion.insert(
          description: 'Initial Balance',
          amount: amount,
          date: DateTime.now(),
          accountId: accId,
          isTransfer: const drift.Value(true),
          categoryId: const drift.Value(null),
        ),
        accId
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? kDarkBg : kLightBg;
    final primaryText = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final subtitleText = (isDark ? Colors.white : Colors.black).withOpacity(0.55);
    final progressTrack = (isDark ? Colors.white : kPrimaryBlue).withOpacity(0.08);

    final pleaseWaitText = AppTranslations.getText('please_wait', currentLanguage);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final horizontalPadding = isTablet ? 80.0 : 28.0;
            final iconSize = isTablet ? 140.0 : 108.0;
            final maxContentWidth = isTablet ? 520.0 : 420.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingIcon(
                        animation: _pulseAnimation,
                        size: iconSize,
                        color: kPrimaryBlue,
                      ),
                      SizedBox(height: isTablet ? 56 : 44),

                      // Dynamic Status Message (Translated)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
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
                          _currentStatus.isNotEmpty ? _currentStatus : 'Loading...',
                          key: ValueKey(_currentStatus),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isTablet ? 26 : 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: primaryText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        pleaseWaitText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 15 : 13.5,
                          fontWeight: FontWeight.w400,
                          color: subtitleText,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: isTablet ? 56 : 44),

                      // Elegant Progress Bar
                      _ElegantProgressBar(
                        progress: _progress,
                        trackColor: progressTrack,
                        fillColor: kPrimaryBlue,
                      ),

                      const SizedBox(height: 14),

                      // Percentage
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: subtitleText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// AI හි Pulsing Icon සැකිල්ල
class _PulsingIcon extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const _PulsingIcon({
    required this.animation,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value; // 0..1
        return SizedBox(
          width: size * 2.2,
          height: size * 2.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding ring
              Container(
                width: size * (1.7 + 0.35 * t),
                height: size * (1.7 + 0.35 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.05 * (1 - t)),
                ),
              ),
              // Middle ring
              Container(
                width: size * (1.35 + 0.2 * t),
                height: size * (1.35 + 0.2 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.08 + 0.04 * (1 - t)),
                ),
              ),
              // Inner ring
              Container(
                width: size * (1.05 + 0.08 * t),
                height: size * (1.05 + 0.08 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.10),
                ),
              ),
              // Core icon container
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      Color.lerp(color, Colors.black, 0.25)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35 + 0.15 * t),
                      blurRadius: 32 + 16 * t,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_moon_rounded,
                  size: size * 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// AI හි ProgressBar සැකිල්ල
class _ElegantProgressBar extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final Color fillColor;

  const _ElegantProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: width * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: LinearGradient(
                    colors: [
                      fillColor.withOpacity(0.85),
                      fillColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fillColor.withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}