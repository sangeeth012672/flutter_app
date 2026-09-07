// lib/features/tasks/repository/task_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/core/network/connectivity_service.dart';
import 'package:smart_task_manager/core/network/dio_client.dart';
import 'package:smart_task_manager/features/tasks/data/local/task_local_source.dart';
import 'package:smart_task_manager/features/tasks/data/remote/task_remote_source.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

class TaskRepository {
  final TaskRemoteSource _remote;
  final TaskLocalSource _local;
  final ConnectivityService _connectivity;

  TaskRepository({
    required TaskRemoteSource remote,
    required TaskLocalSource local,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

  // Offline-first fetch: Try API, fallback to cache
  Future<List<TaskModel>> getTasks({
    required String userId,
    int skip = 0,
    int limit = 10,
  }) async {
    final isOnline = await _connectivity.isConnected();

    if (isOnline) {
      try {
        final tasks = await _remote.getTasks(
          userId: userId,
          skip: skip,
          limit: limit,
        );
        // Cache the first page (fresh load)
        if (skip == 0) {
          await _local.saveTasks(userId, tasks);
        }
        return tasks;
      } on NetworkException {
        // Fall through to cache
        return _local.getTasks(userId);
      }
    } else {
      // Return from cache
      final cached = _local.getTasks(userId);
      if (cached.isEmpty && skip == 0) {
        throw const NetworkException(
          message: 'You\'re offline and no cached tasks are available.',
        );
      }
      return cached;
    }
  }

  Future<TaskModel> createTask({
    required String userId,
    required TaskCreateDto dto,
  }) async {
    await _assertOnline();
    final task = await _remote.createTask(userId: userId, dto: dto);
    await _local.upsertTask(userId, task);
    return task;
  }

  Future<TaskModel> updateTask({
    required String userId,
    required int taskId,
    required TaskCreateDto dto,
  }) async {
    await _assertOnline();
    final task = await _remote.updateTask(
      userId: userId,
      taskId: taskId,
      dto: dto,
    );
    await _local.upsertTask(userId, task);
    return task;
  }

  Future<void> deleteTask({
    required String userId,
    required int taskId,
  }) async {
    await _assertOnline();
    await _remote.deleteTask(userId: userId, taskId: taskId);
    await _local.deleteTask(userId, taskId);
  }

  Future<void> _assertOnline() async {
    final online = await _connectivity.isConnected();
    if (!online) {
      throw const NetworkException(
        message: 'This action requires an internet connection.',
      );
    }
  }
}

final taskRemoteSourceProvider = Provider<TaskRemoteSource>((ref) {
  return TaskRemoteSource(ref.read(dioClientProvider));
});

final taskLocalSourceProvider = Provider<TaskLocalSource>((ref) {
  return TaskLocalSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    remote: ref.read(taskRemoteSourceProvider),
    local: ref.read(taskLocalSourceProvider),
    connectivity: ref.read(connectivityServiceProvider),
  );
});
