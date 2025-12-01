import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class CreateWorkspaceUseCase {
  final WorkspaceRepository _repository;

  CreateWorkspaceUseCase(this._repository);

  Future<Workspace> call(Workspace workspace) async {
    try {
      if (workspace.name.trim().isEmpty) {
        throw Exception('Workspace name cannot be empty');
      }
      
      if (workspace.name.trim().length < 2) {
        throw Exception('Workspace name must be at least 2 characters');
      }

      final now = DateTime.now();
      final workspaces = await _repository.getAllWorkspaces();
      final nextOrder = workspaces.isNotEmpty ? workspaces.length : 0;
      
      final newWorkspace = workspace.copyWith(
        createdAt: now,
        order: nextOrder,
      );

      return await _repository.createWorkspace(newWorkspace);
    } catch (e) {
      throw Exception('Failed to create workspace: $e');
    }
  }
}
