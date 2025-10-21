import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/currency_model.dart';

class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CurrencyService() {
    // ✅ Enable Firestore offline persistence (only needed once in app lifecycle)
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// 🪙 Save user's selected currency (works offline too)
  Future<void> saveUserCurrency(String userId, CurrencyModel currency) async {
    await _firestore.collection('users').doc(userId).set({
      'currency': currency.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// 📥 Get user's selected currency (tries cache first, falls back to server)
  Future<CurrencyModel?> getUserCurrency(String userId) async {
    try {
      // ✅ Try reading from cache first (offline mode)
      final cachedDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));

      if (cachedDoc.exists && cachedDoc.data()?['currency'] != null) {
        return CurrencyModel.fromMap(
          Map<String, dynamic>.from(cachedDoc.data()!['currency']),
        );
      }

      // 🔁 If not in cache, fallback to server
      final serverDoc = await _firestore.collection('users').doc(userId).get();
      if (serverDoc.exists && serverDoc.data()?['currency'] != null) {
        return CurrencyModel.fromMap(
          Map<String, dynamic>.from(serverDoc.data()!['currency']),
        );
      }
    } catch (e) {
      print("⚠️ Error fetching currency: $e");
    }
    return null;
  }

  /// 📡 Stream user's currency (real-time + offline cache)
  Stream<CurrencyModel?> listenToUserCurrency(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots(includeMetadataChanges: true) // ✅ notifies when offline cache is used
        .map((snapshot) {
      if (snapshot.exists && snapshot.data()?['currency'] != null) {
        return CurrencyModel.fromMap(
          Map<String, dynamic>.from(snapshot.data()!['currency']),
        );
      }
      return null;
    });
  }
}
