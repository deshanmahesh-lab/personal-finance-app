import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'initial_balances_screen.dart';

class BankSetupScreen extends ConsumerStatefulWidget {
  const BankSetupScreen({super.key});

  @override
  ConsumerState<BankSetupScreen> createState() => _BankSetupScreenState();
}

class _BankSetupScreenState extends ConsumerState<BankSetupScreen> {
  // අපගේ සැබෑ දත්ත (අලංකාර වර්ණ සහ අයිකන සමඟින්)
  final List<Map<String, dynamic>> _banks = const [
    {
      'id': 'boc',
      'name': 'Bank of Ceylon',
      'code': 'BOC',
      'icon': Icons.account_balance_rounded,
      'tint': Color(0xFFFFF8E1),
      'iconColor': Color(0xFFEFC100),
    },
    {
      'id': 'nsb',
      'name': 'National Savings Bank',
      'code': 'NSB',
      'icon': Icons.savings_rounded,
      'tint': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFF9800),
    },
    {
      'id': 'peoples',
      'name': 'Peoples Bank',
      'code': 'Peoples',
      'icon': Icons.account_balance_wallet_rounded,
      'tint': Color(0xFFFFEBEE),
      'iconColor': Color(0xFFE53935),
    },
  ];

  final Map<String, bool> _selected = {
    'boc': false,
    'nsb': false,
    'peoples': false,
  };

  bool get _anySelected => _selected.values.any((v) => v);

  void _toggle(String id) {
    setState(() {
      _selected[id] = !(_selected[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Translations ලබා ගැනීම
    final currentLanguage = ref.watch(languageProvider);
    final mainTitle = AppTranslations.getText('select_banks', currentLanguage);
    final subTitle = AppTranslations.getText('select_banks_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    // 2. අලංකාර වර්ණ සැකසුම්
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFCFDFC);

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
                  const SizedBox(height: 16),

                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: textColor,
                      size: 22,
                    ),
                    splashRadius: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 24),

                  // Title (Translated)
                  Text(
                    mainTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle (Translated)
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bank Cards List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _banks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) => _BankCard(
                        bank: _banks[index],
                        isSelected: _selected[_banks[index]['id']]!,
                        onTap: () => _toggle(_banks[index]['id']),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Continue Button (Translated and Navigates)
                  _ContinueButton(
                    btnText: btnText,
                    enabled: _anySelected,
                    onPressed: _anySelected ? () {
                      // තෝරාගත් බැංකු ලැයිස්තුව වෙන්කර ගැනීම
                      final selectedList = _selected.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();

                      // ඊළඟ තිරයට ගමන් කිරීම
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InitialBalancesScreen(selectedBanks: selectedList),
                        ),
                      );
                    } : null,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// අලංකාර Bank Card සැකිල්ල
class _BankCard extends StatelessWidget {
  final Map<String, dynamic> bank;
  final bool isSelected;
  final VoidCallback onTap;

  const _BankCard({
    required this.bank,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF182D92).withOpacity(0.05)
            : (isDark ? const Color(0xFF1E1E1E) : Colors.transparent),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF182D92)
              : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
          width: isSelected ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: const Color(0xFF182D92).withOpacity(0.08),
          highlightColor: const Color(0xFF182D92).withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: bank['tint'] as Color,
                  child: Icon(
                    bank['icon'] as IconData,
                    color: bank['iconColor'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank['name'] as String,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bank['code'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: isSelected
                      ? Container(
                    key: const ValueKey('check'),
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF182D92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                      : SizedBox(
                    key: const ValueKey('empty'),
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
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

// අලංකාර Continue බොත්තම
class _ContinueButton extends StatelessWidget {
  final String btnText;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ContinueButton({required this.btnText, required this.enabled, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: enabled ? const Color(0xFF182D92) : const Color(0xFFE5E7EB),
        boxShadow: enabled
            ? [
          BoxShadow(
            color: const Color(0xFF182D92).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 240),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                letterSpacing: 0.2,
              ),
              child: Text(btnText),
            ),
          ),
        ),
      ),
    );
  }
}