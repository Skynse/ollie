import 'package:flutter/material.dart';

class CursorPosition {
  final String userId;
  final String userName;
  final double x;
  final double y;
  final Color color;

  CursorPosition({
    required this.userId,
    required this.userName,
    required this.x,
    required this.y,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'x': x,
      'y': y,
      'color': color.value,
    };
  }

  factory CursorPosition.fromJson(Map<String, dynamic> json) {
    return CursorPosition(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      color: Color(json['color'] as int),
    );
  }
}
