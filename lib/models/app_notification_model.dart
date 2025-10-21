// Base Notification Model
class AppNotification {
  final String id;          // Unique notification ID
  final String userId;      // Foreign key: user who receives this notification
  final String type;        // Type of notification: "budget", "low_balance", "summary"
  final String title;       // Notification title
  final String message;     // Notification message
  final bool isRead;        // Has user read the notification?
  final DateTime createdAt; // When notification was created

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      title: map['title'],
      message: map['message'],
      isRead: map['isRead'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

/// 1️⃣ Budget Alert Notification
class BudgetAlertNotification extends AppNotification {
  final String categoryId;   // Related category
  final double spentAmount;  // Amount spent in the category
  final double budget;       // Budget limit

  BudgetAlertNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required DateTime createdAt,
    this.categoryId = "",
    this.spentAmount = 0.0,
    this.budget = 0.0,
    bool isRead = false,
  }) : super(
          id: id,
          userId: userId,
          type: "budget",
          title: title,
          message: message,
          isRead: isRead,
          createdAt: createdAt,
        );
}

/// 2️⃣ Low Balance Notification
class LowBalanceNotification extends AppNotification {
  final String accountId;   // Related account
  final double balance;     // Current balance
  final double threshold;   // Threshold set for alert

  LowBalanceNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required DateTime createdAt,
    this.accountId = "",
    this.balance = 0.0,
    this.threshold = 0.0,
    bool isRead = false,
  }) : super(
          id: id,
          userId: userId,
          type: "low_balance",
          title: title,
          message: message,
          isRead: isRead,
          createdAt: createdAt,
        );
}

/// 4️⃣ Weekly/Monthly Summary Notification
class SummaryNotification extends AppNotification {
  final DateTime startDate;   // Start of summary period
  final DateTime endDate;     // End of summary period
  final double totalIncome;   // Total income
  final double totalExpense;  // Total expense

  SummaryNotification({
    required String id,
    required String userId,
    required String title,
    required String message,
    required DateTime createdAt,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    bool isRead = false,
  }) : super(
          id: id,
          userId: userId,
          type: "summary",
          title: title,
          message: message,
          isRead: isRead,
          createdAt: createdAt,
        );
}
