// lib/features/tasks/data/local/task_local_source.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_task_manager/core/constants/app_constants.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

class TaskLocalSource {
  Box<String> get _box => Hive.box<String>(AppConstants.tasksBox);

  String _userKey(String userId) => '${AppConstants.tasksKey}_$userId';

  /// Load all cached tasks for user
  List<TaskModel> getTasks(String userId) {
    try {
      final raw = _box.get(_userKey(userId));
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => TaskModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      throw const CacheException(message: 'Failed to load cached tasks.');
    }
  }

  /// Cache all tasks for user
  Future<void> saveTasks(String userId, List<TaskModel> tasks) async {
    try {
      final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await _box.put(_userKey(userId), encoded);
    } catch (e) {
      throw const CacheException(message: 'Failed to cache tasks.');
    }
  }

  /// Upsert a single task in cache
  Future<void> upsertTask(String userId, TaskModel task) async {
    try {
      final current = getTasks(userId);
      final idx = current.indexWhere((t) => t.id == task.id);
      if (idx >= 0) {
        current[idx] = task;
      } else {
        current.insert(0, task);
      }
      await saveTasks(userId, current);
    } catch (e) {
      throw const CacheException(message: 'Failed to update cached task.');
    }
  }

  /// Remove a task from cache
  Future<void> deleteTask(String userId, int taskId) async {
    try {
      final current = getTasks(userId);
      current.removeWhere((t) => t.id == taskId);
      await saveTasks(userId, current);
    } catch (e) {
      throw const CacheException(message: 'Failed to delete cached task.');
    }
  }

  /// Clear all cached tasks for user
  Future<void> clearTasks(String userId) async {
    await _box.delete(_userKey(userId));
  }
}
