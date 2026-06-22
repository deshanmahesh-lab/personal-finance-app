import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS & HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const bgLight = Color(0xFFF9FAFB);
  static const surfaceLight = Color(0xFFFCFDFC);
  static const bgDark = Color(0xFF0B0B12);
  static const surfaceDark = Color(0xFF14141C);

  static const primaryLight = Color(0xFF6C7BFF);
  static const primaryDark = Color(0xFFB9A6FF);

  static const incomeAccent = Color(0xFF43E97B);
  static const expenseAccent = Color(0xFFFF4D6D);

  // Auto-assigned gradients based on Category ID
  static const gradients = [
    [Color(0xFFFF8A8A), Color(0xFFFF4D6D)],
    [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
    [Color(0xFFA8E063), Color(0xFF56AB2F)],
    [Color(0xFFFFB199), Color(0xFFFF0844)],
    [Color(0xFFB39DDB), Color(0xFF7E57C2)],
    [Color(0xFFFFD3A5), Color(0xFFFD6585)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFFFAD961), Color(0xFFF76B1C)],
    [Color(0xFFFBC2EB), Color(0xFFA18CD1)],
  ];

  static List<Color> getGradient(int id) => gradients[id % gradients.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> with TickerProviderStateMixin {
  bool _isIncome = false;

  void _openSheet({Category? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => _CategoryEditorSheet(isIncome: _isIncome, editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final mutedFg = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: Stack(
        children: [
          // Ambient gradient orbs
          _AmbientBackdrop(isDark: isDark),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(fg, mutedFg, lang)),
                SliverToBoxAdapter(child: _buildTypeSelector(isDark, fg, lang)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      // Stream Builder for Real Data
                      child: StreamBuilder<List<Category>>(
                        key: ValueKey(_isIncome),
                        stream: ref.watch(categoryDaoProvider).watchCategories(_isIncome),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                          }
                          final categories = snapshot.data ?? [];

                          return _CategoryGrid(
                            categories: categories,
                            isDark: isDark,
                            fg: fg,
                            lang: lang,
                            onTap: (c) => _openSheet(editing: c),
                            onAdd: () => _openSheet(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Glowing Add Button
          Positioned(
            left: 20, right: 20, bottom: 24,
            child: _GlowingAddButton(
              onTap: () => _openSheet(),
              isDark: isDark,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color fg, Color mutedFg, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _circleIconButton(Icons.arrow_back_ios_new_rounded, fg, () => Navigator.pop(context)),
          const Spacer(),
          Column(
            children: [
              Text('Manage', style: TextStyle(color: mutedFg, fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(AppTranslations.getText('title_categories', lang), style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 44), // To balance the back button
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, Color fg, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: fg.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: fg.withOpacity(0.08)),
            ),
            child: Icon(icon, color: fg, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark, Color fg, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                _segment(AppTranslations.getText('expense', lang), false, AppColors.expenseAccent, fg, isDark),
                _segment(AppTranslations.getText('income', lang), true, AppColors.incomeAccent, fg, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment(String label, bool isIncomeTab, Color accent, Color fg, bool isDark) {
    final active = _isIncome == isIncomeTab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIncome = isIncomeTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: active ? LinearGradient(colors: [accent.withOpacity(0.9), accent.withOpacity(0.6)]) : null,
            boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))] : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isIncomeTab ? Icons.north_east_rounded : Icons.south_west_rounded, size: 16, color: active ? Colors.white : fg.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: active ? Colors.white : fg.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── GRID ───────────────────────── */
class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final bool isDark;
  final Color fg;
  final String lang;
  final void Function(Category) onTap;
  final VoidCallback onAdd;

  const _CategoryGrid({required this.categories, required this.isDark, required this.fg, required this.lang, required this.onTap, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.95,
      ),
      itemBuilder: (_, i) {
        if (i == categories.length) return _AddCard(onTap: onAdd, isDark: isDark, fg: fg, lang: lang);
        return _CategoryCard(category: categories[i], isDark: isDark, fg: fg, onTap: () => onTap(categories[i]));
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool isDark;
  final Color fg;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.isDark, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.getGradient(category.id);
    final initial = category.name.isNotEmpty ? category.name[0].toUpperCase() : '?';
    final hasBudget = category.budgetLimit != null && category.budgetLimit! > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gradient.first.withOpacity(isDark ? 0.22 : 0.1), gradient.last.withOpacity(isDark ? 0.10 : 0.05)]),
          border: Border.all(color: fg.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52, height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.55), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const Spacer(),
            Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (!category.isIncome)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: fg.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: fg.withOpacity(0.08))),
                child: Text(hasBudget ? 'Limit · Rs.${category.budgetLimit!.toStringAsFixed(0)}' : 'No Limit', style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final Color fg;
  final String lang;
  const _AddCard({required this.onTap, required this.isDark, required this.fg, required this.lang});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        isDark: isDark,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), color: fg.withOpacity(0.025)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primary, primary.withOpacity(0.6)]), boxShadow: [BoxShadow(color: primary.withOpacity(0.5), blurRadius: 22, offset: const Offset(0, 8))]),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(AppTranslations.getText('new_category', lang), style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Tap to create', style: TextStyle(color: fg.withOpacity(0.5), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const DottedBorderBox({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedBorderPainter(isDark), child: child);
  }
}

class _DashedBorderPainter extends CustomPainter {
  final bool isDark;
  _DashedBorderPainter(this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.15)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(26));
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

/* ───────────────────────── GLOWING BUTTON ───────────────────────── */
class _GlowingAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final String lang;
  const _GlowingAddButton({required this.onTap, required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [primary, primary.withOpacity(0.7)]),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.55), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(AppTranslations.getText('add_category', lang), style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── GLASS SHEET (Add/Edit) ───────────────────────── */
class _CategoryEditorSheet extends ConsumerStatefulWidget {
  final bool isIncome;
  final Category? editing;
  const _CategoryEditorSheet({required this.isIncome, this.editing});

  @override
  ConsumerState<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _limit = TextEditingController(text: widget.editing?.budgetLimit != null ? widget.editing!.budgetLimit!.toStringAsFixed(0) : '');

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _name.text.trim();
    if (newName.isEmpty) return;

    final budgetText = _limit.text.trim();
    final newBudget = budgetText.isEmpty ? null : double.tryParse(budgetText);

    if (widget.editing == null) {
      final newCategory = CategoriesCompanion.insert(name: newName, isIncome: widget.isIncome, budgetLimit: drift.Value(newBudget));
      ref.read(categoryDaoProvider).insertCategory(newCategory);
    } else {
      final updatedCategory = widget.editing!.copyWith(name: newName, budgetLimit: drift.Value(newBudget));
      ref.read(categoryDaoProvider).updateCategory(updatedCategory);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final lang = ref.read(languageProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.getText('del_cat_confirm', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${widget.editing!.name}"?\n\nPast transactions will not be affected.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppTranslations.getText('cancel', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppTranslations.getText('delete', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final deletedCategory = widget.editing!.copyWith(isActive: false);
      ref.read(categoryDaoProvider).updateCategory(deletedCategory);
      Navigator.pop(context); // Close the bottom sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final sheetBg = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.05);
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final lang = ref.watch(languageProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark.withOpacity(0.8) : AppColors.surfaceLight.withOpacity(0.9),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(color: fg.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.editing == null ? AppTranslations.getText('new_category', lang) : AppTranslations.getText('edit_cat', lang),
                      style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    if (widget.editing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: _delete,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Personalize your spending universe.', style: TextStyle(color: fg.withOpacity(0.6), fontSize: 13)),
                const SizedBox(height: 22),
                _label(AppTranslations.getText('cat_name', lang), fg),
                const SizedBox(height: 10),
                _glassField(controller: _name, hint: 'e.g. Coffee runs', fg: fg, sheetBg: sheetBg, borderColor: borderColor),

                if (!widget.isIncome) ...[
                  const SizedBox(height: 18),
                  _label(AppTranslations.getText('monthly_budget_opt', lang), fg),
                  const SizedBox(height: 10),
                  _glassField(controller: _limit, hint: '500', prefix: 'Rs. ', keyboardType: TextInputType.number, fg: fg, sheetBg: sheetBg, borderColor: borderColor),
                ],

                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 54, alignment: Alignment.center,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: fg.withOpacity(0.15))),
                          child: Text(AppTranslations.getText('cancel', lang), style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _save,
                        child: Container(
                          height: 54, alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(colors: [primary, primary.withOpacity(0.7)]),
                            boxShadow: [BoxShadow(color: primary.withOpacity(0.5), blurRadius: 22, offset: const Offset(0, 10))],
                          ),
                          child: Text(AppTranslations.getText(widget.editing == null ? 'save_cat' : 'update', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color fg) => Text(text.toUpperCase(), style: TextStyle(color: fg.withOpacity(0.55), fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w600));

  Widget _glassField({required TextEditingController controller, required String hint, String? prefix, TextInputType? keyboardType, required Color fg, required Color sheetBg, required Color borderColor}) {
    return Container(
      decoration: BoxDecoration(color: sheetBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (prefix != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(prefix, style: TextStyle(color: fg.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600))),
          Expanded(
            child: TextField(
              controller: controller, keyboardType: keyboardType, style: TextStyle(color: fg, fontSize: 15),
              decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: fg.withOpacity(0.35)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── BACKDROP ───────────────────────── */
class _AmbientBackdrop extends StatelessWidget {
  final bool isDark;
  const _AmbientBackdrop({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg1 = isDark ? const Color(0xFF0B0B12) : const Color(0xFFF9FAFB);
    final bg2 = isDark ? const Color(0xFF11111B) : const Color(0xFFF1F3F5);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bg1, bg2]))),
        ),
        Positioned(top: -120, left: -80, child: _orb(const Color(0xFFB9A6FF).withOpacity(isDark ? 0.25 : 0.15), 280)),
        Positioned(top: 100, right: -100, child: _orb(const Color(0xFF43E97B).withOpacity(isDark ? 0.12 : 0.08), 260)),
        Positioned(bottom: -120, left: -60, child: _orb(const Color(0xFFFF6B8B).withOpacity(isDark ? 0.15 : 0.08), 320)),
      ],
    );
  }

  Widget _orb(Color color, double size) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withOpacity(0)])));
  }
}