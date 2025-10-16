class Project {
  final String id;
  final String name;
  final String description;
  final String createdBy; // User ID of the project creator/owner
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'members': memberIds, // Appwrite relationship field
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle Appwrite relationship field - can be array of IDs or full documents
    List<String> parseMemberIds(dynamic membersField) {
      if (membersField == null) return [];
      if (membersField is List) {
        return membersField.map((e) {
          // If it's a full document, extract the ID
          if (e is Map<String, dynamic>) {
            return (e['id'] ?? e['\$id']).toString();
          }
          // Otherwise it's just an ID string
          return e.toString();
        }).toList();
      }
      return [];
    }

    return Project(
      id: (json['id'] ?? json['\$id']) as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      memberIds: parseMemberIds(json['members']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
