import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final String title;
  final String? description;
  final double amount;
  final String type;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  // 🔹 Firestore map (rules-compliant)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'categoryId': categoryId,
      'title': title,
      'description': description ?? '', // must be string
      'amount': amount.abs(), // number
      'type': type,
      'date': Timestamp.fromDate(date),
      'time': DateFormat('HH:mm').format(date), // required by rules
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['userId'],
      accountId: map['accountId'],
      categoryId: map['categoryId'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'].toDouble(),
      type: map['type'],
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
