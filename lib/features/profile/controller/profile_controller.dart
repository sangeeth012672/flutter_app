// lib/features/profile/controller/profile_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/features/profile/model/profile_model.dart';

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileController(this._firestore, this._auth) : super(const ProfileState());

  String? get _uid => _auth.currentUser?.uid;

  Future<void> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .withConverter<ProfileModel>(
            fromFirestore: (snap, _) => ProfileModel.fromFirestore(snap),
            toFirestore: (model, _) => model.toFirestore(),
          )
          .get();
      if (doc.exists) {
        state = state.copyWith(
          profile: doc.data(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile.',
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    String? themeMode,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updates = <String, dynamic>{'name': name.trim()};
      if (themeMode != null) updates['themeMode'] = themeMode;

      await _firestore.collection('users').doc(uid).update(updates);

      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(name.trim());

      state = state.copyWith(
        profile: state.profile?.copyWith(
          name: name.trim(),
          themeMode: themeMode ?? state.profile?.themeMode,
        ),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile.',
      );
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});
