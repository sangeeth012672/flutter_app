// lib/features/tasks/view/widgets/task_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_strings.dart';
import 'package:smart_task_manager/features/tasks/controller/task_controller.dart';
import 'package:smart_task_manager/features/tasks/model/task_filter.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider.notifier);
    final currentFilter = ref.watch(taskControllerProvider).isLoading
        ? TaskFilterType.all
        : controller.filter.filterType;

    final tabs = [
      (TaskFilterType.all, AppStrings.all),
      (TaskFilterType.pending, AppStrings.pending),
      (TaskFilterType.completed, AppStrings.completed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = currentFilter == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: tab.$2,
              isSelected: isSelected,
              onTap: () => controller.setFilter(tab.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}
