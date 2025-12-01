import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasksByWorkspaceIdUseCase {
  final TaskRepository repository;

  GetTasksByWorkspaceIdUseCase(this.repository);

  Future<List<Task>> call(int workspaceId) async {
    return await repository.getTasksByWorkspaceId(workspaceId);
  }
}
