import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/datasources/app_database.dart';
import '../providers/account_repository_provider.dart';

class ManageCategoriesScreen extends ConsumerWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Categories'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
              Tab(icon: Icon(Icons.attach_money), text: 'Income'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(isIncome: false),
            _CategoryList(isIncome: true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCategoryDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (selection) {
                      setState(() => selectedType = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final isIncome = selectedType == 'income';
                      final newCategory = CategoriesCompanion.insert(
                        name: name,
                        isIncome: isIncome, // drift.Value අයින් කර කෙලින්ම isIncome ලබා දුන්නා
                        // isActive කේතය අවශ්‍ය නැත, මන්ද Database එක එය ස්වයංක්‍රීයව true කරයි
                      );
                      ref.read(accountRepositoryProvider).insertCategory(newCategory);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final bool isIncome;

  const _CategoryList({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(accountRepositoryProvider).watchCategories(isIncome);

    return StreamBuilder<List<Category>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories found. Click + to add one.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Card(
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    Icons.category,
                    color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                // --- අලුත් කොටස: Edit සහ Delete බොත්තම් ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditCategoryDialog(context, ref, cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeleteCategory(context, ref, cat),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // නම සංස්කරණය කිරීම (Edit Name)
  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Category'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != category.name) {
                  // Drift හි copyWith හරහා නම පමණක් වෙනස් කර Update කිරීම
                  final updatedCategory = category.copyWith(name: newName);
                  ref.read(accountRepositoryProvider).updateCategory(updatedCategory);
                }
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Soft Delete කිරීම
  void _confirmDeleteCategory(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Category?'),
            ],
          ),
          content: Text('Are you sure you want to delete "${category.name}"?\n\nExisting transactions using this category will NOT be affected.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () {
                // Soft Delete: isActive අගය false කර Update කිරීම
                final deletedCategory = category.copyWith(isActive: false);
                ref.read(accountRepositoryProvider).updateCategory(deletedCategory);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${category.name} deleted successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}