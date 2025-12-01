import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';
import 'task_event.dart';

/// Base class for all Task states
abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any tasks are loaded
class TaskInitial extends TaskState {
  const TaskInitial();
}

/// State when tasks are being loaded
class TaskLoading extends TaskState {
  const TaskLoading();
}

/// State when tasks are successfully loaded
class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final TaskFilter? currentFilter;
  final String? searchQuery;

  const TaskLoaded({required this.tasks, this.currentFilter, this.searchQuery});

  @override
  List<Object?> get props => [tasks, currentFilter, searchQuery];

  /// Check if there are no tasks
  bool get isEmpty => tasks.isEmpty;

  /// Get completed tasks count
  int get completedCount => tasks.where((task) => task.isCompleted).length;

  /// Get pending tasks count
  int get pendingCount => tasks.where((task) => !task.isCompleted).length;

  /// Get tasks count by priority
  int getCountByPriority(TaskPriority priority) {
    return tasks.where((task) => task.priority == priority).length;
  }

  /// Copy with method for easy state updates
  TaskLoaded copyWith({
    List<Task>? tasks,
    TaskFilter? currentFilter,
    String? searchQuery,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State when there's an error loading or managing tasks
class TaskError extends TaskState {
  final String message;
  final String? errorDetails;

  const TaskError({required this.message, this.errorDetails});

  @override
  List<Object?> get props => [message, errorDetails];
}

/// State when a task operation is in progress (create, update, delete)
class TaskOperationInProgress extends TaskState {
  final String operation;

  const TaskOperationInProgress(this.operation);

  @override
  List<Object?> get props => [operation];
}

/// State when a task operation is successful
class TaskOperationSuccess extends TaskState {
  final String message;
  final List<Task> tasks;

  const TaskOperationSuccess({required this.message, required this.tasks});

  @override
  List<Object?> get props => [message, tasks];
}

/// State when tasks list is empty
class TaskEmpty extends TaskState {
  final String message;

  const TaskEmpty({this.message = 'No tasks yet. Create your first task!'});

  @override
  List<Object?> get props => [message];
}
