import 'person.dart';

/// A persistent group of people (e.g. "Office") that expenses get logged
/// against. Balances accumulate across every expense in the group over
/// time, unlike a one-off split.
class Group {
  Group({
    required this.id,
    required this.name,
    required this.colorValue,
    List<String>? memberIds,
    DateTime? createdAt,
  })  : memberIds = memberIds ?? [kMeId],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  int colorValue;
  List<String> memberIds;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'memberIds': memberIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        memberIds: (json['memberIds'] as List).cast<String>(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A palette for group avatars, distinct in tone from the person palette so
/// groups and people stay visually distinguishable side by side.
const List<int> kGroupPalette = [
  0xFF5B7FDE,
  0xFF2BA894,
  0xFFE07A3F,
  0xFF9C6EFF,
  0xFFD65D8A,
  0xFF3FA66B,
];
