// lib/features/tasks/view/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_task_manager/core/theme/app_theme.dart';
import 'package:smart_task_manager/core/utils/date_formatter.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isOverdue =
        !task.isCompleted && DateFormatter.isOverdue(task.dueDate);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete?.call(),
      background: _DismissBackground(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggleComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted
                          ? scheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: scheme.onPrimary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Tags row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _PriorityChip(priority: task.priority),
                          _CategoryChip(category: task.category),
                          if (task.dueDate != null)
                            _DueDateChip(
                              dueDate: task.dueDate!,
                              isOverdue: isOverdue,
                              isCompleted: task.isCompleted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Priority indicator bar
                const SizedBox(width: 8),
                _PriorityBar(priority: task.priority),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.05, end: 0, duration: 300.ms),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Dismiss Background ─────────────────────────────────────
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high   => AppTheme.priorityHigh,
      TaskPriority.medium => AppTheme.priorityMedium,
      TaskPriority.low    => AppTheme.priorityLow,
    };
    final label = switch (priority) {
      TaskPriority.high   => 'High',
      TaskPriority.medium => 'Med',
      TaskPriority.low    => 'Low',
    };
    return _Tag(label: label, color: color);
  }
}

class _CategoryChip extends StatelessWidget {
  final TaskCategory category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Tag(
      label: category.displayName,
      color: scheme.secondaryContainer,
      textColor: scheme.onSecondaryContainer,
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final DateTime dueDate;
  final bool isOverdue;
  final bool isCompleted;
  const _DueDateChip({
    required this.dueDate,
    required this.isOverdue,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isOverdue && !isCompleted ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final textColor = isOverdue && !isCompleted ? scheme.onErrorContainer : scheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tag(
          label: DateFormatter.formatRelative(dueDate),
          color: color,
          textColor: textColor,
          icon: Icons.event_rounded,
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;

  const _Tag({
    required this.label,
    required this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedText = textColor ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: resolvedText),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: resolvedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Priority bar accent ───────────────────────────────────
class _PriorityBar extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBar({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high   => AppTheme.priorityHigh,
      TaskPriority.medium => AppTheme.priorityMedium,
      TaskPriority.low    => AppTheme.priorityLow,
    };
    return Container(
      width: 4,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
