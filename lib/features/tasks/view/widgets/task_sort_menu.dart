// lib/features/tasks/view/widgets/task_sort_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_strings.dart';
import 'package:smart_task_manager/features/tasks/controller/task_controller.dart';
import 'package:smart_task_manager/features/tasks/model/task_filter.dart';

class TaskSortMenu extends ConsumerWidget {
  const TaskSortMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider.notifier);
    final currentSort = controller.filter.sortType;
    final ascending = controller.filter.sortAscending;

    return PopupMenuButton<TaskSortType>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: AppStrings.sortBy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (sort) {
        if (sort == currentSort) {
          controller.setSort(sort, ascending: !ascending);
        } else {
          controller.setSort(sort, ascending: false);
        }
      },
      itemBuilder: (context) => [
        _buildItem(context, AppStrings.sortCreatedDate, Icons.calendar_today_rounded, TaskSortType.createdDate, currentSort, ascending),
        _buildItem(context, AppStrings.sortDueDate, Icons.event_rounded, TaskSortType.dueDate, currentSort, ascending),
        _buildItem(context, AppStrings.sortPriority, Icons.flag_rounded, TaskSortType.priority, currentSort, ascending),
      ],
    );
  }

  PopupMenuItem<TaskSortType> _buildItem(
    BuildContext context,
    String label,
    IconData icon,
    TaskSortType value,
    TaskSortType current,
    bool ascending,
  ) {
    final isSelected = value == current;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? scheme.primary : null),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? scheme.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 16,
              color: scheme.primary,
            ),
        ],
      ),
    );
  }
}
