/// A recorded payment from one person to another that pays down a debt
/// within a group (Splitwise's "Settle up"), backed by Supabase's
/// `settlements` table.
class Settlement {
  Settlement({
    required this.id,
    required this.groupId,
    required this.fromId,
    required this.toId,
    required this.amount,
    DateTime? date,
    this.note = '',
  }) : date = date ?? DateTime.now();

  final String id;
  final String groupId;
  final String fromId;
  final String toId;
  final double amount;
  final DateTime date;
  final String note;

  Map<String, dynamic> toRow() => {
        'group_id': groupId,
        'from_id': fromId,
        'to_id': toId,
        'amount': amount,
        'note': note,
      };

  factory Settlement.fromRow(Map<String, dynamic> row) => Settlement(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        fromId: row['from_id'] as String,
        toId: row['to_id'] as String,
        amount: (row['amount'] as num).toDouble(),
        date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
        note: row['note'] as String? ?? '',
      );
}
