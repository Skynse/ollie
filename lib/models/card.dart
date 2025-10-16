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
      'id': id,
      'column_id': columnId,
      'title': title,
      'description': description,
      'position': position,
      'assignee_ids': assigneeIds,
      'label_ids': labelIds,
      'priority': priority.toJson(),
      'due_date': dueDate?.toIso8601String(),
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: (json['id'] ?? json['\$id']) as String,
      columnId: json['column_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      position: json['position'] as int? ?? 0,
      assigneeIds:
          (json['assignee_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      labelIds:
          (json['label_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priority: json['priority'] != null
          ? Priority.fromJson(json['priority'] as String)
          : Priority.low,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      commentCount: json['comment_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      createdBy: json['created_by'] as String,
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
