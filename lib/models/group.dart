/// A shared group backed by Supabase's `groups` + `group_members` tables.
/// Colleagues join via [inviteCode]; balances accumulate across every
/// expense logged against the group over time.
class Group {
  Group({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.inviteCode,
    required this.createdBy,
    List<String>? memberIds,
    DateTime? createdAt,
  })  : memberIds = memberIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  int colorValue;
  final String inviteCode;
  final String createdBy;
  List<String> memberIds;
  final DateTime createdAt;

  factory Group.fromRow(Map<String, dynamic> row, List<String> memberIds) => Group(
        id: row['id'] as String,
        name: row['name'] as String,
        colorValue: (row['color_value'] as num).toInt(),
        inviteCode: row['invite_code'] as String,
        createdBy: row['created_by'] as String,
        memberIds: memberIds,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
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
