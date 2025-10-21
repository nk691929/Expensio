import 'package:animationandcharts/services/category_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/category_model.dart';

/// 📦 Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// 📡 Stream all categories of a specific user
final userCategoriesStreamProvider =
    StreamProvider.family<List<CategoryModel>, String>((ref, userId) {
      return ref.read(categoryRepositoryProvider).streamUserCategories(userId);
    });

/// 🧠 StateNotifier for Category CRUD actions
class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repository;
  final String userId;

  CategoryNotifier(this._repository, this.userId)
    : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  // 📥 Load all categories initially
  Future<void> _loadCategories() async {
    try {
      final stream = _repository.streamUserCategories(userId);
      stream.listen((categories) {
        state = AsyncValue.data(categories);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ➕ Add new category
  Future<void> addCategory(CategoryModel category) async {
    await _repository.saveCategory(category);
  }

  // ✏️ Update category
  Future<void> updateCategory(CategoryModel category) async {
    await _repository.updateCategory(category);
  }

  // ❌ Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
    } catch (e) {
      throw Exception(e.toString()); // You can also show SnackBar in UI
    }
  }
}

/// 🪄 StateNotifierProvider for managing categories
final categoryNotifierProvider =
    StateNotifierProvider.family<
      CategoryNotifier,
      AsyncValue<List<CategoryModel>>,
      String
    >((ref, userId) {
      return CategoryNotifier(ref.read(categoryRepositoryProvider), userId);
    });
