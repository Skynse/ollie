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
      'text': text,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      completedBy: json['completedBy'] as String?,
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
