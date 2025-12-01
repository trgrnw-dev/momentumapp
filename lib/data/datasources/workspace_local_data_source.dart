import 'package:sqflite/sqflite.dart';
import '../models/workspace_model.dart';

/// Workspace Local Data Source
/// Handles local database operations for workspaces using SQLite
class WorkspaceLocalDataSource {
  final Database _database;

  WorkspaceLocalDataSource(this._database);

  /// Get all workspaces ordered by order field
  Future<List<WorkspaceModel>> getAllWorkspaces() async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'workspaces',
        orderBy: '`order` ASC',
      );
      return List.generate(maps.length, (i) => WorkspaceModel.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all workspaces: $e');
    }
  }

  /// Get workspace by ID
  Future<WorkspaceModel?> getWorkspaceById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'workspaces',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return WorkspaceModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get workspace by ID: $e');
    }
  }

  /// Create a new workspace
  Future<WorkspaceModel> createWorkspace(WorkspaceModel workspace) async {
    try {
      final workspaceMap = workspace.toMap();
      workspaceMap.remove('id'); // Remove id for auto-increment
      final id = await _database.insert('workspaces', workspaceMap);
      return workspace.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create workspace: $e');
    }
  }

  /// Update an existing workspace
  Future<WorkspaceModel> updateWorkspace(WorkspaceModel workspace) async {
    try {
      await _database.update(
        'workspaces',
        workspace.toMap(),
        where: 'id = ?',
        whereArgs: [workspace.id],
      );
      return workspace;
    } catch (e) {
      throw Exception('Failed to update workspace: $e');
    }
  }

  /// Delete a workspace
  Future<void> deleteWorkspace(int id) async {
    try {
      await _database.delete(
        'workspaces',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete workspace: $e');
    }
  }

  /// Get workspace by order
  Future<WorkspaceModel?> getWorkspaceByOrder(int order) async {
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        'workspaces',
        where: '`order` = ?',
        whereArgs: [order],
      );
      if (maps.isNotEmpty) {
        return WorkspaceModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get workspace by order: $e');
    }
  }

  /// Update workspace order
  Future<void> updateWorkspaceOrder(int workspaceId, int newOrder) async {
    try {
      await _database.update(
        'workspaces',
        {'`order`': newOrder},
        where: 'id = ?',
        whereArgs: [workspaceId],
      );
    } catch (e) {
      throw Exception('Failed to update workspace order: $e');
    }
  }

  /// Update workspace task counts
  Future<void> updateWorkspaceTaskCounts(int workspaceId, int totalTasks, int completedTasks) async {
    try {
      await _database.update(
        'workspaces',
        {
          'totalTasks': totalTasks,
          'completedTasks': completedTasks,
        },
        where: 'id = ?',
        whereArgs: [workspaceId],
      );
    } catch (e) {
      throw Exception('Failed to update workspace task counts: $e');
    }
  }

  /// Get workspace statistics
  Future<Map<String, int>> getWorkspaceStatistics() async {
    try {
      final workspaces = await getAllWorkspaces();
      int totalWorkspaces = workspaces.length;
      int totalTasks = workspaces.fold(0, (sum, workspace) => sum + workspace.totalTasks);
      int completedTasks = workspaces.fold(0, (sum, workspace) => sum + workspace.completedTasks);
      
      return {
        'totalWorkspaces': totalWorkspaces,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
      };
    } catch (e) {
      throw Exception('Failed to get workspace statistics: $e');
    }
  }

  /// Watch all workspaces for changes (SQLite doesn't have built-in streams)
  Stream<List<WorkspaceModel>> watchAllWorkspaces() async* {
    while (true) {
      yield await getAllWorkspaces();
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
