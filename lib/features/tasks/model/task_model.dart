// lib/features/tasks/model/task_model.dart

enum TaskPriority { low, medium, high }

enum TaskCategory {
  work,
  personal,
  health,
  finance,
  education,
  shopping,
  travel,
  others,
}

extension TaskPriorityExt on TaskPriority {
  String get apiValue {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  static TaskPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }
}

extension TaskCategoryExt on TaskCategory {
  String get apiValue {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.finance:
        return 'Finance';
      case TaskCategory.education:
        return 'Education';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.travel:
        return 'Travel';
      case TaskCategory.others:
        return 'Others';
    }
  }

  static TaskCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'personal':
        return TaskCategory.personal;
      case 'health':
        return TaskCategory.health;
      case 'finance':
        return TaskCategory.finance;
      case 'education':
        return TaskCategory.education;
      case 'shopping':
        return TaskCategory.shopping;
      case 'travel':
        return TaskCategory.travel;
      case 'others':
        return TaskCategory.others;
      default:
        return TaskCategory.work;
    }
  }

  String get displayName => apiValue;
}

class TaskModel {
  final int id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.work,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      priority: TaskPriorityExt.fromString(json['priority'] as String?),
      category: TaskCategoryExt.fromString(json['category'] as String?),
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'priority': priority.apiValue,
      'category': category.apiValue,
      'user_id': userId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toHiveMap() => toJson();

  factory TaskModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return TaskModel.fromJson(Map<String, dynamic>.from(map));
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskCategory? category,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDueDate = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      category: category ?? this.category,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskModel && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, isCompleted: $isCompleted)';
}

class TaskCreateDto {
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskCategory category;

  const TaskCreateDto({
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.work,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'is_completed': isCompleted,
      if (dueDate != null) 'due_date': dueDate!.toUtc().toIso8601String(),
      'priority': priority.apiValue,
      'category': category.apiValue,
    };
  }
}
