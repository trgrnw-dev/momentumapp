import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../../domain/entities/task.dart';

/// Local Data Source for Task operations using SQLite
/// Handles all direct database interactions
class TaskLocalDataSource {
  final Database database;

  TaskLocalDataSource(this.database);

  /// Get all tasks from the database
  Future<List<TaskModel>> getAllTasks() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      orderBy: 'dueDate DESC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get task by ID
  Future<TaskModel?> getTaskById(int id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    }
    return null;
  }

  /// Get tasks by date range
  Future<List<TaskModel>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'dueDate BETWEEN ? AND ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get completed tasks
  Future<List<TaskModel>> getCompletedTasks() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [1],
      orderBy: 'dueDate DESC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get pending (not completed) tasks
  Future<List<TaskModel>> getPendingTasks() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [0],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get tasks by priority
  Future<List<TaskModel>> getTasksByPriority(TaskPriority priority) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'priority = ?',
      whereArgs: [priority.index],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get tasks by category
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get tasks by workspace ID
  Future<List<TaskModel>> getTasksByWorkspaceId(int workspaceId) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'workspaceId = ?',
      whereArgs: [workspaceId],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }


  /// Create a new task
  Future<int> createTask(TaskModel task) async {
    final taskMap = task.toMap();
    taskMap.remove('id'); // Remove id for auto-increment
    return await database.insert('tasks', taskMap);
  }

  /// Update an existing task
  Future<void> updateTask(TaskModel task) async {
    await database.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Delete a task by ID
  Future<bool> deleteTask(int id) async {
    final result = await database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(int id) async {
    await database.rawUpdate(
      'UPDATE tasks SET isCompleted = NOT isCompleted WHERE id = ?',
      [id],
    );
  }

  /// Delete all completed tasks
  Future<int> deleteCompletedTasks() async {
    return await database.delete(
      'tasks',
      where: 'isCompleted = ?',
      whereArgs: [1],
    );
  }

  /// Get total tasks count
  Future<int> getTasksCount() async {
    final result = await database.rawQuery('SELECT COUNT(*) as count FROM tasks');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search tasks by title or description
  Future<List<TaskModel>> searchTasks(String query) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Get tasks for today
  Future<List<TaskModel>> getTasksForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await getTasksByDateRange(startOfDay, endOfDay);
  }

  /// Get overdue tasks
  Future<List<TaskModel>> getOverdueTasks() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      where: 'dueDate < ? AND isCompleted = ?',
      whereArgs: [now.millisecondsSinceEpoch, 0],
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  /// Delete all tasks (use with caution!)
  Future<void> deleteAllTasks() async {
    await database.delete('tasks');
  }

  /// Watch all tasks for changes (SQLite doesn't have built-in streams)
  /// This would need to be implemented with periodic polling or using a stream controller
  Stream<List<TaskModel>> watchAllTasks() async* {
    while (true) {
      yield await getAllTasks();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
