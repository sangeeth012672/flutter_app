// lib/features/tasks/view/widgets/offline_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(isOnlineProvider);

    return connectivity.when(
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return _BannerWidget();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: scheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Text(
            'You\'re offline • Showing cached data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: -1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
