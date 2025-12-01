import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';
import 'package:flutter/material.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final WorkspaceRepository? workspaceRepository;

  TaskRepositoryImpl({
    required this.localDataSource,
    this.workspaceRepository,
  });

  @override
  Future<List<Task>> getAllTasks() async {
    try {
      final taskModels = await localDataSource.getAllTasks();
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  @override
  Future<Task?> getTaskById(int id) async {
    try {
      final taskModel = await localDataSource.getTaskById(id);
      return taskModel?.toEntity();
    } catch (e) {
      throw Exception('Failed to get task by id: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end) async {
    try {
      final taskModels = await localDataSource.getTasksByDateRange(start, end);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date range: $e');
    }
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    try {
      final taskModels = await localDataSource.getCompletedTasks();
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get completed tasks: $e');
    }
  }

  @override
  Future<List<Task>> getPendingTasks() async {
    try {
      final taskModels = await localDataSource.getPendingTasks();
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get pending tasks: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    try {
      final taskModels = await localDataSource.getTasksByPriority(priority);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by priority: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByCategory(String category) async {
    try {
      final taskModels = await localDataSource.getTasksByCategory(category);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by category: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByWorkspaceId(int workspaceId) async {
    try {
      final taskModels = await localDataSource.getTasksByWorkspaceId(workspaceId);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by workspace ID: $e');
    }
  }

  @override
  Future<void> createTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      await localDataSource.createTask(taskModel);
      
      if (task.workspaceId != null && workspaceRepository != null) {
        await _updateWorkspaceStatistics(task.workspaceId!);
      }
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      final existingTaskModel = await localDataSource.getTaskById(task.id);
      if (existingTaskModel != null) {
        existingTaskModel.updateFromEntity(task);
        await localDataSource.updateTask(existingTaskModel);
      } else {
        final taskModel = TaskModel.fromEntity(task);
        await localDataSource.updateTask(taskModel);
      }
      
      if (task.workspaceId != null && workspaceRepository != null) {
        await _updateWorkspaceStatistics(task.workspaceId!);
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      final taskModel = await localDataSource.getTaskById(id);
      if (taskModel == null) {
        throw Exception('Task with id $id not found');
      }
      
      final result = await localDataSource.deleteTask(id);
      if (!result) {
        throw Exception('Task with id $id not found');
      }
      
      if (taskModel.workspaceId != null && workspaceRepository != null) {
        await _updateWorkspaceStatistics(taskModel.workspaceId!);
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<void> toggleTaskCompletion(int id) async {
    try {
      final taskModel = await localDataSource.getTaskById(id);
      if (taskModel == null) {
        throw Exception('Task with id $id not found');
      }
      
      await localDataSource.toggleTaskCompletion(id);
      
      if (taskModel.workspaceId != null && workspaceRepository != null) {
        await _updateWorkspaceStatistics(taskModel.workspaceId!);
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  @override
  Future<void> deleteCompletedTasks() async {
    try {
      await localDataSource.deleteCompletedTasks();
    } catch (e) {
      throw Exception('Failed to delete completed tasks: $e');
    }
  }

  @override
  Future<int> getTasksCount() async {
    try {
      return await localDataSource.getTasksCount();
    } catch (e) {
      throw Exception('Failed to get tasks count: $e');
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    try {
      final taskModels = await localDataSource.searchTasks(query);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return localDataSource.watchAllTasks().map((taskModels) => 
      taskModels.map((model) => model.toEntity()).toList()
    );
  }

  Future<void> _updateWorkspaceStatistics(int workspaceId) async {
    if (workspaceRepository == null) return;
    
    try {
      final allTasks = await localDataSource.getAllTasks();
      final workspaceTasks = allTasks.where((task) => task.workspaceId == workspaceId).toList();
      
      final totalTasks = workspaceTasks.length;
      final completedTasks = workspaceTasks.where((task) => task.isCompleted).length;
      
      await workspaceRepository!.updateWorkspaceTaskCounts(
        workspaceId, 
        totalTasks, 
        completedTasks
      );
    } catch (e) {
      debugPrint('Failed to update workspace statistics: $e');
    }
  }
}
