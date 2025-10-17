enum SprintStatus {
  planning,
  active,
  completed;

  String toJson() => name;

  static SprintStatus fromJson(String json) {
    return SprintStatus.values.firstWhere((e) => e.name == json);
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
    required this.cardIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'name': name,
      'goal': goal,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetHours': targetHours,
      'status': status.toJson(),
      'cardIds': cardIds,
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
    String? goal,
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
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetHours: targetHours ?? this.targetHours,
      status: status ?? this.status,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
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

  double get progress {
    final total = durationDays.toDouble();
    final elapsed = total - daysRemaining;
    return elapsed / total;
  }
}
