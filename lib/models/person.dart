import 'package:flutter/material.dart';

/// A teammate, backed by a row in Supabase's `profiles` table (one per
/// signed-up user). [id] is that user's auth uid.
class Person {
  Person({required this.id, required this.name, required this.colorValue});

  final String id;
  String name;
  int colorValue;

  Color get color => Color(colorValue);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory Person.fromRow(Map<String, dynamic> row) => Person(
        id: row['id'] as String,
        name: row['name'] as String,
        colorValue: (row['color_value'] as num).toInt(),
      );

  Person copy() => Person(id: id, name: name, colorValue: colorValue);
}

/// A friendly, high-contrast palette to auto-assign to new participants.
const List<int> kPersonPalette = [
  0xFF2BA894, // teal
  0xFFE95A6A, // coral red
  0xFFFFB03B, // amber
  0xFF6C5CE7, // violet
  0xFF3B9DFF, // blue
  0xFFFF8AB1, // pink
  0xFF39C46A, // green
  0xFFFF7A45, // orange
  0xFF9C6EFF, // purple
  0xFF17B0A7, // aqua
];
