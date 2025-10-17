class BoardColumn {
  final String id;
  final String boardId;
  final String name;
  final int position;
  final String color;
  final int? wipLimit;
  final List<String> cardIds;

  BoardColumn({
    required this.id,
    required this.boardId,
    required this.name,
    required this.position,
    required this.color,
    this.wipLimit,
    required this.cardIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'name': name,
      'position': position,
      'color': color,
      'wipLimit': wipLimit,
      'cardIds': cardIds,
    };
  }

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      id: (json['id'] ?? json['\$id']) as String,
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
      color: json['color'] as String? ?? '#808080',
      wipLimit: json['wipLimit'] as int?,
      cardIds:
          (json['cardIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  BoardColumn copyWith({
    String? id,
    String? boardId,
    String? name,
    int? position,
    String? color,
    int? wipLimit,
    List<String>? cardIds,
  }) {
    return BoardColumn(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color ?? this.color,
      wipLimit: wipLimit ?? this.wipLimit,
      cardIds: cardIds ?? this.cardIds,
    );
  }
}
