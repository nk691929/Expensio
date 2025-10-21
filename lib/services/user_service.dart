// import 'dart:io';
import 'package:animationandcharts/models/user_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final SupabaseClient _supabase = Supabase.instance.client;

  UserRepository() {
    // ✅ Enable Firestore offline persistence (only needs to run once)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  CollectionReference get _users => _firestore.collection('users');

  // ✅ Create or update user (works offline, syncs later)
  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  // 📥 Get single user by ID (tries cache first, then server)
  Future<UserModel?> getUserById(String userId) async {
    try {
      // 🔎 Try reading from cache first (works offline)
      final cachedDoc = await _users
          .doc(userId)
          .get(const GetOptions(source: Source.cache));

      if (cachedDoc.exists) {
        return UserModel.fromMap(cachedDoc.data() as Map<String, dynamic>);
      }

      // 🌐 Fallback to server if not in cache
      final serverDoc = await _users.doc(userId).get();
      if (serverDoc.exists) {
        return UserModel.fromMap(serverDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("⚠️ Error reading user data: $e");
    }
    return null;
  }

  // 📡 Stream user profile (real-time & offline)
  Stream<UserModel?> streamUser(String userId) {
    return _users
        .doc(userId)
        .snapshots(includeMetadataChanges: true) // ✅ emits from cache too
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromMap(doc.data() as Map<String, dynamic>);
          }
          return null;
        });
  }

  // ✏️ Update user profile (offline supported)
  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  // ❌ Delete user and all their related data
 // ❌ Delete user and all their related data
Future<void> deleteUser(String userId) async {
  // final user = await getUserById(userId);

  // 🧹 1. Delete profile image if exists
  // if (user?.profileImageUrl != null) {
  //   await deleteProfileImage(userId);
  // }

  // 🧹 2. Delete all accounts belonging to the user
  final accountsSnap = await _firestore
      .collection('accounts')
      .where('userId', isEqualTo: userId)
      .get();
  for (var doc in accountsSnap.docs) {
    await doc.reference.delete();
  }

  // 🧹 3. Delete all categories belonging to the user
  final categoriesSnap = await _firestore
      .collection('categories')
      .where('userId', isEqualTo: userId)
      .get();
  for (var doc in categoriesSnap.docs) {
    await doc.reference.delete();
  }

  // 🧹 4. Delete all transactions belonging to the user
  final transactionsSnap = await _firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .get();
  for (var doc in transactionsSnap.docs) {
    await doc.reference.delete();
  }

  // 🧹 5. Finally, delete the user document itself
  await _users.doc(userId).delete();

  // 🧹 6. Delete the user from Firebase Authentication
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      // ✅ If deleting the currently signed-in user
      await currentUser.delete();
    } else {
      // ⚠️ If deleting another user, must be done from Admin SDK on backend
      print("⚠️ Can't delete another user directly from client app.");
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      print("⚠️ User needs to reauthenticate before deletion.");
      // 👉 Ask them to log in again, then retry delete()
    } else {
      print("❌ Failed to delete auth user: ${e.message}");
    }
  }
}

  // 📤 Upload profile image to Supabase Storage
  // Future<String?> uploadProfileImage({
  //   required String userId,
  //   required File imageFile,
  // }) async {
  //   final path =
  //       'profile_pics/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

  //   final response = await _supabase.storage
  //       .from('profile_images')
  //       .upload(path, imageFile);

  //   if (response.isEmpty) {
  //     throw Exception('❌ Failed to upload image');
  //   }

  //   final publicUrl = _supabase.storage
  //       .from('profile_images')
  //       .getPublicUrl(path);

  //   // ✅ Save URL to Firestore (offline-safe)
  //   await _users.doc(userId).set({
  //     'profileImageUrl': publicUrl,
  //   }, SetOptions(merge: true));

  //   return publicUrl;
  // }

  // 🔄 Update profile image (delete old one, then upload new)
  // Future<String?> updateProfileImage({
  //   required String userId,
  //   required File newImageFile,
  // }) async {
  //   final user = await getUserById(userId);

  //   // 🧹 Delete old image if exists
  //   if (user?.profileImageUrl != null) {
  //     await deleteProfileImage(userId);
  //   }

  //   return await uploadProfileImage(userId: userId, imageFile: newImageFile);
  // }

  // 🗑️ Delete profile image from Supabase & Firestore
  // Future<void> deleteProfileImage(String userId) async {
  //   final user = await getUserById(userId);
  //   if (user?.profileImageUrl == null) return;

  //   final publicUrl = user!.profileImageUrl!;
  //   final filePath = _extractFilePathFromUrl(publicUrl);

  //   if (filePath != null) {
  //     await _supabase.storage.from('profile_images').remove([filePath]);
  //     await _users.doc(userId).update({'profileImageUrl': null});
  //   }
  // }

  // 🧠 Helper: extract file path from public URL
  // String? _extractFilePathFromUrl(String url) {
  //   try {
  //     final parts = url.split('/storage/v1/object/public/profile_images/');
  //     if (parts.length > 1) {
  //       return parts[1];
  //     }
  //   } catch (_) {}
  //   return null;
  // }
}
