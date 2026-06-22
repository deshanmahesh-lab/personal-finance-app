import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'theme_configuration_screen.dart';

class SecuritySetupScreen extends ConsumerStatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  ConsumerState<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends ConsumerState<SecuritySetupScreen>
    with SingleTickerProviderStateMixin {
  bool _isAppLockEnabled = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const Color primaryBlue = Color(0xFF182D92);
  static const Color lightBackground = Color(0xFFFCFDFC);

  @override
  void initState() {
    super.initState();
    // Glowing Effect එක සඳහා Animation Controller එක
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. තේරූ භාෂාවට අදාළව තිරයේ වචන (Translations) ලබා ගැනීම
    final currentLanguage = ref.watch(languageProvider);
    final mainTitle = AppTranslations.getText('secure_data_title', currentLanguage);
    final subTitle = AppTranslations.getText('secure_data_desc', currentLanguage);
    final lockTitle = AppTranslations.getText('enable_app_lock', currentLanguage);
    final lockDesc = AppTranslations.getText('app_lock_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    // 2. අලංකාර වර්ණ සැකසුම් (Light / Dark Mode සඳහා)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : lightBackground;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: primaryBlue,
                      size: 22,
                    ),
                    splashRadius: 24,
                  ),

                  const SizedBox(height: 32),

                  // Visual Hero (Glowing Fingerprint)
                  Center(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildRing(180 * _pulseAnimation.value, primaryBlue.withOpacity(0.06)),
                              _buildRing(150 * _pulseAnimation.value, primaryBlue.withOpacity(0.10)),
                              _buildRing(120 * _pulseAnimation.value, primaryBlue.withOpacity(0.14)),
                              Container(
                                height: 96,
                                width: 96,
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fingerprint,
                                  color: primaryBlue,
                                  size: 48,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Toggle Card (මුළු Card එකම Click කළ හැක)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAppLockEnabled = !_isAppLockEnabled;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isAppLockEnabled
                            ? primaryBlue.withOpacity(0.05)
                            : isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isAppLockEnabled
                              ? primaryBlue
                              : isDark
                              ? Colors.white24
                              : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: _isAppLockEnabled
                                  ? primaryBlue.withOpacity(0.12)
                                  : isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _isAppLockEnabled
                                  ? Icons.fingerprint
                                  : Icons.lock_outline,
                              color: _isAppLockEnabled
                                  ? primaryBlue
                                  : isDark
                                  ? Colors.white60
                                  : const Color(0xFF9CA3AF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lockTitle,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lockDesc,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: subtitleColor,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAppLockEnabled,
                            onChanged: (value) {
                              setState(() {
                                _isAppLockEnabled = value;
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: primaryBlue,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: isDark
                                ? Colors.white24
                                : const Color(0xFFD1D5DB),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // 1. තේරූ සැකසුම Provider හරහා දුරකථනයේ ස්ථිරව Save කිරීම
                            ref.read(appLockProvider.notifier).setLock(_isAppLockEnabled);

                            // 2. ඊළඟ තිරයට යාම (Theme Configuration Screen)
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ThemeConfigurationScreen())
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white24,
                          child: Center(
                            child: Text(
                              btnText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Animation එක සඳහා පිටුපසින් නිර්මාණය වන Rings (වළලු)
  Widget _buildRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 1.2,
        ),
      ),
    );
  }
}