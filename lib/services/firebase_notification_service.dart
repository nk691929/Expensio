import 'package:animationandcharts/models/app_notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart'; // ✅ Add this import

class FirebaseNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  /// ✅ Create a notification (Firestore + Local)
  Future<void> createNotification(AppNotification notification) async {
    await _notifications.doc(notification.id).set(notification.toMap());

    // 🛎️ Also show a local notification
    await NotificationService.showNotification(
      title: notification.title,
      body: notification.message,
      payload: "notificationId=${notification.id}", // 📦 pass payload for navigation
    );
  }

  /// 📥 Get a specific notification
  Future<AppNotification?> getNotification(String id) async {
    final doc = await _notifications.doc(id).get();
    if (doc.exists) {
      return AppNotification.fromMap(doc.data()!);
    }
    return null;
  }

  /// 📜 Get all notifications for a user (latest first)
  Future<List<AppNotification>> getUserNotifications(String userId) async {
    final query = await _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs
        .map((doc) => AppNotification.fromMap(doc.data()))
        .toList();
  }

  /// 📡 Real-time stream of notifications
  Stream<List<AppNotification>> listenToUserNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.data()))
            .toList());
  }

  /// ✏️ Mark as read
  Future<void> markAsRead(String id) async {
    await _notifications.doc(id).update({"isRead": true});
  }

  /// 📭 Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final query =
        await _notifications.where('userId', isEqualTo: userId).get();
    for (final doc in query.docs) {
      batch.update(doc.reference, {"isRead": true});
    }
    await batch.commit();
  }

  /// ❌ Delete notification
  Future<void> deleteNotification(String id) async {
    await _notifications.doc(id).delete();
  }

  /// ❌ Delete all notifications for a user
  Future<void> deleteAllUserNotifications(String userId) async {
    final query = await _notifications.where('userId', isEqualTo: userId).get();
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // 🔔 Budget alert
  Future<void> sendBudgetAlert({
    required String userId,
    required String categoryId,
    required double spent,
    required double budget,
  }) async {
    final notification = BudgetAlertNotification(
      id: _firestore.collection('notifications').doc().id,
      userId: userId,
      title: "⚠️ Budget Alert",
      message: "You've spent $spent of your $budget budget.",
      createdAt: DateTime.now(),
      categoryId: categoryId,
      spentAmount: spent,
      budget: budget,
    );
    await createNotification(notification);
  }

  // 🔔 Low balance alert
  Future<void> sendLowBalanceAlert({
    required String userId,
    required String accountId,
    required double balance,
    required double threshold,
  }) async {
    final notification = LowBalanceNotification(
      id: _firestore.collection('notifications').doc().id,
      userId: userId,
      title: "💸 Low Balance",
      message: "Your account balance is low: $balance (below $threshold).",
      createdAt: DateTime.now(),
      accountId: accountId,
      balance: balance,
      threshold: threshold,
    );
    await createNotification(notification);
  }

  // 📊 Weekly/Monthly summary
  Future<void> sendSummaryNotification({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final notification = SummaryNotification(
      id: _firestore.collection('notifications').doc().id,
      userId: userId,
      title: "📊 Expense Summary",
      message:
          "From ${startDate.toString().split(' ').first} to ${endDate.toString().split(' ').first}, you earned $totalIncome and spent $totalExpense.",
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
    await createNotification(notification);
  }
}
