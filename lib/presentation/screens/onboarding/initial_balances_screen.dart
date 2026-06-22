import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../utils/app_translations.dart';
import 'initialization_screen.dart';

class InitialBalancesScreen extends ConsumerStatefulWidget {
  final List<String> selectedBanks;

  const InitialBalancesScreen({super.key, required this.selectedBanks});

  @override
  ConsumerState<InitialBalancesScreen> createState() => _InitialBalancesScreenState();
}

class _InitialBalancesScreenState extends ConsumerState<InitialBalancesScreen> {
  // අපගේ සැබෑ දත්ත (අලංකාර වර්ණ සහ අයිකන සමඟින්)
  final Map<String, _BalanceItem> _bankDetails = {
    'boc': _BalanceItem(
      id: 'boc',
      label: 'Bank of Ceylon (BOC)',
      icon: Icons.account_balance_rounded,
      tint: const Color(0xFFFFF8E1),
      tintDark: const Color(0xFF3E3A1C),
      iconColor: const Color(0xFFF9A825),
    ),
    'nsb': _BalanceItem(
      id: 'nsb',
      label: 'National Savings Bank (NSB)',
      icon: Icons.savings_rounded,
      tint: const Color(0xFFFFF3E0),
      tintDark: const Color(0xFF3E270A),
      iconColor: const Color(0xFFFF9800),
    ),
    'peoples': _BalanceItem(
      id: 'peoples',
      label: 'Peoples Bank',
      icon: Icons.account_balance_wallet_rounded,
      tint: const Color(0xFFFFEBEE),
      tintDark: const Color(0xFF3E1C20),
      iconColor: const Color(0xFFC62828),
    ),
  };

  final _BalanceItem _cashWallet = _BalanceItem(
    id: 'cash',
    label: 'My Wallet (Cash)',
    icon: Icons.account_balance_wallet_rounded,
    tint: const Color(0xFFE8F5E9),
    tintDark: const Color(0xFF1B3C1E),
    iconColor: const Color(0xFF2E7D32),
  );

  late final List<_BalanceItem> _activeItems;
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();

    // 1. තෝරාගත් බැංකු සහ Cash Wallet එක පමණක් ලැයිස්තුවකට ගැනීම
    _activeItems = [_cashWallet];
    for (var bankId in widget.selectedBanks) {
      if (_bankDetails.containsKey(bankId)) {
        _activeItems.add(_bankDetails[bankId]!);
      }
    }

    // 2. Controllers සහ FocusNodes සැකසීම
    _controllers = {};
    _focusNodes = {};

    for (final item in _activeItems) {
      _controllers[item.id] = TextEditingController();
      final node = FocusNode();
      node.addListener(_onFocusChanged);
      _focusNodes[item.id] = node;
    }
  }

  @override
  void dispose() {
    for (final id in _controllers.keys) {
      _controllers[id]?.dispose();
      _focusNodes[id]?.removeListener(_onFocusChanged);
      _focusNodes[id]?.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // 1. Translations ලබා ගැනීම
    final currentLanguage = ref.watch(languageProvider);

    // AppTranslations.dart හි මෙම key-value යුගලයන් නොමැති නම් පෙරනිමි ඉංග්‍රීසි පෙන්වීමට Fallback එකක් යොදා ඇත.
    final title = AppTranslations.getText('enter_balances', currentLanguage) == 'enter_balances'
        ? 'Enter Initial Balances' : AppTranslations.getText('enter_balances', currentLanguage);
    final desc = AppTranslations.getText('enter_balances_desc', currentLanguage) == 'enter_balances_desc'
        ? 'Please enter the current balance for your wallets to start fresh.' : AppTranslations.getText('enter_balances_desc', currentLanguage);
    final btnText = AppTranslations.getText('continue_btn', currentLanguage);

    // 2. අලංකාර වර්ණ සැකසුම්
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final background = isDark ? const Color(0xFF121212) : const Color(0xFFFCFDFC);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 16),

                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: textPrimary,
                          splashRadius: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Dynamic Balance Input Cards
                      ..._activeItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _BalanceInputCard(
                            item: item,
                            controller: _controllers[item.id]!,
                            focusNode: _focusNodes[item.id]!,
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Continue Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _ContinueButton(
                    btnText: btnText,
                    onPressed: () {
                      // 1. සියලුම අගයන් double ලෙස Map එකකට සකස් කිරීම
                      final Map<String, double> balances = {};
                      _controllers.forEach((key, controller) {
                        balances[key] = double.tryParse(controller.text) ?? 0.0;
                      });

                      // 2. InitializationScreen වෙත ගමන් කිරීම
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InitializationScreen(
                            selectedBanks: widget.selectedBanks,
                            initialBalances: balances,
                          ),
                        ),
                      );
                    },
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

// Data Model Class
class _BalanceItem {
  final String id;
  final String label;
  final IconData icon;
  final Color tint;
  final Color tintDark;
  final Color iconColor;

  _BalanceItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.tint,
    required this.tintDark,
    required this.iconColor,
  });
}

// අලංකාර Input Card සැකිල්ල
class _BalanceInputCard extends StatelessWidget {
  final _BalanceItem item;
  final TextEditingController controller;
  final FocusNode focusNode;

  const _BalanceInputCard({
    required this.item,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF182D92);
    final isFocused = focusNode.hasFocus;

    final cardBackground = isFocused
        ? primary.withOpacity(isDark ? 0.06 : 0.03)
        : Colors.transparent;

    final borderColor = isFocused
        ? primary.withOpacity(0.85)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);

    final labelColor = isFocused
        ? primary
        : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

    final inputColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 1.8 : 1.2,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: primary.withOpacity(isDark ? 0.18 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Circular Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? item.tintDark : item.tint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 26,
                ),
              ),
            ),

            const SizedBox(width: 18),

            // Input Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      letterSpacing: 0.2,
                    ),
                    child: Text(item.label),
                  ),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: inputColor,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          'Rs. ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isFocused ? primary : hintColor,
                            height: 1.2,
                          ),
                        ),
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: hintColor,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// අලංකාර Continue බොත්තම
class _ContinueButton extends StatefulWidget {
  final String btnText;
  final VoidCallback onPressed;

  const _ContinueButton({required this.btnText, required this.onPressed});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF182D92);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isPressed
              ? []
              : [
            BoxShadow(
              color: primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.btnText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}