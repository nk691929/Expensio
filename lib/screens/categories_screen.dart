import 'package:animationandcharts/providers/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  final String userId;
  const CategoriesScreen({super.key, required this.userId});

  void _deleteCategory(BuildContext context, WidgetRef ref, CategoryModel category) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category? 🗑️"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(categoryNotifierProvider(userId).notifier).deleteCategory(category.id);
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(userCategoriesStreamProvider(userId));
    final colorScheme = Theme.of(context).colorScheme;
    final currencyAsync = ref.watch(userCurrencyProvider(userId));
    final currencySymbol = currencyAsync.maybeWhen(
            data: (c) => c?.symbol ?? "PKR",
            orElse: () => "PKR",
          );

    return Scaffold(
      appBar: AppBar(
        title: Text("Categories", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Text(
                "No categories yet.\nTap ➕ to add your first one!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (_, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: category.color.withOpacity(0.15),
                    child: Icon(category.icon, color: category.color, size: 28),
                  ),
                  title: Text(category.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
                  subtitle: Text(
                    "Monthly Budget: \ $currencySymbol${category.budget}",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final updatedCategory = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditCategoryScreen(
                                category: category,
                                userId: userId,
                              ),
                            ),
                          );
                          if (updatedCategory != null) {
                            // Real-time stream handles update automatically
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.redAccent,
                        onPressed: () => _deleteCategory(context, ref, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newCategory = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditCategoryScreen(userId: userId),
            ),
          );
          if (newCategory != null) {
            // Real-time stream updates automatically
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Category"),
      ),
    );
  }
}
