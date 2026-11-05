import '../utils/copy_with.dart';

class TimeLog {
  final String id;
  final String cardId;
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
      'id': id,
      'cardId': cardId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'isActive': isActive,
      'sprintId': sprintId,
      '\$createdAt': createdAt.toUtc().toIso8601String(),
      '\$updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory TimeLog.fromJson(Map<String, dynamic> json) {
    final endTimeStr = json['endTime'] as String?;
    DateTime? parsedEndTime;
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      final parsed = DateTime.parse(endTimeStr);
      // Legacy Appwrite rows used year 2099 for "no end time".
      parsedEndTime = parsed.year == 2099 ? null : parsed;
    }

    final notes = json['notes'] as String?;
    final sprintId = json['sprintId'] as String?;

    return TimeLog(
      id: (json['id'] ?? json['\$id']) as String,
      cardId: json['cardId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: parsedEndTime,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      notes: notes == null || notes.isEmpty ? null : notes,
      isActive: json['isActive'] as bool? ?? false,
      sprintId: sprintId == null || sprintId.isEmpty ? null : sprintId,
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
    DateTime? startTime,
    Object? endTime = unset,
    int? durationMinutes,
    Object? notes = unset,
    bool? isActive,
    Object? sprintId = unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeLog(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      startTime: startTime ?? this.startTime,
      endTime: identical(endTime, unset) ? this.endTime : endTime as DateTime?,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: identical(notes, unset) ? this.notes : notes as String?,
      isActive: isActive ?? this.isActive,
      sprintId: identical(sprintId, unset)
          ? this.sprintId
          : sprintId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
