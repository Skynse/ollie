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
  final double? estimatedHours;
  final double
  totalLoggedHours; // Total hours logged (denormalized for performance)
  final String? sprintId;
  final String rank;

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
    this.estimatedHours,
    this.totalLoggedHours = 0.0,
    this.sprintId,
    required this.rank,
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
      'estimatedHours': estimatedHours,
      'totalLoggedHours': totalLoggedHours,
      'sprintId': sprintId,
      'rank': rank,
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
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      totalLoggedHours: (json['totalLoggedHours'] as num?)?.toDouble() ?? 0.0,
      sprintId: json['sprintId'] as String?,
      rank: json['rank'] as String? ?? 'U',
    );
  }

  factory Card.empty() {
    return Card(
      id: '',
      columnId: '',
      title: '',
      description: '',
      position: 0,
      assigneeIds: [],
      labelIds: [],
      priority: Priority.low,
      dueDate: null,
      commentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: '',
      estimatedHours: 0.0,
      sprintId: '',
      rank: '',
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
    double? estimatedHours,
    double? totalLoggedHours,
    String? sprintId,
    String? rank,
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
      estimatedHours: estimatedHours ?? this.estimatedHours,
      totalLoggedHours: totalLoggedHours ?? this.totalLoggedHours,
      sprintId: sprintId ?? this.sprintId,
      rank: rank ?? this.rank,
    );
  }
}
