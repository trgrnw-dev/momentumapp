import '../entities/task.dart';

/// Task Repository Interface (Domain Layer)
/// Defines the contract for task data operations
/// Implementation will be in the data layer
abstract class TaskRepository {
  /// Get all tasks
  Future<List<Task>> getAllTasks();

  /// Get task by id
  Future<Task?> getTaskById(int id);

  /// Get tasks by date range
  Future<List<Task>> getTasksByDateRange(DateTime start, DateTime end);

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks();

  /// Get pending tasks
  Future<List<Task>> getPendingTasks();

  /// Get tasks by priority
  Future<List<Task>> getTasksByPriority(TaskPriority priority);

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(String category);

  /// Get tasks by workspace ID
  Future<List<Task>> getTasksByWorkspaceId(int workspaceId);

  /// Create a new task
  Future<void> createTask(Task task);

  /// Update an existing task
  Future<void> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(int id);

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(int id);

  /// Delete all completed tasks
  Future<void> deleteCompletedTasks();

  /// Get tasks count
  Future<int> getTasksCount();

  /// Search tasks by title or description
  Future<List<Task>> searchTasks(String query);

  /// Watch all tasks for changes
  Stream<List<Task>> watchAllTasks();
}
