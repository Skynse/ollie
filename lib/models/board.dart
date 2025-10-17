class Board {
  final String id;
  final String name;
  final String? description;
  final String createdBy; // User ID of the board creator/owner
  final List<String> memberIds; // Users who have access to this board
  final List<String> columnIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Board({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.memberIds,
    required this.columnIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'members': memberIds, // String array in Appwrite
      'columnIds': columnIds,
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    // Handle members field - can be array of IDs or array of objects
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

    return Board(
      id: (json['id'] ?? json['\$id']) as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
      memberIds: parseMemberIds(json['members']),
      columnIds:
          (json['columnIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
    String? description,
    String? createdBy,
    List<String>? memberIds,
    List<String>? columnIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      columnIds: columnIds ?? this.columnIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
