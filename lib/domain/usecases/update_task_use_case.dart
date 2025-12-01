import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository repository;

  UpdateTaskUseCase(this.repository);

  Future<void> call(Task task) async {
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    if (task.dueDate.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      throw ArgumentError('Task due date cannot be in the past');
    }

    await repository.updateTask(task);
  }
}
