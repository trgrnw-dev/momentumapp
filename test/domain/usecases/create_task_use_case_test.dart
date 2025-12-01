import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:momentum/domain/entities/task.dart';
import 'package:momentum/domain/repositories/task_repository.dart';
import 'package:momentum/domain/usecases/create_task_use_case.dart';

// Генерируем моки
@GenerateMocks([TaskRepository])
import 'create_task_use_case_test.mocks.dart';

void main() {
  group('CreateTaskUseCase', () {
    late CreateTaskUseCase useCase;
    late MockTaskRepository mockRepository;

    setUp(() {
      mockRepository = MockTaskRepository();
      useCase = CreateTaskUseCase(mockRepository);
    });

    test('должен успешно создать задачу с минимальными данными', () async {
      // Arrange
      final task = Task(
        id: 0, // ID будет установлен репозиторием
        title: 'Новая задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createTask(any))
          .thenAnswer((_) async {});

      // Act
      await useCase.call(task);

      // Assert
      verify(mockRepository.createTask(task)).called(1);
    });

    test('должен успешно создать задачу с полными данными', () async {
      // Arrange
      final task = Task(
        id: 0,
        title: 'Важная задача',
        description: 'Подробное описание задачи',
        isCompleted: false,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: 'Работа',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createTask(any))
          .thenAnswer((_) async {});

      // Act
      await useCase.call(task);

      // Assert
      verify(mockRepository.createTask(task)).called(1);
    });

    test('должен пробрасывать исключение при ошибке создания', () async {
      // Arrange
      final task = Task(
        id: 0,
        title: 'Задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createTask(any))
          .thenThrow(Exception('Ошибка создания задачи'));

      // Act & Assert
      expect(() => useCase.call(task), throwsException);
      verify(mockRepository.createTask(task)).called(1);
    });

    test('должен создать задачу с высоким приоритетом', () async {
      // Arrange
      final task = Task(
        id: 0,
        title: 'Срочная задача',
        description: 'Очень важная задача',
        isCompleted: false,
        priority: TaskPriority.urgent,
        dueDate: DateTime.now().add(Duration(hours: 2)),
        category: 'Срочно',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createTask(any))
          .thenAnswer((_) async {});

      // Act
      await useCase.call(task);

      // Assert
      verify(mockRepository.createTask(task)).called(1);
      expect(task.priority, equals(TaskPriority.urgent));
    });
  });
}
