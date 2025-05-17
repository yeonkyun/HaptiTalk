import 'package:flutter/material.dart';

// 세션 태그 모델
class SessionTag {
  final String id; // 태그 ID
  final String name; // 태그 이름
  final Color color; // 태그 색상

  SessionTag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory SessionTag.fromJson(Map<String, dynamic> json) {
    return SessionTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  // 복사본 생성
  SessionTag copyWith({
    String? id,
    String? name,
    Color? color,
  }) {
    return SessionTag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SessionTag &&
        other.id == id &&
        other.name == name &&
        other.color == color;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ color.hashCode;
}
