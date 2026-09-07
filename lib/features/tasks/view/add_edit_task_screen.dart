// lib/features/tasks/view/add_edit_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/utils/date_formatter.dart';
import 'package:smart_task_manager/core/utils/validators.dart';
import 'package:smart_task_manager/features/tasks/controller/task_controller.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task; // null = add, non-null = edit

  const AddEditTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late TaskPriority _priority;
  late TaskCategory _category;
  DateTime? _dueDate;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _category = task?.category ?? TaskCategory.work;
    _dueDate = task?.dueDate;
    _isCompleted = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: scheme.error,
              onPressed: _confirmDelete,
              tooltip: 'Delete task',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              validator: Validators.validateTaskTitle,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add details (optional)',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Due Date
            const _SectionLabel(label: 'Due Date'),
            const SizedBox(height: 8),
            _DatePickerTile(
              selectedDate: _dueDate,
              onDatePicked: (d) => setState(() => _dueDate = d),
              onClear: () => setState(() => _dueDate = null),
            ),
            const SizedBox(height: 20),

            // Priority
            const _SectionLabel(label: 'Priority'),
            const SizedBox(height: 8),
            _PrioritySelector(
              value: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 20),

            // Category
            const _SectionLabel(label: 'Category'),
            const SizedBox(height: 8),
            _CategorySelector(
              value: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 20),

            // Completed toggle
            SwitchListTile.adaptive(
              value: _isCompleted,
              onChanged: (v) => setState(() => _isCompleted = v),
              title: const Text('Mark as completed'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Task' : 'Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final dto = TaskCreateDto(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isCompleted: _isCompleted,
      dueDate: _dueDate,
      priority: _priority,
      category: _category,
    );

    final controller = ref.read(taskControllerProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await controller.updateTask(widget.task!.id, dto);
    } else {
      success = await controller.createTask(dto);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Task updated successfully!' : 'Task created!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      final err = ref.read(taskControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

    if (confirmed == true && mounted) {
      final success = await ref
          .read(taskControllerProvider.notifier)
          .deleteTask(widget.task!.id);
      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted')),
          );
        }
      }
    }
  }
}

// ── Sub-widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onClear;

  const _DatePickerTile({
    required this.selectedDate,
    required this.onDatePicked,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          // Also pick time
          if (context.mounted) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(
                selectedDate ?? DateTime.now(),
              ),
            );
            final combined = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time?.hour ?? 23,
              time?.minute ?? 59,
            );
            onDatePicked(combined);
          }
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              color: selectedDate != null ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormatter.formatDateTime(selectedDate)
                    : 'Select due date (optional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selectedDate != null
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = value == p;
        final color = switch (p) {
          TaskPriority.low    => const Color(0xFF2ED573),
          TaskPriority.medium => const Color(0xFFFFB347),
          TaskPriority.high   => const Color(0xFFFF4757),
        };
        final label = switch (p) {
          TaskPriority.low    => 'Low',
          TaskPriority.medium => 'Medium',
          TaskPriority.high   => 'High',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.flag_rounded, color: color, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final TaskCategory value;
  final ValueChanged<TaskCategory> onChanged;

  const _CategorySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskCategory.values.map((c) {
        final isSelected = value == c;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? scheme.primary : Colors.transparent,
              ),
            ),
            child: Text(
              c.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
