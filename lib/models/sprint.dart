import '../utils/copy_with.dart';

enum SprintStatus {
  planning,
  active,
  completed;

  String toJson() => name;

  static SprintStatus fromJson(String json) {
    return SprintStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => SprintStatus.planning,
    );
  }
}

class Sprint {
  final String id;
  final String boardId;
  final String name;
  final String? goal;
  final DateTime startDate;
  final DateTime endDate;
  final double targetHours;
  final SprintStatus status;

  /// Derived from `cards.sprint_id` when a sprint is read from the database.
  /// It is never stored on the sprint row, which keeps card membership in one
  /// place.
  final List<String> cardIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sprint({
    required this.id,
    required this.boardId,
    required this.name,
    this.goal,
    required this.startDate,
    required this.endDate,
    required this.targetHours,
    required this.status,
    this.cardIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boardId': boardId,
      'name': name,
      'goal': goal,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetHours': targetHours,
      'status': status.toJson(),
      '\$createdAt': createdAt.toUtc().toIso8601String(),
      '\$updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Sprint.fromJson(Map<String, dynamic> json) {
    return Sprint(
      id: (json['id'] ?? json['\$id']) as String,
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      targetHours: (json['targetHours'] as num).toDouble(),
      status: SprintStatus.fromJson(json['status'] as String),
      cardIds:
          (json['cardIds'] as List<dynamic>?)
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

  Sprint copyWith({
    String? id,
    String? boardId,
    String? name,
    Object? goal = unset,
    DateTime? startDate,
    DateTime? endDate,
    double? targetHours,
    SprintStatus? status,
    List<String>? cardIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sprint(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      goal: identical(goal, unset) ? this.goal : goal as String?,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetHours: targetHours ?? this.targetHours,
      status: status ?? this.status,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays;

  bool get isActive => status == SprintStatus.active;
  bool get isCompleted => status == SprintStatus.completed;
  bool get isPast => DateTime.now().isAfter(endDate);

  double get daysRemaining {
    if (isCompleted) return 0;
    final now = DateTime.now();
    if (now.isBefore(startDate)) return durationDays.toDouble();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays.toDouble();
  }

  /// Fraction of the sprint's calendar that has elapsed.
  double get progress {
    if (durationDays <= 0) return isCompleted ? 1 : 0;
    final total = durationDays.toDouble();
    final elapsed = total - daysRemaining;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
