import 'package:animationandcharts/models/user_modal.dart';
import 'package:animationandcharts/services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
// import 'dart:io';

/// 🛠 Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// 📡 Real-time Stream Provider for User
final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.read(userRepositoryProvider).streamUser(userId);
});

/// 🧠 StateNotifier for all User CRUD + Image actions
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository _repository;

  UserNotifier(this._repository) : super(const AsyncValue.data(null));

  // ➕ Create or Update User
  Future<void> saveUser(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 📥 Fetch user once
  Future<void> fetchUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.getUserById(userId);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ✏️ Update profile
  Future<void> updateUser(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUser(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 🗑️ Delete user
  Future<void> deleteUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteUser(userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 📤 Upload profile image
  // Future<void> uploadProfileImage(String userId, File imageFile) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     await _repository.uploadProfileImage(
  //       userId: userId,
  //       imageFile: imageFile,
  //     );
  //     final updatedUser = await _repository.getUserById(userId);
  //     state = AsyncValue.data(updatedUser);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }

  // 🔄 Update profile image (delete old + upload new)
  // Future<void> updateProfileImage(String userId, File newImageFile) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     await _repository.updateProfileImage(
  //       userId: userId,
  //       newImageFile: newImageFile,
  //     );
  //     final updatedUser = await _repository.getUserById(userId);
  //     state = AsyncValue.data(updatedUser);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }

  // ❌ Delete profile image
  // Future<void> deleteProfileImage(String userId) async {
  //   state = const AsyncValue.loading();
  //   try {
  //     await _repository.deleteProfileImage(userId);
  //     final updatedUser = await _repository.getUserById(userId);
  //     state = AsyncValue.data(updatedUser);
  //   } catch (e, st) {
  //     state = AsyncValue.error(e, st);
  //   }
  // }
}

/// 🧩 Provider for `UserNotifier`
final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref.read(userRepositoryProvider));
});
