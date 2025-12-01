import '../../domain/entities/tag.dart';

/// Tag Model for SQLite Database
class TagModel {
  int id;

  String name;

  String colorHex;

  DateTime createdAt;

  int usageCount;

  /// Default constructor
  TagModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
    required this.usageCount,
  });

  /// Constructor from domain entity
  TagModel.fromEntity(Tag tag) 
    : id = tag.id,
      name = tag.name,
      colorHex = tag.colorHex,
      createdAt = tag.createdAt,
      usageCount = tag.usageCount;


  /// Convert model to domain entity
  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: createdAt,
      usageCount: usageCount,
    );
  }

  /// Create a new tag model for insertion
  factory TagModel.create({
    required String name,
    required String colorHex,
  }) {
    return TagModel(
      id: 0, // Will be set by database
      name: name,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      usageCount: 0,
    );
  }

  /// Copy with method for updates
  TagModel copyWith({
    int? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'usageCount': usageCount,
    };
  }

  /// Create from Map (SQLite result)
  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as int,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      usageCount: map['usageCount'] as int,
    );
  }
}
