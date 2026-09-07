// lib/app/router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_task_manager/features/auth/controller/auth_controller.dart';
import 'package:smart_task_manager/features/auth/view/login_screen.dart';
import 'package:smart_task_manager/features/auth/view/register_screen.dart';
import 'package:smart_task_manager/features/profile/view/profile_screen.dart';
import 'package:smart_task_manager/features/tasks/view/task_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(

    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authControllerProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final status = authState.status;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (status == AuthStatus.unknown) return null;

      if (status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }

      if (status == AuthStatus.authenticated && isAuthRoute) {
        return '/tasks';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const MaterialPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => const MaterialPage(
          child: RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        pageBuilder: (context, state) => const MaterialPage(
          child: TaskListScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          child: const ProfileScreen(),
          key: state.pageKey,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

/// Adapter to make StateNotifier's stream work with GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
