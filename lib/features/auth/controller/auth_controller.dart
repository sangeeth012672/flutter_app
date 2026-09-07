// lib/features/auth/controller/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/features/auth/model/user_model.dart';
import 'package:smart_task_manager/features/profile/model/profile_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthController(this._auth, this._firestore) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: UserModel.fromFirebaseUser(user),
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      final ex = AuthException.fromCode(e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: ex.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;

      // Update display name
      await user.updateDisplayName(name.trim());

      // Create Firestore profile
      final profile = ProfileModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        themeMode: 'system',
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile.toFirestore());

      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      final ex = AuthException.fromCode(e.code);
      state = state.copyWith(
        isLoading: false,
        errorMessage: ex.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String? get currentUserId => _auth.currentUser?.uid;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.uid;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authControllerProvider).status;
});
