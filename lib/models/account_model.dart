import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Account {
  final String id; // Unique account ID
  final String userId; // Foreign key linking to user
  final String name; // Account name
  final String? holder; // Holder name (optional)
  final String? number; // Account number (optional)
  final double balance; // Current balance
  final int colorValue; // Color stored as int (Color.value)
  final String logo; // Logo identifier (e.g., "wallet", "credit_card")
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Account({
    required this.id,
    required this.userId,
    required this.name,
    this.holder,
    this.number,
    required this.balance,
    required this.colorValue,
    required this.logo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert int to Color
  Color get color => Color(colorValue);

  // Convert Account to Map for DB storage
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "name": name,
      "holder": holder,
      "number": number,
      "balance": balance,
      "colorValue": colorValue,
      "logo": logo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Account from Map (e.g., from DB)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      holder: map['holder'],
      number: map['number'],
      balance: (map['balance'] as num).toDouble(),
      colorValue: map['colorValue'],
      logo: map['logo'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Copy with method for updating
  Account copyWith({
    String? name,
    String? holder,
    String? number,
    double? balance,
    int? colorValue,
    String? logo,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      userId: userId,
      name: name ?? this.name,
      holder: holder ?? this.holder,
      number: number ?? this.number,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      logo: logo ?? this.logo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
