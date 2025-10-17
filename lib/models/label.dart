class Label {
  final String id;
  final String boardId;
  final String name;
  final int color;

  Label({
    required this.id,
    required this.boardId,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {'boardId': boardId, 'name': name, 'color': color};
  }

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: (json['id'] ?? json['\$id']) as String,
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      color: json['color'],
    );
  }

  Label copyWith({String? id, String? boardId, String? name, int? color}) {
    return Label(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}
