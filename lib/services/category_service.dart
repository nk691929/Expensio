import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CategoryRepository() {
    // ✅ Enable offline persistence (do this once, usually at app startup)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  // ➕ Create or Update Category (works offline too)
  Future<void> saveCategory(CategoryModel category) async {
    await _categories
        .doc(category.id)
        .set(
          category.toMap(),
          SetOptions(merge: true),
        ); // ✅ merge safe for offline
  }

  // 📥 Get Category by ID (cache-first)
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      // ✅ Try getting from local cache first
      final cachedDoc = await _categories
          .doc(categoryId)
          .get(const GetOptions(source: Source.cache));
      if (cachedDoc.exists) {
        return CategoryModel.fromMap(cachedDoc.data()!);
      }

      // 🔁 If not in cache, fallback to server
      final serverDoc = await _categories.doc(categoryId).get();
      if (serverDoc.exists) {
        return CategoryModel.fromMap(serverDoc.data()!);
      }
    } catch (e) {
      print("⚠️ Error getting category: $e");
    }
    return null;
  }

  // 📡 Stream all categories of a user (works offline & syncs later)
  Stream<List<CategoryModel>> streamUserCategories(String userId) {
    return _categories
        .where('userId', isEqualTo: userId)
        .snapshots(
          includeMetadataChanges: true,
        ) // ✅ shows when data is from cache
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ✏️ Update Category (works offline)
  Future<void> updateCategory(CategoryModel category) async {
    await _categories
        .doc(category.id)
        .set(
          category.toMap(),
          SetOptions(merge: true), // ✅ safer than `.update()` for offline
        );
  }

  // ❌ Delete Category (with dependency check)
  Future<void> deleteCategory(String categoryId) async {
    final txSnapshot = await _firestore
        .collection('transactions')
        .where(
          'userId',
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        ) // ✅ make sure user is owner
        .where('categoryId', isEqualTo: categoryId)
        .limit(1) // ✅ performance
        .get();

    if (txSnapshot.docs.isNotEmpty) {
      throw Exception(
        "⚠️ Cannot delete this category — transactions are linked to it.",
      );
    }

    await _categories.doc(categoryId).delete();
  }
}
