// lib/features/tasks/view/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_strings.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/features/tasks/controller/task_controller.dart';
import 'package:smart_task_manager/features/tasks/view/add_edit_task_screen.dart';
import 'package:smart_task_manager/features/tasks/view/widgets/empty_state_widget.dart';
import 'package:smart_task_manager/features/tasks/view/widgets/offline_banner.dart';
import 'package:smart_task_manager/features/tasks/view/widgets/task_card.dart';
import 'package:smart_task_manager/features/tasks/view/widgets/task_filter_bar.dart';
import 'package:smart_task_manager/features/tasks/view/widgets/task_sort_menu.dart';
import 'package:go_router/go_router.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(taskControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    // Show snackbar when error occurs
    ref.listen(taskControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: next.exception is NetworkException
                  ? scheme.error
                  : scheme.errorContainer,
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () =>
                    ref.read(taskControllerProvider.notifier).clearError(),
              ),
            ),
          );
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, taskState),
      body: Column(
        children: [
          // Offline banner
          const OfflineBanner(),

          // Search bar
          if (_showSearch)
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (q) =>
                  ref.read(taskControllerProvider.notifier).setSearchQuery(q),
              onClose: () {
                setState(() => _showSearch = false);
                _searchCtrl.clear();
                ref.read(taskControllerProvider.notifier).setSearchQuery('');
              },
            ).animate().slideY(begin: -0.5, end: 0, duration: 200.ms),

          // Filter bar
          const SizedBox(height: 12),
          const TaskFilterBar(),
          const SizedBox(height: 8),

          // Task list
          Expanded(child: _buildBody(context, taskState)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTask(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, TaskState taskState) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Tasks'),
          if (!taskState.isLoading)
            Text(
              '${taskState.displayed.length} task${taskState.displayed.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off_rounded : Icons.search_rounded),
          onPressed: () => setState(() => _showSearch = !_showSearch),
          tooltip: 'Search',
        ),
        const TaskSortMenu(),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => context.push('/profile'),
          tooltip: 'Profile',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TaskState taskState) {
    if (taskState.isLoading) {
      return const _LoadingShimmer();
    }

    if (taskState.exception != null && taskState.tasks.isEmpty) {
      return EmptyStateWidget(
        icon: taskState.exception is NetworkException
            ? Icons.wifi_off_rounded
            : Icons.error_outline_rounded,
        title: taskState.exception is NetworkException
            ? 'No Connection'
            : 'Something went wrong',
        subtitle: taskState.errorMessage ?? AppStrings.genericError,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(taskControllerProvider.notifier).fetchTasks(refresh: true),
      );
    }

    if (taskState.displayed.isEmpty) {
      return EmptyStateWidget(
        title: _searchCtrl.text.isNotEmpty
            ? AppStrings.noResultsFound
            : AppStrings.noTasks,
        subtitle: _searchCtrl.text.isNotEmpty
            ? AppStrings.noResultsSubtitle
            : AppStrings.noTasksSubtitle,
        icon: _searchCtrl.text.isNotEmpty
            ? Icons.search_off_rounded
            : Icons.task_alt_rounded,
        actionLabel:
            _searchCtrl.text.isEmpty ? 'Add Task' : null,
        onAction: _searchCtrl.text.isEmpty
            ? () => _openAddTask(context)
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(taskControllerProvider.notifier).fetchTasks(refresh: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount:
            taskState.displayed.length + (taskState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == taskState.displayed.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final task = taskState.displayed[index];
          return TaskCard(
            key: ValueKey(task.id),
            task: task,
            index: index,
            onTap: () => _openEditTask(context, task.id),
            onToggleComplete: () => ref
                .read(taskControllerProvider.notifier)
                .toggleComplete(task),
            onDelete: () =>
                ref.read(taskControllerProvider.notifier).deleteTask(task.id),
          );
        },
      ),
    );
  }

  void _openAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditTaskScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openEditTask(BuildContext context, int taskId) {
    final task = ref
        .read(taskControllerProvider)
        .tasks
        .firstWhere((t) => t.id == taskId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(task: task),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppStrings.search,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ),
      ),
    );
  }
}

// ── Loading Shimmer ───────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(
              duration: 1200.ms,
              color: scheme.surfaceContainerHighest,
            ),
      ),
    );
  }
}
