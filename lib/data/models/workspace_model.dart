/// WorkspaceModel - Data model for workspace entity
/// Represents a workspace in the SQLite database
class WorkspaceModel {
  int id;

  String name;

  String? description;

  String iconName;

  String colorHex;


  DateTime createdAt;


  int order;

  int totalTasks;

  int completedTasks;

  WorkspaceModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.colorHex,
    required this.createdAt,
    required this.order,
    this.totalTasks = 0,
    this.completedTasks = 0,
  });

  WorkspaceModel.create({
    required this.name,
    this.description,
    required this.iconName,
    required this.colorHex,
    required this.order,
    this.totalTasks = 0,
    this.completedTasks = 0,
  }) : id = 0,
       createdAt = DateTime.now();

  /// Copy with method
  WorkspaceModel copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    String? colorHex,
    DateTime? createdAt,
    int? order,
    int? totalTasks,
    int? completedTasks,
  }) {
    return WorkspaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
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
      'order': order,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
    };
  }

  /// Create from JSON
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconName: json['iconName'] as String,
      colorHex: json['colorHex'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      order: json['order'] as int,
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
    );
  }

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'colorHex': colorHex,
      'createdAt': createdAt.millisecondsSinceEpoch,
      '`order`': order,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
    };
  }

  /// Create from Map (SQLite result)
  factory WorkspaceModel.fromMap(Map<String, dynamic> map) {
    return WorkspaceModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['iconName'] as String,
      colorHex: map['colorHex'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      order: (map['`order`'] as int?) ?? 0, // Handle null values
      totalTasks: map['totalTasks'] as int,
      completedTasks: map['completedTasks'] as int,
    );
  }

  @override
  String toString() {
    return 'WorkspaceModel(id: $id, name: $name, iconName: $iconName, colorHex: $colorHex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkspaceModel &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.iconName == iconName &&
        other.colorHex == colorHex &&
        other.createdAt == createdAt &&
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
      order,
      totalTasks,
      completedTasks,
    );
  }
}
