import 'package:animationandcharts/models/user_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Create user with email & password
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _auth.currentUser?.reload();
    final user = userCredential.user!;
    try {
      await user.sendEmailVerification();
      print("✅ Verification email sent");
    } catch (e) {
      print("❌ Failed to send verification email: $e");
    }

    // 🔑 Get FCM token at sign up
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    final userModel = UserModel(
      id: user.uid,
      name: name,
      email: email,
      token: fcmToken,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    return userModel;
  }

  /// 🔑 Login with email & password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) return null;

    // 🚨 Require verified email
    if (!user.emailVerified) {
      throw FirebaseAuthException(
        code: "email-not-verified",
        message: "Please verify your email before logging in.",
      );
    }

    // ✅ Update token at sign-in (important!)
    String? newToken = await FirebaseMessaging.instance.getToken();
    await _firestore.collection('users').doc(user.uid).update({
      'token': newToken,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  /// 📧 Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// 🔄 Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  /// 🔁 Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 👤 Get current user model
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    // ✅ Refresh token if needed
    String? currentToken = await FirebaseMessaging.instance.getToken();
    if (doc['token'] != currentToken) {
      await _firestore.collection('users').doc(user.uid).update({
        'token': currentToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    return UserModel.fromMap(
      (await _firestore.collection('users').doc(user.uid).get()).data()!,
    );
  }

  /// 📡 Listen to auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 🚪 Sign out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      // 🧹 Clear FCM token before sign out
      await _firestore.collection('users').doc(user.uid).update({
        'token': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    await _auth.signOut();
  }

  /// 🗑️ Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  /// 🔐 Change password (requires re-authentication)
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently logged in.',
      );
    }

    // 🔄 Re-authenticate first
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'The old password is incorrect.',
        );
      }
      rethrow;
    }
  }

  /// ✅ Verify if the provided password is correct
  Future<bool> verifyPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently logged in.',
      );
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // 🔑 Try re-authenticating to check if password matches
      await user.reauthenticateWithCredential(cred);
      return true; // ✅ Password is correct
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return false; // ❌ Password is incorrect
      }
      rethrow; // 🚨 Other errors (like too many requests)
    }
  }
}
