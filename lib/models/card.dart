import 'priority.dart';

class Card {
  final String id;
  final String columnId;
  final String title;
  final String? description;
  final int position;
  final List<String> assigneeIds;
  final List<String> labelIds;
  final Priority priority;
  final DateTime? dueDate;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  Card({
    required this.id,
    required this.columnId,
    required this.title,
    this.description,
    required this.position,
    required this.assigneeIds,
    required this.labelIds,
    required this.priority,
    this.dueDate,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'columnId': columnId,
      'title': title,
      'description': description,
      'position': position,
      'assigneeIds': assigneeIds,
      'labelIds': labelIds,
      'priority': priority.toJson(),
      'dueDate': dueDate?.toIso8601String(),
      'commentCount': commentCount,
      'createdBy': createdBy,
    };
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: (json['id'] ?? json['\$id']) as String,
      columnId: json['columnId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      position: json['position'] as int? ?? 0,
      assigneeIds:
          (json['assigneeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      labelIds:
          (json['labelIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priority: json['priority'] != null
          ? Priority.fromJson(json['priority'] as String)
          : Priority.low,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      commentCount: json['commentCount'] as int? ?? 0,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : DateTime.now(),
      createdBy: json['createdBy'] as String,
    );
  }

  Card copyWith({
    String? id,
    String? columnId,
    String? title,
    String? description,
    int? position,
    List<String>? assigneeIds,
    List<String>? labelIds,
    Priority? priority,
    DateTime? dueDate,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Card(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      labelIds: labelIds ?? this.labelIds,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
