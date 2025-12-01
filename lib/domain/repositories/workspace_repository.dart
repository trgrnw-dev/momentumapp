import '../entities/workspace.dart';

/// Workspace Repository Interface
/// Defines the contract for workspace data operations
abstract class WorkspaceRepository {
  /// Get all workspaces
  Future<List<Workspace>> getAllWorkspaces();

  /// Get workspace by ID
  Future<Workspace?> getWorkspaceById(int id);

  /// Create a new workspace
  Future<Workspace> createWorkspace(Workspace workspace);

  /// Update an existing workspace
  Future<Workspace> updateWorkspace(Workspace workspace);

  /// Delete a workspace
  Future<void> deleteWorkspace(int id);

  /// Get workspace by order
  Future<Workspace?> getWorkspaceByOrder(int order);

  /// Update workspace order
  Future<void> updateWorkspaceOrder(int workspaceId, int newOrder);

  /// Update workspace task counts
  Future<void> updateWorkspaceTaskCounts(int workspaceId, int totalTasks, int completedTasks);

  /// Get workspace statistics
  Future<Map<String, int>> getWorkspaceStatistics();

  /// Watch all workspaces for changes
  Stream<List<Workspace>> watchAllWorkspaces();
}
