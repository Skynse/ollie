class TimeLog {
  final String id;
  final String cardId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String? notes;
  final bool isActive;
  final String? sprintId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeLog({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.notes,
    required this.isActive,
    this.sprintId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'isActive': isActive,
      'sprintId': sprintId,
    };
  }

  factory TimeLog.fromJson(Map<String, dynamic> json) {
    return TimeLog(
      id: (json['id'] ?? json['\$id']) as String,
      cardId: json['cardId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool,
      sprintId: json['sprintId'] as String?,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : DateTime.now(),
    );
  }

  TimeLog copyWith({
    String? id,
    String? cardId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? notes,
    bool? isActive,
    String? sprintId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeLog(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      sprintId: sprintId ?? this.sprintId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  double get durationHours => durationMinutes / 60.0;

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Duration get elapsedTime {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }
}
