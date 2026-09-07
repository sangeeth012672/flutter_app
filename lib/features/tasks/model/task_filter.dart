// lib/features/tasks/model/task_filter.dart
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

enum TaskFilterType { all, completed, pending }

enum TaskSortType { dueDate, priority, createdDate }

class TaskFilter {
  final TaskFilterType filterType;
  final TaskSortType sortType;
  final bool sortAscending;
  final String searchQuery;

  const TaskFilter({
    this.filterType = TaskFilterType.all,
    this.sortType = TaskSortType.createdDate,
    this.sortAscending = false,
    this.searchQuery = '',
  });

  TaskFilter copyWith({
    TaskFilterType? filterType,
    TaskSortType? sortType,
    bool? sortAscending,
    String? searchQuery,
  }) {
    return TaskFilter(
      filterType: filterType ?? this.filterType,
      sortType: sortType ?? this.sortType,
      sortAscending: sortAscending ?? this.sortAscending,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Apply filter and sort to a task list (client-side)
  List<TaskModel> apply(List<TaskModel> tasks) {
    var result = tasks.toList();

    // 1. Search filter
    if (searchQuery.isNotEmpty) {
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (t.description
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    // 2. Status filter
    switch (filterType) {
      case TaskFilterType.completed:
        result = result.where((t) => t.isCompleted).toList();
      case TaskFilterType.pending:
        result = result.where((t) => !t.isCompleted).toList();
      case TaskFilterType.all:
        break;
    }

    // 3. Sort
    result.sort((a, b) {
      int cmp;
      switch (sortType) {
        case TaskSortType.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            cmp = 0;
          } else if (a.dueDate == null) {
            cmp = 1;
          } else if (b.dueDate == null) {
            cmp = -1;
          } else {
            cmp = a.dueDate!.compareTo(b.dueDate!);
          }
        case TaskSortType.priority:
          cmp = _priorityValue(a.priority) - _priorityValue(b.priority);
        case TaskSortType.createdDate:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return sortAscending ? cmp : -cmp;
    });

    return result;
  }

  int _priorityValue(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.high:
        return 2;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFilter &&
          filterType == other.filterType &&
          sortType == other.sortType &&
          sortAscending == other.sortAscending &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(filterType, sortType, sortAscending, searchQuery);
}
