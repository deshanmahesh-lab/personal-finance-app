import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'bank_setup_screen.dart';

class ThemeConfigurationScreen extends ConsumerStatefulWidget {
  const ThemeConfigurationScreen({super.key});

  @override
  ConsumerState<ThemeConfigurationScreen> createState() =>
      _ThemeConfigurationScreenState();
}

class _ThemeConfigurationScreenState extends ConsumerState<ThemeConfigurationScreen>
    with SingleTickerProviderStateMixin {

  // AI ගේ ThemeOption වෙනුවට අපගේ නිල ThemeMode යොදාගැනීම
  ThemeMode _selectedTheme = ThemeMode.system;

  static const Color primaryBlue = Color(0xFF182D92);
  static const Color lightBackground = Color(0xFFFCFDFC);
  static const Color darkBackground = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    // 1. තේරූ භාෂාවට අදාළව තිරයේ වචන (Translations) ලබා ගැනීම
    final currentLanguage = ref.watch(languageProvider);
    final mainTitle = AppTranslations.getText('choose_theme', currentLanguage);
    final subTitle = AppTranslations.getText('choose_theme_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);
    final lightText = AppTranslations.getText('light_mode', currentLanguage);
    final darkText = AppTranslations.getText('dark_mode', currentLanguage);
    final systemText = AppTranslations.getText('system_default', currentLanguage);

    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? darkBackground : lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 22,
                      color: primaryBlue,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(height: 32),

                  // Title (Translated)
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle (Translated)
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Theme Cards
                  _ThemeCard(
                    mode: ThemeMode.light,
                    icon: Icons.light_mode,
                    title: lightText,
                    isSelected: _selectedTheme == ThemeMode.light,
                    onTap: () {
                      setState(() => _selectedTheme = ThemeMode.light);
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.light); // සජීවීව තේමාව වෙනස් කිරීම
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  _ThemeCard(
                    mode: ThemeMode.dark,
                    icon: Icons.dark_mode,
                    title: darkText,
                    isSelected: _selectedTheme == ThemeMode.dark,
                    onTap: () {
                      setState(() => _selectedTheme = ThemeMode.dark);
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark); // සජීවීව තේමාව වෙනස් කිරීම
                    },
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  _ThemeCard(
                    mode: ThemeMode.system,
                    icon: Icons.settings_system_daydream,
                    title: systemText,
                    isSelected: _selectedTheme == ThemeMode.system,
                    onTap: () {
                      setState(() => _selectedTheme = ThemeMode.system);
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.system); // සජීවීව තේමාව වෙනස් කිරීම
                    },
                    isDark: isDark,
                  ),

                  const Spacer(),

                  // Continue Button
                  _ContinueButton(
                    btnText: btnText,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BankSetupScreen()),
                      );
                    },
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
}

class _ThemeCard extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.mode,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? _ThemeConfigurationScreenState.primaryBlue
        : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB));

    final Color backgroundColor = isSelected
        ? _ThemeConfigurationScreenState.primaryBlue.withOpacity(
      isDark ? 0.12 : 0.05,
    )
        : Colors.transparent;

    final Color iconColor = isSelected
        ? _ThemeConfigurationScreenState.primaryBlue
        : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));

    final Color titleColor = isSelected
        ? (isDark ? Colors.white : const Color(0xFF111827))
        : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: _ThemeConfigurationScreenState.primaryBlue.withOpacity(0.08),
          highlightColor: _ThemeConfigurationScreenState.primaryBlue.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _ThemeConfigurationScreenState.primaryBlue
                        .withOpacity(0.1)
                        : (isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: iconColor,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _ThemeConfigurationScreenState.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String btnText;
  final VoidCallback onTap;

  const _ContinueButton({required this.btnText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _ThemeConfigurationScreenState.primaryBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _ThemeConfigurationScreenState.primaryBlue.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                btnText,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}