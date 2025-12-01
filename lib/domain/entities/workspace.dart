/// Workspace Entity
/// Represents a workspace in the domain layer
class Workspace {
  /// Unique identifier
  final int id;

  /// Workspace name
  final String name;

  /// Optional description
  final String? description;

  /// Icon name for the workspace
  final String iconName;

  /// Color hex code for the workspace
  final String colorHex;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Order for sorting workspaces
  final int order;

  /// Total number of tasks in this workspace
  final int totalTasks;

  /// Number of completed tasks in this workspace
  final int completedTasks;

  /// Default constructor
  const Workspace({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    required this.order,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  /// Copy with method
  Workspace copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? order,
    int? totalTasks,
    int? completedTasks,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'order': order,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
    };
  }

  /// Create from JSON
  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['iconName'] as String,
      colorHex: json['colorHex'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      order: json['order'] as int,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'Workspace(id: $id, name: $name, iconName: $iconName, colorHex: $colorHex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workspace &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.iconName == iconName &&
        other.colorHex == colorHex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.order == order &&
        other.totalTasks == totalTasks &&
        other.completedTasks == completedTasks;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      iconName,
      colorHex,
      createdAt,
      updatedAt,
      order,
      totalTasks,
      completedTasks,
    );
  }
}
