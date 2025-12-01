import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class UpdateWorkspaceUseCase {
  final WorkspaceRepository _repository;

  UpdateWorkspaceUseCase(this._repository);

  Future<Workspace> call(Workspace workspace) async {
    try {
      if (workspace.name.trim().isEmpty) {
        throw Exception('Workspace name cannot be empty');
      }
      
      if (workspace.name.trim().length < 2) {
        throw Exception('Workspace name must be at least 2 characters');
      }

      return await _repository.updateWorkspace(workspace);
    } catch (e) {
      throw Exception('Failed to update workspace: $e');
    }
  }
}
