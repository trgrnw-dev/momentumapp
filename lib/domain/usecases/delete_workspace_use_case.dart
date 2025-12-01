import '../repositories/workspace_repository.dart';
import '../repositories/task_repository.dart';

class DeleteWorkspaceUseCase {
  final WorkspaceRepository _workspaceRepository;
  final TaskRepository _taskRepository;

  DeleteWorkspaceUseCase(this._workspaceRepository, this._taskRepository);

  Future<void> call(int workspaceId) async {
    try {
      final workspace = await _workspaceRepository.getWorkspaceById(workspaceId);
      if (workspace == null) {
        throw Exception('Workspace not found');
      }

      final tasks = await _taskRepository.getTasksByWorkspaceId(workspaceId);
      for (final task in tasks) {
        await _taskRepository.deleteTask(task.id);
      }
      await _workspaceRepository.deleteWorkspace(workspaceId);
    } catch (e) {
      throw Exception('Failed to delete workspace: $e');
    }
  }
}
