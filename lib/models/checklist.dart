import 'checklist_item.dart';

class Checklist {
  final String id;
  final String cardId;
  final String title;
  final List<ChecklistItem> items;

  Checklist({
    required this.id,
    required this.cardId,
    required this.title,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: (json['id'] ?? json['\$id']) as String,
      cardId: json['cardId'] as String,
      title: json['title'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => ChecklistItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Checklist copyWith({
    String? id,
    String? cardId,
    String? title,
    List<ChecklistItem>? items,
  }) {
    return Checklist(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      items: items ?? this.items,
    );
  }
}
