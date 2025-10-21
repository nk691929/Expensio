class UserModel {
  final String id;                // Unique user ID
  final String name;              // Full name
  final String email;             // Email (unique, non-editable)
  final String? bio;              // Short bio
  final String? profileImageUrl;  // URL to profile image
  final String? token;            // FCM device token for push notifications
  final DateTime createdAt;       // Account creation timestamp
  final DateTime updatedAt;       // Last profile update timestamp

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.token,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert UserModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create UserModel from Map (e.g., from Firestore/Supabase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      token: map['token'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? name,
    String? bio,
    String? profileImageUrl,
    String? token,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      token: token ?? this.token,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
