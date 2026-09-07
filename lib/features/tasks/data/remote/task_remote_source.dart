// lib/features/tasks/data/remote/task_remote_source.dart
import 'package:dio/dio.dart';
import 'package:smart_task_manager/core/errors/app_exception.dart';
import 'package:smart_task_manager/core/network/dio_client.dart';
import 'package:smart_task_manager/features/tasks/model/task_model.dart';

class TaskRemoteSource {
  final DioClient _client;

  TaskRemoteSource(this._client);

  Future<List<TaskModel>> getTasks({
    required String userId,
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/tasks/',
        queryParameters: {
          'user_id': userId,
          'skip': skip,
          'limit': limit,
        },
      );
      final data = response.data!;
      final taskList = data['data'] as List<dynamic>? ?? [];
      return taskList
          .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioToAppException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch tasks: $e');
    }
  }

  Future<TaskModel> createTask({
    required String userId,
    required TaskCreateDto dto,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/tasks/',
        queryParameters: {'user_id': userId},
        data: dto.toJson(),
      );
      return TaskModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw dioToAppException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to create task: $e');
    }
  }

  Future<TaskModel> updateTask({
    required String userId,
    required int taskId,
    required TaskCreateDto dto,
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/tasks/$taskId',
        queryParameters: {'user_id': userId},
        data: dto.toJson(),
      );
      return TaskModel.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw dioToAppException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to update task: $e');
    }
  }

  Future<void> deleteTask({
    required String userId,
    required int taskId,
  }) async {
    try {
      await _client.delete<Map<String, dynamic>>(
        '/tasks/$taskId',
        queryParameters: {'user_id': userId},
      );
    } on DioException catch (e) {
      throw dioToAppException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to delete task: $e');
    }
  }
}
