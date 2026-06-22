import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'permissions_screen.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  // තාවකාලිකව තෝරාගෙන ඇති භාෂාව (පෙරනිමිය: English)
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {
      'code': 'English',
      'native': 'English',
      'translation': 'English',
      'letter': 'A',
    },
    {
      'code': 'සිංහල',
      'native': 'සිංහල',
      'translation': 'Sinhala',
      'letter': 'අ',
    },
    {
      'code': 'தமிழ்',
      'native': 'தமிழ்',
      'translation': 'Tamil',
      'letter': 'அ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 1. තේරූ භාෂාවට අදාළව තිරයේ වචන (Translations) ලබා ගැනීම
    final mainTitle = AppTranslations.getText('select_language', _selectedLanguage);
    final subTitle = AppTranslations.getText('language_desc', _selectedLanguage);
    final btnText = AppTranslations.getText('continue_btn', _selectedLanguage);

    // 2. අලංකාර වර්ණ සැකසුම් (Light / Dark Mode සඳහා)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF182D92);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFCFDFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111111);
    final textSecondary = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);

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
                  const SizedBox(height: 40),

                  // මාතෘකාව (Translated)
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // උප මාතෘකාව (Translated)
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // භාෂා ලැයිස්තුව
                  ..._languages.map((language) {
                    final isSelected = _selectedLanguage == language['code'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // කාඩ්පත එබූ විට භාෂාව තාවකාලිකව වෙනස් වේ
                            _selectedLanguage = language['code']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue.withOpacity(0.05) : backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryBlue
                                  : isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE5E5E5),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryBlue.withOpacity(0.1)
                                        : isDark
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFFF5F5F5),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    language['letter']!,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? primaryBlue : textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        language['native']!,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        language['translation']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkmark ඇනිමේෂන් එක
                                AnimatedOpacity(
                                  opacity: isSelected ? 1 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: AnimatedScale(
                                    scale: isSelected ? 1 : 0.6,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
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
                  }),

                  const Spacer(),

                  // Continue බොත්තම
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      child: ElevatedButton(
                        onPressed: () {
                          // 1. තේරූ භාෂාව Provider හරහා දුරකථනයේ ස්ථිරව Save කිරීම
                          ref.read(languageProvider.notifier).setLanguage(_selectedLanguage);

                          // 2. ඊළඟ තිරයට යාම (Permissions Screen)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PermissionsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: Text(btnText), // Translated Button Text
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
}