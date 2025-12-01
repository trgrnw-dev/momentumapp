import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetAllTasksUseCase {
  final TaskRepository repository;

  GetAllTasksUseCase(this.repository);

  Future<List<Task>> call() async {
    return await repository.getAllTasks();
  }
}
