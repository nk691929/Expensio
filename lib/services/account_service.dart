import 'package:animationandcharts/models/account_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AccountRepository() {
    // ✅ Enable offline persistence (once, usually at app startup)
    _firestore.settings = const Settings(
      persistenceEnabled: true, // 🔥 cache data offline
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _firestore.collection('accounts');

  // ➕ Create
  Future<void> createAccount(Account account) async {
    await _accounts
        .doc(account.id)
        .set(account.toMap(), SetOptions(merge: true));
  }

  // 📥 Read all for a user (realtime + works offline)
  Stream<List<Account>> getAccounts(String userId) {
    return _accounts
        .where("userId", isEqualTo: userId)
        .snapshots(
          includeMetadataChanges: true,
        ) // ✅ metadata tells if it's from cache
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Account.fromMap(doc.data())).toList(),
        );
  }

  // 📤 Get single account (works offline too)
  Future<Account?> getAccountById(String accountId) async {
    final doc = await _accounts
        .doc(accountId)
        .get(const GetOptions(source: Source.cache));
    if (doc.exists) {
      return Account.fromMap(doc.data()!);
    } else {
      // If not in cache, try server
      final onlineDoc = await _accounts.doc(accountId).get();
      if (onlineDoc.exists) return Account.fromMap(onlineDoc.data()!);
    }
    return null;
  }

  // ✏️ Update (works offline – will sync later if offline)
  Future<void> updateAccount(Account account) async {
    print("🔥 Updating account ${account.id}");
    print("📦 Data: ${account.toMap()}");

    await _accounts
        .doc(account.id)
        .set(
          account.toMap(),
          SetOptions(merge: true), // ✅ safer offline updates
        );
  }

  // ❌ Delete (with dependency check)
  Future<void> deleteAccount(String accountId) async {
    final txSnapshot = await _firestore
        .collection('transactions')
        .where(
          'userId',
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        ) // ✅ make sure user is owner
        .where('accountId', isEqualTo: accountId)
        .limit(1) // ✅ performance
        .get();

    if (txSnapshot.docs.isNotEmpty) {
      throw Exception(
        "⚠️ Cannot delete this account — transactions are linked to it.",
      );
    }

    await _accounts.doc(accountId).delete();
  }

  // 💰 Update only balance (offline-persistent)
  Future<void> updateAccountBalance({
    required String accountId,
    required double delta,
  }) async {
    final docRef = _accounts.doc(accountId);

    // First, try to get cached data
    final doc = await docRef.get(const GetOptions(source: Source.cache));
    double currentBalance = 0;

    if (doc.exists) {
      currentBalance = (doc.get('balance') ?? 0).toDouble();
    } else {
      // fallback: get from server if not in cache
      final onlineDoc = await docRef.get();
      if (onlineDoc.exists) {
        currentBalance = (onlineDoc.get('balance') ?? 0).toDouble();
      }
    }

    final newBalance = currentBalance + delta;

    // ✅ Use set with merge to update balance offline
    await docRef.set({
      'balance': newBalance,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
  }
}