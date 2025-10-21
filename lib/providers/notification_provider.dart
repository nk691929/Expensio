import 'package:animationandcharts/models/app_notification_model.dart';
import 'package:animationandcharts/services/firebase_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔧 Provide NotificationService
final notificationServiceProvider = Provider<FirebaseNotificationService>((ref) {
  return FirebaseNotificationService();
});

/// 📡 Real-time notification stream
final userNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  final service = ref.watch(notificationServiceProvider);
  return service.listenToUserNotifications(userId);
});

/// 📦 Load once (non-stream)
final userNotificationsFutureProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getUserNotifications(userId);
});