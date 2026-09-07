// lib/features/tasks/controller/task_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/features/auth/controller/auth_controller.dart';
import 'package:smart_task_manager/features/tasks/model/task_filter.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';
import 'package:smart_task_manager/features/tasks/repository/task_repository.dart';

class TaskState {
  final List<TaskModel> tasks;       // full loaded list (raw from API/cache)
  final List<TaskModel> displayed;   // after filter + sort + search
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentSkip;
  final String? errorMessage;
  final AppException? exception;

  const TaskState({
    this.tasks = const [],
    this.displayed = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentSkip = 0,
    this.errorMessage,
    this.exception,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    List<TaskModel>? displayed,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentSkip,
    String? errorMessage,
    AppException? exception,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      displayed: displayed ?? this.displayed,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentSkip: currentSkip ?? this.currentSkip,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exception: clearError ? null : (exception ?? this.exception),
    );
  }
}

class TaskController extends StateNotifier<TaskState> {
  final TaskRepository _repository;
  final String _userId;

  TaskFilter _filter = const TaskFilter();
  Timer? _searchDebounce;

  TaskController(this._repository, this._userId) : super(const TaskState()) {
    fetchTasks();
  }

  TaskFilter get filter => _filter;

  Future<void> fetchTasks({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentSkip: 0,
      hasMore: true,
    );

    try {
      final tasks = await _repository.getTasks(
        userId: _userId,
        skip: 0,
        limit: AppConstants.pageLimit,
      );

      final hasMore = tasks.length >= AppConstants.pageLimit;
      state = state.copyWith(
        tasks: tasks,
        displayed: _filter.apply(tasks),
        isLoading: false,
        currentSkip: tasks.length,
        hasMore: hasMore,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        exception: e,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final newTasks = await _repository.getTasks(
        userId: _userId,
        skip: state.currentSkip,
        limit: AppConstants.pageLimit,
      );

      if (newTasks.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      // Merge: remove duplicates by id
      final merged = [...state.tasks];
      for (final t in newTasks) {
        if (!merged.any((existing) => existing.id == t.id)) {
          merged.add(t);
        }
      }

      state = state.copyWith(
        tasks: merged,
        displayed: _filter.apply(merged),
        isLoadingMore: false,
        currentSkip: state.currentSkip + newTasks.length,
        hasMore: newTasks.length >= AppConstants.pageLimit,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
      );
    }
  }

  void setFilter(TaskFilterType type) {
    _filter = _filter.copyWith(filterType: type);
    _applyFilter();
  }

  void setSort(TaskSortType sortType, {bool? ascending}) {
    _filter = _filter.copyWith(
      sortType: sortType,
      sortAscending: ascending ?? _filter.sortAscending,
    );
    _applyFilter();
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        _filter = _filter.copyWith(searchQuery: query);
        _applyFilter();
      },
    );
  }

  void _applyFilter() {
    state = state.copyWith(displayed: _filter.apply(state.tasks));
  }

  Future<bool> createTask(TaskCreateDto dto) async {
    try {
      final created = await _repository.createTask(
        userId: _userId,
        dto: dto,
      );
      // Optimistic: prepend to list
      final updated = [created, ...state.tasks];
      state = state.copyWith(
        tasks: updated,
        displayed: _filter.apply(updated),
        currentSkip: state.currentSkip + 1,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message, exception: e);
      return false;
    }
  }

  Future<bool> updateTask(int taskId, TaskCreateDto dto) async {
    // Optimistic: update in list immediately
    final originalTasks = state.tasks;
    final optimisticTasks = state.tasks.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        title: dto.title,
        description: dto.description,
        isCompleted: dto.isCompleted,
        dueDate: dto.dueDate,
        priority: dto.priority,
        category: dto.category,
        updatedAt: DateTime.now(),
        clearDueDate: dto.dueDate == null,
      );
    }).toList();

    state = state.copyWith(
      tasks: optimisticTasks,
      displayed: _filter.apply(optimisticTasks),
    );

    try {
      final updated = await _repository.updateTask(
        userId: _userId,
        taskId: taskId,
        dto: dto,
      );
      // Replace with server response
      final confirmed = state.tasks
          .map((t) => t.id == taskId ? updated : t)
          .toList();
      state = state.copyWith(
        tasks: confirmed,
        displayed: _filter.apply(confirmed),
      );
      return true;
    } on AppException catch (e) {
      // Rollback on failure
      state = state.copyWith(
        tasks: originalTasks,
        displayed: _filter.apply(originalTasks),
        errorMessage: e.message,
        exception: e,
      );
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    // Optimistic: remove from list immediately
    final originalTasks = state.tasks;
    final optimisticTasks = state.tasks.where((t) => t.id != taskId).toList();

    state = state.copyWith(
      tasks: optimisticTasks,
      displayed: _filter.apply(optimisticTasks),
    );

    try {
      await _repository.deleteTask(userId: _userId, taskId: taskId);
      return true;
    } on AppException catch (e) {
      // Rollback
      state = state.copyWith(
        tasks: originalTasks,
        displayed: _filter.apply(originalTasks),
        errorMessage: e.message,
        exception: e,
      );
      return false;
    }
  }

  Future<bool> toggleComplete(TaskModel task) async {
    final dto = TaskCreateDto(
      title: task.title,
      description: task.description,
      isCompleted: !task.isCompleted,
      dueDate: task.dueDate,
      priority: task.priority,
      category: task.category,
    );
    return updateTask(task.id, dto);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

final taskControllerProvider =
    StateNotifierProvider.autoDispose<TaskController, TaskState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.read(taskRepositoryProvider);
  if (userId == null) throw Exception('User not logged in');
  return TaskController(repository, userId);
});
