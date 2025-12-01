import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:momentum/domain/entities/task.dart';
import 'package:momentum/domain/repositories/task_repository.dart';
import 'package:momentum/domain/usecases/get_all_tasks_use_case.dart';

// Генерируем моки
@GenerateMocks([TaskRepository])
import 'get_all_tasks_use_case_test.mocks.dart';

void main() {
  group('GetAllTasksUseCase', () {
    late GetAllTasksUseCase useCase;
    late MockTaskRepository mockRepository;

    setUp(() {
      mockRepository = MockTaskRepository();
      useCase = GetAllTasksUseCase(mockRepository);
    });

    test('должен возвращать список задач при успешном получении', () async {
      // Arrange
      final tasks = [
        Task(
          id: 1,
          title: 'Тестовая задача 1',
          description: 'Описание задачи 1',
          isCompleted: false,
          priority: TaskPriority.medium,
          dueDate: DateTime.now().add(Duration(days: 1)),
          category: 'Работа',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Task(
          id: 2,
          title: 'Тестовая задача 2',
          description: 'Описание задачи 2',
          isCompleted: true,
          priority: TaskPriority.high,
          dueDate: DateTime.now().add(Duration(days: 2)),
          category: 'Личное',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getAllTasks())
          .thenAnswer((_) async => tasks);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, equals(tasks));
      verify(mockRepository.getAllTasks()).called(1);
    });

    test('должен возвращать пустой список когда задач нет', () async {
      // Arrange
      when(mockRepository.getAllTasks())
          .thenAnswer((_) async => <Task>[]);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result, isEmpty);
      verify(mockRepository.getAllTasks()).called(1);
    });

    test('должен пробрасывать исключение при ошибке репозитория', () async {
      // Arrange
      when(mockRepository.getAllTasks())
          .thenThrow(Exception('Ошибка базы данных'));

      // Act & Assert
      expect(() => useCase.call(), throwsException);
      verify(mockRepository.getAllTasks()).called(1);
    });
  });
}
