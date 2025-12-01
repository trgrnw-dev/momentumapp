import 'package:equatable/equatable.dart';

/// Task entity - core business model
/// Represents a task in the domain layer
class Task extends Equatable {
  final int id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final int? workspaceId;
  final double? progress;
  final int? estimatedHours;
  final List<int>? tagIds;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.workspaceId,
    this.progress,
    this.estimatedHours,
    this.tagIds,
  });

  /// Create a copy of task with updated fields
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    int? workspaceId,
    double? progress,
    int? estimatedHours,
    List<int>? tagIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      workspaceId: workspaceId ?? this.workspaceId,
      progress: progress ?? this.progress,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      tagIds: tagIds ?? this.tagIds,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    dueDate,
    isCompleted,
    priority,
    createdAt,
    updatedAt,
    category,
    workspaceId,
    progress,
    estimatedHours,
    tagIds,
  ];
}

/// Task priority levels
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}

