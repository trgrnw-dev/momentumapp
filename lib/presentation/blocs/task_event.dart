import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

/// Base class for all Task events
abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all tasks
class LoadTasksEvent extends TaskEvent {
  const LoadTasksEvent();
}

/// Event to load tasks by workspace ID
class LoadTasksByWorkspaceEvent extends TaskEvent {
  final int workspaceId;

  const LoadTasksByWorkspaceEvent(this.workspaceId);

  @override
  List<Object?> get props => [workspaceId];
}

/// Event to load tasks by specific filter
class LoadFilteredTasksEvent extends TaskEvent {
  final TaskFilter filter;
  final int? workspaceId;

  const LoadFilteredTasksEvent(this.filter, {this.workspaceId});

  @override
  List<Object?> get props => [filter, workspaceId];
}

/// Event to create a new task
class CreateTaskEvent extends TaskEvent {
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskPriority priority;
  final String? category;
  final int? workspaceId;
  final List<int>? tagIds;

  const CreateTaskEvent({
    required this.title,
    this.description,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.category,
    this.workspaceId,
    this.tagIds,
  });

  @override
  List<Object?> get props => [title, description, dueDate, priority, category, workspaceId, tagIds];
}

/// Event to update an existing task
class UpdateTaskEvent extends TaskEvent {
  final Task task;

  const UpdateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

/// Event to delete a task
class DeleteTaskEvent extends TaskEvent {
  final int taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Event to toggle task completion status
class ToggleTaskCompletionEvent extends TaskEvent {
  final int taskId;

  const ToggleTaskCompletionEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Event to delete all completed tasks
class DeleteCompletedTasksEvent extends TaskEvent {
  const DeleteCompletedTasksEvent();
}

/// Event to search tasks
class SearchTasksEvent extends TaskEvent {
  final String query;

  const SearchTasksEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Event to filter tasks by priority
class FilterTasksByPriorityEvent extends TaskEvent {
  final TaskPriority priority;

  const FilterTasksByPriorityEvent(this.priority);

  @override
  List<Object?> get props => [priority];
}

/// Event to filter tasks by category
class FilterTasksByCategoryEvent extends TaskEvent {
  final String category;

  const FilterTasksByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to filter tasks by date range
class FilterTasksByDateRangeEvent extends TaskEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FilterTasksByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to load today's tasks
class LoadTodayTasksEvent extends TaskEvent {
  const LoadTodayTasksEvent();
}

/// Event to load overdue tasks
class LoadOverdueTasksEvent extends TaskEvent {
  const LoadOverdueTasksEvent();
}

/// Event to load completed tasks
class LoadCompletedTasksEvent extends TaskEvent {
  const LoadCompletedTasksEvent();
}

/// Event to load pending tasks
class LoadPendingTasksEvent extends TaskEvent {
  const LoadPendingTasksEvent();
}

/// Task filter types
enum TaskFilter { all }
