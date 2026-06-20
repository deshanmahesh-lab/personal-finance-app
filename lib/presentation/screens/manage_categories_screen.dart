import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/language_provider.dart';
import '../../utils/app_translations.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  bool _isIncome = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final backgroundColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2);
    final primaryColor = _isIncome ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildSlidingToggles(primaryColor, lang),
            const SizedBox(height: 16),
            Expanded(child: _CategoryList(isIncome: _isIncome)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        elevation: 2,
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _showAddCategoryDialog(context, ref, _isIncome),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppTranslations.getText('add_category', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildSlidingToggles(Color primaryColor, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: _isIncome ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: 0.5, child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]))),
            ),
            Row(
              children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _isIncome = false), behavior: HitTestBehavior.opaque, child: Center(child: Text(AppTranslations.getText('expense', lang), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: !_isIncome ? primaryColor : Colors.grey.shade600))))),
                Expanded(child: GestureDetector(onTap: () => setState(() => _isIncome = true), behavior: HitTestBehavior.opaque, child: Center(child: Text(AppTranslations.getText('income', lang), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _isIncome ? primaryColor : Colors.grey.shade600))))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, bool isIncome) {
    final lang = ref.read(languageProvider);
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final dialogColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.getText('new_category', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: AppTranslations.getText('cat_name', lang), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dialogColor, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                if (!isIncome) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: AppTranslations.getText('monthly_budget_opt', lang), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dialogColor, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: dialogColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        final budgetText = budgetController.text.trim();
                        final budgetValue = double.tryParse(budgetText);
                        final newCategory = CategoriesCompanion.insert(name: name, isIncome: isIncome, budgetLimit: drift.Value(budgetValue));
                        ref.read(categoryDaoProvider).insertCategory(newCategory);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(AppTranslations.getText('save_cat', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final bool isIncome;
  const _CategoryList({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final stream = ref.watch(categoryDaoProvider).watchCategories(isIncome);
    final themeColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;

    return StreamBuilder<List<Category>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.category_rounded, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No categories configured.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]));
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 64, endIndent: 16, color: Colors.grey.withOpacity(0.15)),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final hasBudget = cat.budgetLimit != null && cat.budgetLimit! > 0;

                return Dismissible(
                  key: ValueKey(cat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red.shade600, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 24), child: const Icon(Icons.delete_outline, color: Colors.white, size: 28)),
                  confirmDismiss: (direction) => _confirmDeleteCategory(context, ref, cat),
                  onDismissed: (direction) {
                    final deletedCategory = cat.copyWith(isActive: false);
                    ref.read(categoryDaoProvider).updateCategory(deletedCategory);
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onLongPress: () => _showEditCategoryDialog(context, ref, cat, themeColor),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.sell_outlined, color: themeColor, size: 22)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  if (hasBudget) ...[const SizedBox(height: 4), Text('Budget: Rs. ${cat.budgetLimit!.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))]
                                ],
                              ),
                            ),
                            Icon(Icons.drag_handle_rounded, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category, Color themeColor) {
    final lang = ref.read(languageProvider);
    final nameController = TextEditingController(text: category.name);
    final budgetController = TextEditingController(text: category.budgetLimit != null ? category.budgetLimit!.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppTranslations.getText('edit_cat', lang), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: AppTranslations.getText('cat_name', lang), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                if (!category.isIncome) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: AppTranslations.getText('monthly_budget_opt', lang), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: () {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        final budgetText = budgetController.text.trim();
                        final newBudget = budgetText.isEmpty ? null : double.tryParse(budgetText);
                        final updatedCategory = category.copyWith(name: newName, budgetLimit: drift.Value(newBudget));
                        ref.read(categoryDaoProvider).updateCategory(updatedCategory);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(AppTranslations.getText('update', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) async {
    final lang = ref.read(languageProvider);
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppTranslations.getText('del_cat_confirm', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete "${category.name}"?\n\nPast transactions will not be affected.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.getText('cancel', lang), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                final deletedCategory = category.copyWith(isActive: false);
                ref.read(categoryDaoProvider).updateCategory(deletedCategory);
                Navigator.pop(context);
              },
              child: Text(AppTranslations.getText('delete', lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}