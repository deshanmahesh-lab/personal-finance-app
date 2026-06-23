import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';

// =============================================================================
// MODELS & DATA
// =============================================================================
class _BankDef {
  final String id;
  final String name;
  final String shortName;
  final String tagline;
  final Color color;
  final Color glow;
  final IconData icon;

  const _BankDef({
    required this.id,
    required this.name,
    required this.shortName,
    required this.tagline,
    required this.color,
    required this.glow,
    required this.icon,
  });
}

// අපගේ සහාය දක්වන බැංකු ලැයිස්තුව (Supported Banks)
const List<_BankDef> _allBanks = [
  _BankDef(
    id: 'boc',
    name: 'Bank of Ceylon',
    shortName: 'BOC',
    tagline: 'Bankers to the Nation',
    color: Color(0xFFE5B600),
    glow: Color(0xFFFFD64A),
    icon: Icons.account_balance_rounded,
  ),
  _BankDef(
    id: 'nsb',
    name: 'National Savings Bank',
    shortName: 'NSB',
    tagline: 'The Power of Trust',
    color: Color(0xFFEF6C1A),
    glow: Color(0xFFFF8A3D),
    icon: Icons.savings_rounded,
  ),
  _BankDef(
    id: 'peoples',
    name: 'Peoples Bank',
    shortName: 'PB',
    tagline: 'Pulse of the People',
    color: Color(0xFFD7263D),
    glow: Color(0xFFFF5063),
    icon: Icons.business_rounded,
  ),
  _BankDef(
    id: 'cash',
    name: 'Cash Wallet',
    shortName: 'CW',
    tagline: 'Spend in your pocket',
    color: Color(0xFF1DB954),
    glow: Color(0xFF34E07A),
    icon: Icons.account_balance_wallet_rounded,
  ),
];

// Database Account එකක් සහ අපගේ UI Bank Definition එකක් එකතු කරන Wrapper එක
class _WalletData {
  final Account account;
  final _BankDef bankDef;
  const _WalletData({required this.account, required this.bankDef});
}

// =============================================================================
// SCREEN
// =============================================================================
class ManageAccountsScreen extends ConsumerStatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  ConsumerState<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends ConsumerState<ManageAccountsScreen> with TickerProviderStateMixin {
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // [FIXED] පරණ සහ අලුත් ගිණුම් දෙකම නිවැරදිව හඳුනාගන්නා බුද්ධිමත් ලොජික් එක
  _BankDef _identifyBank(Account acc) {
    final type = acc.type.toLowerCase();
    final name = acc.name.toLowerCase();

    // 1. අලුතින් හදපු ගිණුම් වල කෙලින්ම ID එක type එකේ තියෙනවා (boc, nsb, etc.)
    for (var b in _allBanks) {
      if (b.id == type) return b;
    }

    // 2. පරණ ගිණුම් සඳහා (Fallback) - නම කියවා බැංකුව හඳුනාගැනීම
    if (name.contains('boc') || name.contains('ceylon')) {
      return _allBanks.firstWhere((b) => b.id == 'boc');
    }
    if (name.contains('nsb') || name.contains('national')) {
      return _allBanks.firstWhere((b) => b.id == 'nsb');
    }
    if (name.contains('peoples')) {
      return _allBanks.firstWhere((b) => b.id == 'peoples');
    }

    // 3. මුකුත්ම ගැලපෙන්නේ නැත්නම් Cash විදිහට පෙන්වීම
    return _allBanks.last;
  }

  Future<void> _openAddSheet(List<_BankDef> availableBanks) async {
    HapticFeedback.mediumImpact();
    if (availableBanks.isEmpty) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _AddWalletSheet(banks: availableBanks),
    );

    if (result != null) {
      final selectedBank = result['bank'] as _BankDef;
      final initialBalance = result['balance'] as double;

      // Database එකට නිවැරදිව type එක Save කිරීම
      final newAccount = AccountsCompanion.insert(
        name: selectedBank.name,
        type: selectedBank.id, // boc, nsb, peoples, cash
        initialBalance: drift.Value(initialBalance),
      );
      ref.read(accountDaoProvider).insertAccount(newAccount);

      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFCFDFC);
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final lang = ref.watch(languageProvider);

    // [FIXED] මුළු Scaffold එකම StreamBuilder එක ඇතුළට ගැනීමෙන් FAB එක සහ Body එක Sync කිරීම
    return StreamBuilder<List<Account>>(
        stream: ref.watch(accountDaoProvider).watchAllAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));
          }

          final accounts = snapshot.data ?? [];

          // පරණ සහ අලුත් ගිණුම් නිවැරදිව Map කිරීම
          final List<_WalletData> wallets = accounts.map((acc) {
            return _WalletData(account: acc, bankDef: _identifyBank(acc));
          }).toList();

          final double totalBalance = wallets.fold(0.0, (sum, w) => sum + w.account.initialBalance);

          // දැනටමත් හදාගෙන ඇති ගිණුම් ඉවත් කර ඉතිරි බැංකු පමණක් තේරීම
          final List<_BankDef> availableBanks = _allBanks.where((b) => !wallets.any((w) => w.bankDef.id == b.id)).toList();

          return Scaffold(
            backgroundColor: bg,
            extendBody: true,
            body: Stack(
              children: [
                ...wallets.map((w) => Positioned(
                  top: 80 + wallets.indexOf(w) * 120.0,
                  right: -120,
                  child: _GlowOrb(color: w.bankDef.glow, size: 280),
                ),
                ),
                Positioned(
                  bottom: -100, left: -100,
                  child: _GlowOrb(color: isDark ? Colors.blueAccent : Colors.blueGrey, size: 320),
                ),

                SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Row(
                            children: [
                              _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, isDark: isDark, onTap: () => Navigator.pop(context)),
                              const Spacer(),
                              _GlassIconButton(icon: Icons.tune_rounded, isDark: isDark, onTap: () {}),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getText('my_wallets', lang) == 'my_wallets' ? 'My Wallets' : AppTranslations.getText('my_wallets', lang),
                                style: TextStyle(color: fg, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.0),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${wallets.length} connected accounts',
                                style: TextStyle(color: fg.withOpacity(0.55), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                          child: _TotalBalancePanel(total: totalBalance, isDark: isDark),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            children: [
                              Text('Connected', style: TextStyle(color: fg.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: fg.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: fg.withOpacity(0.08))),
                                child: Text(
                                  '${wallets.length}/${_allBanks.length}',
                                  style: TextStyle(color: fg.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (wallets.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text("No accounts connected yet.", style: TextStyle(color: fg.withOpacity(0.5))),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          sliver: SliverList.separated(
                            itemCount: wallets.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (_, i) => _WalletCard(wallet: wallets[i], isDark: isDark),
                          ),
                        ),

                      if (availableBanks.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 140),
                          sliver: SliverToBoxAdapter(
                            child: _AddNewCard(
                              isDark: isDark,
                              remaining: availableBanks.length,
                              onTap: () => _openAddSheet(availableBanks),
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                    ],
                  ),
                ),
              ],
            ),

            floatingActionButton: availableBanks.isEmpty
                ? null
                : AnimatedBuilder(
              animation: _fabController,
              builder: (_, child) {
                final t = Curves.easeInOut.transform(_fabController.value);
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF3A52C9).withOpacity(0.35 + 0.25 * t), blurRadius: 30 + 20 * t, spreadRadius: 2 + 4 * t)],
                  ),
                  child: child,
                );
              },
              child: FloatingActionButton.extended(
                onPressed: () => _openAddSheet(availableBanks),
                backgroundColor: const Color(0xFF182D92), foregroundColor: Colors.white, elevation: 0,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(AppTranslations.getText('add_wallet', lang) == 'add_wallet' ? 'Add Wallet' : AppTranslations.getText('add_wallet', lang), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2)),
              ),
            ),
          );
        }
    );
  }
}

// =============================================================================
// TOTAL BALANCE PANEL
// =============================================================================
class _TotalBalancePanel extends StatelessWidget {
  final double total;
  final bool isDark;
  const _TotalBalancePanel({required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)] : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: fg.withOpacity(isDark ? 0.08 : 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A52C9), Color(0xFF182D92)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF3A52C9).withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.diamond_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Net Balance', style: TextStyle(color: fg.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                    const SizedBox(height: 4),
                    Text('LKR ${_format(total)}', style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WALLET CARD (Glassmorphic + brand glow)
// =============================================================================
class _WalletCard extends StatelessWidget {
  final _WalletData wallet;
  final bool isDark;
  const _WalletCard({required this.wallet, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return Stack(
      children: [
        Positioned(
          right: -40, top: -40,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [wallet.bankDef.glow.withOpacity(0.35), wallet.bankDef.glow.withOpacity(0.0)])),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: isDark ? [Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.02)] : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: wallet.bankDef.glow.withOpacity(0.25), width: 1),
                boxShadow: [BoxShadow(color: wallet.bankDef.color.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [wallet.bankDef.color, wallet.bankDef.glow]),
                          boxShadow: [BoxShadow(color: wallet.bankDef.glow.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Icon(wallet.bankDef.icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.bankDef.name, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(wallet.bankDef.tagline, style: TextStyle(color: fg.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: wallet.bankDef.glow.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: wallet.bankDef.glow.withOpacity(0.4))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: wallet.bankDef.glow, boxShadow: [BoxShadow(color: wallet.bankDef.glow, blurRadius: 6)])),
                            const SizedBox(width: 6),
                            Text('Active', style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Initial Balance', style: TextStyle(color: fg.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('LKR', style: TextStyle(color: fg.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text(_format(wallet.account.initialBalance), style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.0)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ADD NEW CARD
// =============================================================================
class _AddNewCard extends StatelessWidget {
  final bool isDark; final int remaining; final VoidCallback onTap;
  const _AddNewCard({required this.isDark, required this.remaining, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        color: fg.withOpacity(0.18), radius: 26,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF3A52C9), Color(0xFF182D92)]), boxShadow: [BoxShadow(color: const Color(0xFF3A52C9).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))]),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect a new wallet', style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text('$remaining supported banks available', style: TextStyle(color: fg.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: fg.withOpacity(0.4), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ADD WALLET BOTTOM SHEET
// =============================================================================
class _AddWalletSheet extends StatefulWidget {
  final List<_BankDef> banks;
  const _AddWalletSheet({required this.banks});

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  _BankDef? _selected;
  String _amount = '';

  void _tapKey(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == 'del') {
        if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
      } else if (k == '.') {
        if (!_amount.contains('.')) _amount = _amount.isEmpty ? '0.' : '$_amount.';
      } else {
        if (_amount.length < 12) _amount = '$_amount$k';
      }
    });
  }

  double get _amountValue => double.tryParse(_amount) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFCFDFC);
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return DraggableScrollableSheet(
      initialChildSize: 0.78, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(color: bg.withOpacity(isDark ? 0.92 : 0.98), border: Border(top: BorderSide(color: fg.withOpacity(0.08)))),
            child: Stack(
              children: [
                if (_selected != null) Positioned(top: -80, right: -80, child: _GlowOrb(color: _selected!.glow, size: 280)),
                Column(
                  children: [
                    Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Container(width: 42, height: 4, decoration: BoxDecoration(color: fg.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 14, 8),
                      child: Row(
                        children: [
                          if (_selected != null) GestureDetector(onTap: () => setState(() { _selected = null; _amount = ''; }), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(shape: BoxShape.circle, color: fg.withOpacity(0.06)), child: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 16))),
                          if (_selected != null) const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selected == null ? 'Choose a bank' : 'Initial balance', style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                                const SizedBox(height: 2),
                                Text(_selected == null ? 'Supported banks shown below' : _selected!.name, style: TextStyle(color: fg.withOpacity(0.55), fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close_rounded, color: fg.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim), child: child)),
                        child: _selected == null ? _buildBankGrid(controller, fg, isDark) : _buildAmountEntry(fg, isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankGrid(ScrollController controller, Color fg, bool isDark) {
    return GridView.builder(
      key: const ValueKey('grid'), controller: controller, padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.95),
      itemCount: widget.banks.length,
      itemBuilder: (_, i) {
        final b = widget.banks[i];
        return GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); setState(() => _selected = b); },
          child: Stack(
            children: [
              Positioned(right: -30, top: -30, child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [b.glow.withOpacity(0.4), b.glow.withOpacity(0.0)])))),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
                  border: Border.all(color: b.glow.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: b.color.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [b.color, b.glow]), boxShadow: [BoxShadow(color: b.glow.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 6))]), child: Icon(b.icon, color: Colors.white, size: 24)),
                    const Spacer(),
                    Text(b.shortName, style: TextStyle(color: fg.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountEntry(Color fg, bool isDark) {
    return Padding(
      key: const ValueKey('amount'),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [Colors.white.withOpacity(0.06), Colors.white.withOpacity(0.02)] : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.7)]),
              border: Border.all(color: _selected!.glow.withOpacity(0.35)),
              boxShadow: [BoxShadow(color: _selected!.glow.withOpacity(0.18), blurRadius: 26, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INITIAL BALANCE', style: TextStyle(color: fg.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('LKR', style: TextStyle(color: fg.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(child: FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(_amount.isEmpty ? '0' : _format(_amountValue), style: TextStyle(color: fg, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.6, height: 1.0)))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildKeypad(fg, isDark)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: _amountValue < 0 ? null : () {
                Navigator.pop(context, {'bank': _selected, 'balance': _amountValue});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _selected!.color, disabledBackgroundColor: fg.withOpacity(0.1), foregroundColor: Colors.white, elevation: 0, shadowColor: _selected!.glow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ).copyWith(overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text('Connect ${_selected!.shortName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(Color fg, bool isDark) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.8),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16), onTap: () => _tapKey(k),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: fg.withOpacity(isDark ? 0.05 : 0.04)),
              child: k == 'del' ? Icon(Icons.backspace_outlined, color: fg.withOpacity(0.8), size: 22) : Text(k, style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SHARED HELPERS
// =============================================================================
class _GlowOrb extends StatelessWidget {
  final Color color; final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(0.35), color.withOpacity(0.0)]))));
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon; final bool isDark; final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: fg.withOpacity(0.06), border: Border.all(color: fg.withOpacity(0.1))), child: Icon(icon, color: fg, size: 18)),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child; final Color color; final double radius;
  const DottedBorderBox({super.key, required this.child, required this.color, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedBorderPainter(color: color, radius: radius), child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child));
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color; final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.4..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0; const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(metric.extractPath(dist, next.clamp(0, metric.length)), paint);
        dist = next + gap;
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

String _format(double v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  return '${buf.toString()}.${parts[1]}';
}