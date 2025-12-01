import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tag entity - represents a tag for categorizing tasks
class Tag extends Equatable {
  final int id;
  final String name;
  final String colorHex;
  final DateTime createdAt;
  final int usageCount;

  const Tag({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
    this.usageCount = 0,
  });

  /// Create a copy of tag with updated fields
  Tag copyWith({
    int? id,
    String? name,
    String? colorHex,
    DateTime? createdAt,
    int? usageCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [id, name, colorHex, createdAt, usageCount];

  Color get color => _parseColor(colorHex);

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF137FEC); // Default color
    }
  }

  static const List<String> predefinedColors = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#98D8C8', // Mint
    '#F7DC6F', // Gold
    '#BB8FCE', // Lavender
    '#85C1E9', // Sky Blue
    '#F8C471', // Orange
    '#82E0AA', // Light Green
  ];
}
