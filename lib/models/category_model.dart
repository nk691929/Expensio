import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final String id; // Unique category ID
  final String userId; // Foreign key: User who owns this category
  final String? accountId; // Optional foreign key: linked account (optional)
  final String name; // Category name
  final int budget; // Monthly budget
  final Color color; // Category color
  final IconData icon; // Category icon
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  CategoryModel({
    required this.id,
    required this.userId,
    this.accountId,
    required this.name,
    required this.budget,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert CategoryModel to map for DB storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'name': name,
      'budget': budget,
      'color': color.value, // store color as int
      'icon': icon.codePoint, // store icon as int
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create CategoryModel from DB map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      userId: map['userId'],
      accountId: map['accountId'],
      name: map['name'],
      budget: map['budget'],
      color: Color(map['color']),
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // CopyWith method for easy updates
  CategoryModel copyWith({
    String? name,
    int? budget,
    Color? color,
    IconData? icon,
    String? accountId,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id,
      userId: userId,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
