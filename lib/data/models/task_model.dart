import '../../domain/entities/task.dart';

/// Модель задачи для SQLite базы данных
/// Это представление задачи на уровне данных
class TaskModel {
  int id;

  String title;

  String? description;

  DateTime dueDate;

  bool isCompleted;

  TaskPriority priority;

  DateTime createdAt;

  String? category;

  int? workspaceId;

  double? progress;

  int? estimatedHours;

  String? tagIds; // JSON строка для SQLite

  /// Конструктор по умолчанию
  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    this.category,
    this.workspaceId,
    this.progress,
    this.estimatedHours,
    this.tagIds,
  });

  /// Конструктор из доменной сущности
  TaskModel.fromEntity(Task task) 
    : id = task.id,
      title = task.title,
      description = task.description,
      dueDate = task.dueDate,
      isCompleted = task.isCompleted,
      priority = task.priority,
      createdAt = task.createdAt,
      category = task.category,
      workspaceId = task.workspaceId,
      progress = task.progress,
      estimatedHours = task.estimatedHours,
      tagIds = task.tagIds?.join(',');

  /// Обновить существующую модель новыми данными
  void updateFromEntity(Task task) {
    title = task.title;
    description = task.description;
    dueDate = task.dueDate;
    isCompleted = task.isCompleted;
    priority = task.priority;
    category = task.category;
    workspaceId = task.workspaceId;
    progress = task.progress;
    estimatedHours = task.estimatedHours;
    tagIds = task.tagIds?.join(',');
  }

  /// Преобразовать модель в доменную сущность
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted,
      updatedAt: createdAt,
      priority: priority,
      createdAt: createdAt,
      category: category,
      workspaceId: workspaceId,
      progress: progress,
      estimatedHours: estimatedHours,
      tagIds: tagIds?.split(',').map(int.parse).toList(),
    );
  }

  /// Создать новую модель задачи для вставки
  factory TaskModel.create({
    required String title,
    String? description,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? category,
    int? workspaceId,
    double? progress,
    int? estimatedHours,
    List<int>? tagIds,
  }) {
    return TaskModel(
      id: 0, // Будет установлено базой данных
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      priority: priority,
      createdAt: DateTime.now(),
      category: category,
      workspaceId: workspaceId,
      progress: progress,
      estimatedHours: estimatedHours,
      tagIds: tagIds?.join(','),
    );
  }

  /// Метод копирования для обновлений
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? createdAt,
    String? category,
    int? workspaceId,
    double? progress,
    int? estimatedHours,
    List<int>? tagIds,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      workspaceId: workspaceId ?? this.workspaceId,
      progress: progress ?? this.progress,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      tagIds: tagIds != null ? tagIds.join(',') : this.tagIds,
    );
  }

  /// Преобразовать в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'category': category,
      'workspaceId': workspaceId,
      'progress': progress,
      'estimatedHours': estimatedHours,
      'tagIds': tagIds,
    };
  }

  /// Создать из Map (результат SQLite)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      isCompleted: (map['isCompleted'] as int) == 1,
      priority: TaskPriority.values[map['priority'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      category: map['category'] as String?,
      workspaceId: map['workspaceId'] as int?,
      progress: map['progress'] as double?,
      estimatedHours: map['estimatedHours'] as int?,
      tagIds: map['tagIds'] as String?,
    );
  }
}
