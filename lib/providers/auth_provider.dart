import 'package:animationandcharts/models/user_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

/// 🔌 Auth Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// 📡 Auth State Stream (logged-in or not)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// 👤 Current User Data (Firestore)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(authServiceProvider).getCurrentUser();
});

/// ✅ Sign up provider (use in UI with ref.read)
final signUpProvider = FutureProvider.family<UserModel, Map<String, String>>((ref, data) async {
  return ref.watch(authServiceProvider).signUp(
    name: data['name']!,
    email: data['email']!,
    password: data['password']!,
  );
});

/// 🔑 Sign in provider
final signInProvider = FutureProvider.family<UserModel?, Map<String, String>>((ref, data) async {
  return ref.watch(authServiceProvider).signIn(
    email: data['email']!,
    password: data['password']!,
  );
});

final verifyPasswordProvider = FutureProvider.family<bool, String>((ref, password) async {
  return ref.watch(authServiceProvider).verifyPassword(password);
});