import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class GetAllWorkspacesUseCase {
  final WorkspaceRepository _repository;

  GetAllWorkspacesUseCase(this._repository);

  Future<List<Workspace>> call() async {
    try {
      return await _repository.getAllWorkspaces();
    } catch (e) {
      throw Exception('Failed to get all workspaces: $e');
    }
  }
}
