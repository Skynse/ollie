import '../utils/copy_with.dart';
import 'priority.dart';

class Card {
  final String id;
  final String columnId;
  final String title;
  final String? description;
  final Priority priority;
  final DateTime? dueDate;
  final double? estimatedHours;

  /// Denormalized sum of this card's time logs. Maintained by the repository
  /// whenever a log is created, updated or deleted.
  final double totalLoggedHours;
  final String? sprintId;
  final String rank;
  final bool completed;
  final int subtaskCount;
  final int completedSubtaskCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Card({
    required this.id,
    required this.columnId,
    required this.title,
    this.description,
    required this.priority,
    this.dueDate,
    this.estimatedHours,
    this.totalLoggedHours = 0.0,
    this.sprintId,
    required this.rank,
    required this.completed,
    this.subtaskCount = 0,
    this.completedSubtaskCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'columnId': columnId,
      'title': title,
      'description': description,
      'priority': priority.toJson(),
      'dueDate': dueDate?.toIso8601String(),
      'estimatedHours': estimatedHours,
      'totalLoggedHours': totalLoggedHours,
      'sprintId': sprintId,
      'rank': rank,
      'completed': completed,
      'subtaskCount': subtaskCount,
      'completedSubtaskCount': completedSubtaskCount,
      '\$createdAt': createdAt.toUtc().toIso8601String(),
      '\$updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      id: (json['id'] ?? json['\$id']) as String,
      columnId: json['columnId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: json['priority'] != null
          ? Priority.fromJson(json['priority'] as String)
          : Priority.low,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      totalLoggedHours: (json['totalLoggedHours'] as num?)?.toDouble() ?? 0.0,
      sprintId: (json['sprintId'] as String?)?.isEmpty == true
          ? null
          : json['sprintId'] as String?,
      rank: json['rank'] as String? ?? 'U',
      completed: json['completed'] as bool? ?? false,
      subtaskCount: json['subtaskCount'] as int? ?? 0,
      completedSubtaskCount: json['completedSubtaskCount'] as int? ?? 0,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Card copyWith({
    String? id,
    String? columnId,
    String? title,
    Object? description = unset,
    Priority? priority,
    Object? dueDate = unset,
    Object? estimatedHours = unset,
    double? totalLoggedHours,
    Object? sprintId = unset,
    String? rank,
    bool? completed,
    int? subtaskCount,
    int? completedSubtaskCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Card(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: identical(description, unset)
          ? this.description
          : description as String?,
      priority: priority ?? this.priority,
      dueDate: identical(dueDate, unset) ? this.dueDate : dueDate as DateTime?,
      estimatedHours: identical(estimatedHours, unset)
          ? this.estimatedHours
          : (estimatedHours as num?)?.toDouble(),
      totalLoggedHours: totalLoggedHours ?? this.totalLoggedHours,
      sprintId: identical(sprintId, unset)
          ? this.sprintId
          : sprintId as String?,
      rank: rank ?? this.rank,
      completed: completed ?? this.completed,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      completedSubtaskCount:
          completedSubtaskCount ?? this.completedSubtaskCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
