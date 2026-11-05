import '../utils/copy_with.dart';

class Board {
  final String id;
  final String name;
  final String? description;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Board({
    required this.id,
    required this.name,
    this.description,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'archived': archived,
      '\$createdAt': createdAt.toUtc().toIso8601String(),
      '\$updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: (json['id'] ?? json['\$id']) as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      archived: json['archived'] as bool? ?? false,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Board copyWith({
    String? id,
    String? name,
    Object? description = unset,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      description: identical(description, unset)
          ? this.description
          : description as String?,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
