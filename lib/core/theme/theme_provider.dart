// lib/core/theme/theme_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────
class ThemeState {
  final ThemeMode themeMode;
  const ThemeState({this.themeMode = ThemeMode.system});
  ThemeState copyWith({ThemeMode? themeMode}) =>
      ThemeState(themeMode: themeMode ?? this.themeMode);
}

// ── Controller ────────────────────────────────────────────
class ThemeController extends StateNotifier<ThemeState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ThemeController(this._firestore, this._auth)
      : super(const ThemeState()) {
    _loadLocalTheme();
  }

  /// Load from SharedPreferences first (fast), then sync from Firestore
  Future<void> _loadLocalTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.themeModeKey);
    if (saved != null) {
      state = ThemeState(themeMode: _parseMode(saved));
    }
  }

  Future<void> loadFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      final themeStr = doc.data()?['themeMode'] as String?;
      if (themeStr != null) {
        final mode = _parseMode(themeStr);
        state = state.copyWith(themeMode: mode);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.themeModeKey, themeStr);
      }
    } catch (_) {
      // Fall back to local preference
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final modeStr = _modeString(mode);

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, modeStr);

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'themeMode': modeStr})
          .catchError((_) {});
    }
  }

  void toggleTheme() {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(next);
  }

  ThemeMode _parseMode(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  String _modeString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }
}

// ── Providers ─────────────────────────────────────────────
final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeState>((ref) {
  return ThemeController(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeControllerProvider).themeMode;
});
