class BurndownSnapshot {
  final String id;
  final String sprintId;
  final DateTime date;
  final double remainingHours;
  final double completedHours;
  final int totalCards;
  final int completedCards;
  final double scopeChangeHours;
  final DateTime createdAt;

  BurndownSnapshot({
    required this.id,
    required this.sprintId,
    required this.date,
    required this.remainingHours,
    required this.completedHours,
    required this.totalCards,
    required this.completedCards,
    this.scopeChangeHours = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sprintId': sprintId,
      'date': date.toIso8601String(),
      'remainingHours': remainingHours,
      'completedHours': completedHours,
      'totalCards': totalCards,
      'completedCards': completedCards,
      'scopeChangeHours': scopeChangeHours,
    };
  }

  factory BurndownSnapshot.fromJson(Map<String, dynamic> json) {
    return BurndownSnapshot(
      id: (json['id'] ?? json['\$id']) as String,
      sprintId: json['sprintId'] as String,
      date: DateTime.parse(json['date'] as String),
      remainingHours: (json['remainingHours'] as num).toDouble(),
      completedHours: (json['completedHours'] as num).toDouble(),
      totalCards: json['totalCards'] as int,
      completedCards: json['completedCards'] as int,
      scopeChangeHours: (json['scopeChangeHours'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
    );
  }

  BurndownSnapshot copyWith({
    String? id,
    String? sprintId,
    DateTime? date,
    double? remainingHours,
    double? completedHours,
    int? totalCards,
    int? completedCards,
    double? scopeChangeHours,
    DateTime? createdAt,
  }) {
    return BurndownSnapshot(
      id: id ?? this.id,
      sprintId: sprintId ?? this.sprintId,
      date: date ?? this.date,
      remainingHours: remainingHours ?? this.remainingHours,
      completedHours: completedHours ?? this.completedHours,
      totalCards: totalCards ?? this.totalCards,
      completedCards: completedCards ?? this.completedCards,
      scopeChangeHours: scopeChangeHours ?? this.scopeChangeHours,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  double get totalHours => remainingHours + completedHours;
  double get completionPercentage =>
      totalHours > 0 ? (completedHours / totalHours) * 100 : 0;
}
