import 'package:flutter/material.dart' show Colors;

import '../utils/copy_with.dart';

class BoardColumn {
  final String id;
  final String boardId;
  final String name;
  final int position;
  final int color;
  final int? wipLimit;

  BoardColumn({
    required this.id,
    required this.boardId,
    required this.name,
    required this.position,
    required this.color,
    this.wipLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boardId': boardId,
      'name': name,
      'position': position,
      'color': color,
      'wipLimit': wipLimit,
    };
  }

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      id: (json['id'] ?? json['\$id']) as String,
      boardId: json['boardId'] as String,
      name: json['name'] as String,
      position: json['position'] as int? ?? 0,
      color: json['color'] as int? ?? Colors.grey.toARGB32(),
      wipLimit: json['wipLimit'] as int?,
    );
  }

  BoardColumn copyWith({
    String? id,
    String? boardId,
    String? name,
    int? position,
    int? color,
    Object? wipLimit = unset,
  }) {
    return BoardColumn(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color ?? this.color,
      wipLimit: identical(wipLimit, unset) ? this.wipLimit : wipLimit as int?,
    );
  }
}
