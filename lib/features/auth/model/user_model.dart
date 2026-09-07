// lib/features/auth/model/user_model.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory UserModel.fromFirebaseUser(fb.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName)';
}
