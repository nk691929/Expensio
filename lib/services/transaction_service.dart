import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionService() {
    // ✅ Ensure offline persistence is enabled (only needed once)
    _firestore.settings = const Settings(persistenceEnabled: true);
  }

  /// 🔹 Collection reference
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  /// ✅ Create a new transaction (🔥 Non-blocking for offline)
  Future<void> createTransaction(TransactionModel transaction) async {
    _transactions.doc(transaction.id).set(transaction.toMap());
  }

  /// 📥 Get a single transaction by ID (tries cache first if offline)
  Future<TransactionModel?> getTransaction(String id) async {
    try {
      // ✅ Try server first
      final doc = await _transactions.doc(id).get();
      if (doc.exists) return TransactionModel.fromMap(doc.data()!);
    } catch (e) {
      // ⚠️ Fallback to cache if offline
      final doc = await _transactions.doc(id).get(const GetOptions(source: Source.cache));
      if (doc.exists) return TransactionModel.fromMap(doc.data()!);
    }
    return null;
  }

  /// 📜 Get all transactions once (tries server, falls back to cache)
  Future<List<TransactionModel>> getUserTransactions(String userId) async {
    try {
      final query = await _transactions
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      return query.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList();
    } catch (e) {
      // ⚠️ Offline fallback: use local cache
      final query = await _transactions
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.cache));
      return query.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList();
    }
  }

  /// 🔄 Real-time stream (works offline, updates when online)
  Stream<List<TransactionModel>> listenToUserTransactions(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }

  /// ✏️ Update transaction (non-blocking)
  Future<void> updateTransaction(TransactionModel transaction) async {
    _transactions.doc(transaction.id).update(transaction.toMap());
  }

  /// ❌ Delete transaction (non-blocking)
  Future<void> deleteTransaction(String id) async {
    _transactions.doc(id).delete();
  }
}
