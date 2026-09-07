// lib/features/profile/model/profile_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String themeMode; // 'system' | 'light' | 'dark'

  const ProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.themeMode = 'system',
  });

  factory ProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProfileModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      themeMode: data['themeMode'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'themeMode': themeMode,
    };
  }

  ProfileModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    String? themeMode,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  String toString() =>
      'ProfileModel(uid: $uid, name: $name, email: $email, themeMode: $themeMode)';
}
