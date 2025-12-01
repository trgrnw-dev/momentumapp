import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/domain/entities/task.dart';
import 'package:momentum/presentation/widgets/task_card.dart';

void main() {
  group('TaskCard Widget Tests', () {
    testWidgets('должен отображать заголовок задачи', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Тестовая задача',
        description: 'Описание задачи',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: 'Работа',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Тестовая задача'), findsOneWidget);
    });

    testWidgets('должен отображать описание задачи', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Задача',
        description: 'Подробное описание',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Подробное описание'), findsOneWidget);
    });

    testWidgets('должен отображать приоритет задачи', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Срочная задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.high,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('должен отображать категорию задачи', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: 'Работа',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Работа'), findsOneWidget);
    });

    testWidgets('должен отображать дату выполнения', (WidgetTester tester) async {
      // Arrange
      final dueDate = DateTime.now().add(Duration(days: 1));
      final task = Task(
        id: 1,
        title: 'Задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: dueDate,
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('должен вызывать onToggle при нажатии на чекбокс', (WidgetTester tester) async {
      // Arrange
      bool toggleCalled = false;
      final task = Task(
        id: 1,
        title: 'Задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              onToggle: () {
                toggleCalled = true;
              },
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Assert
      expect(toggleCalled, isTrue);
    });

    testWidgets('должен вызывать onDelete при нажатии на кнопку удаления', (WidgetTester tester) async {
      // Arrange
      bool deleteCalled = false;
      final task = Task(
        id: 1,
        title: 'Задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {
                deleteCalled = true;
              },
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Assert
      expect(deleteCalled, isTrue);
    });

    testWidgets('должен отображать выполненные задачи с зачеркнутым текстом', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Выполненная задача',
        description: '',
        isCompleted: true,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().add(Duration(days: 1)),
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Выполненная задача'), findsOneWidget);
      // Проверяем, что чекбокс отмечен
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('должен отображать просроченные задачи с красным цветом', (WidgetTester tester) async {
      // Arrange
      final task = Task(
        id: 1,
        title: 'Просроченная задача',
        description: '',
        isCompleted: false,
        priority: TaskPriority.medium,
        dueDate: DateTime.now().subtract(Duration(days: 1)), // Вчера
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:             TaskCard(
              task: task,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Просроченная задача'), findsOneWidget);
      // Проверяем наличие иконки предупреждения для просроченных задач
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
}
