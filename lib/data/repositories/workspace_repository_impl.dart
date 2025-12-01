import '../../domain/entities/workspace.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_local_data_source.dart';
import '../models/workspace_model.dart';

/// Workspace Repository Implementation
/// Implements the workspace repository interface using local data source
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceLocalDataSource _localDataSource;

  WorkspaceRepositoryImpl({required WorkspaceLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<List<Workspace>> getAllWorkspaces() async {
    try {
      final models = await _localDataSource.getAllWorkspaces();
      return models.map((model) => _modelToEntity(model)).toList();
    } catch (e) {
      throw Exception('Failed to get all workspaces: $e');
    }
  }

  @override
  Future<Workspace?> getWorkspaceById(int id) async {
    try {
      final model = await _localDataSource.getWorkspaceById(id);
      return model != null ? _modelToEntity(model) : null;
    } catch (e) {
      throw Exception('Failed to get workspace by ID: $e');
    }
  }

  @override
  Future<Workspace> createWorkspace(Workspace workspace) async {
    try {
      final model = _entityToModel(workspace);
      final createdModel = await _localDataSource.createWorkspace(model);
      return _modelToEntity(createdModel);
    } catch (e) {
      throw Exception('Failed to create workspace: $e');
    }
  }

  @override
  Future<Workspace> updateWorkspace(Workspace workspace) async {
    try {
      final model = _entityToModel(workspace);
      final updatedModel = await _localDataSource.updateWorkspace(model);
      return _modelToEntity(updatedModel);
    } catch (e) {
      throw Exception('Failed to update workspace: $e');
    }
  }

  @override
  Future<void> deleteWorkspace(int id) async {
    try {
      await _localDataSource.deleteWorkspace(id);
    } catch (e) {
      throw Exception('Failed to delete workspace: $e');
    }
  }

  @override
  Future<Workspace?> getWorkspaceByOrder(int order) async {
    try {
      final model = await _localDataSource.getWorkspaceByOrder(order);
      return model != null ? _modelToEntity(model) : null;
    } catch (e) {
      throw Exception('Failed to get workspace by order: $e');
    }
  }

  @override
  Future<void> updateWorkspaceOrder(int workspaceId, int newOrder) async {
    try {
      await _localDataSource.updateWorkspaceOrder(workspaceId, newOrder);
    } catch (e) {
      throw Exception('Failed to update workspace order: $e');
    }
  }

  @override
  Future<void> updateWorkspaceTaskCounts(int workspaceId, int totalTasks, int completedTasks) async {
    try {
      final model = await _localDataSource.getWorkspaceById(workspaceId);
      if (model != null) {
        model.totalTasks = totalTasks;
        model.completedTasks = completedTasks;
        await _localDataSource.updateWorkspace(model);
      }
    } catch (e) {
      throw Exception('Failed to update workspace task counts: $e');
    }
  }

  @override
  Future<Map<String, int>> getWorkspaceStatistics() async {
    try {
      return await _localDataSource.getWorkspaceStatistics();
    } catch (e) {
      throw Exception('Failed to get workspace statistics: $e');
    }
  }

  @override
  Stream<List<Workspace>> watchAllWorkspaces() {
    return _localDataSource.watchAllWorkspaces().map((workspaceModels) => 
      workspaceModels.map((model) => _modelToEntity(model)).toList()
    );
  }

  /// Convert WorkspaceModel to Workspace entity
  Workspace _modelToEntity(WorkspaceModel model) {
    return Workspace(
      id: model.id,
      name: model.name,
      description: model.description,
      iconName: model.iconName,
      colorHex: model.colorHex,
      createdAt: model.createdAt,
      updatedAt: model.createdAt,
      order: model.order,
      totalTasks: model.totalTasks,
      completedTasks: model.completedTasks,
    );
  }

  /// Convert Workspace entity to WorkspaceModel
  WorkspaceModel _entityToModel(Workspace workspace) {
    final model = WorkspaceModel.create(
      name: workspace.name,
      description: workspace.description,
      iconName: workspace.iconName,
      colorHex: workspace.colorHex,
      order: workspace.order,
    );
    
    // Only set ID if it's not 0 (auto-increment)
    if (workspace.id != 0) {
      model.id = workspace.id;
    }
    
    model.createdAt = workspace.createdAt;
    model.totalTasks = workspace.totalTasks;
    model.completedTasks = workspace.completedTasks;
    
    return model;
  }
}
