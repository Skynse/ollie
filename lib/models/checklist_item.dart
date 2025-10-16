class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'completed_by': completedBy,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      completedBy: json['completed_by'] as String?,
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}
