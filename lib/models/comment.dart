class Comment {
  final String id;
  final String cardId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {'cardId': cardId, 'userId': userId, 'content': content};
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] ?? json['\$id']) as String,
      cardId: json['cardId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['\$updatedAt'] != null
          ? DateTime.parse(json['\$updatedAt'] as String)
          : null,
    );
  }

  Comment copyWith({
    String? id,
    String? cardId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
