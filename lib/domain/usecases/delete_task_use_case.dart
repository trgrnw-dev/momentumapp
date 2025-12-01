import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;

  DeleteTaskUseCase(this.repository);

  Future<void> call(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid task ID');
    }

    await repository.deleteTask(id);
  }
}
