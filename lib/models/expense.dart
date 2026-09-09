import 'bill_item.dart';

enum SplitType { equal, exact, percent, items }

enum ExpenseCategory { general, food, transport, entertainment, home, utilities, shopping, travel }

/// One logged expense: who paid, the total, and how it's split between the
/// participants. Always belongs to a group, backed by Supabase's
/// `expenses` table.
class Expense {
  Expense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.splitType,
    required Map<String, double> shares,
    required List<String> participantIds,
    this.category = ExpenseCategory.general,
    List<BillItem>? items,
    DateTime? date,
    DateTime? createdAt,
  })  : shares = {...shares},
        participantIds = [...participantIds],
        items = items ?? [],
        date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String groupId;
  String description;
  double amount;
  String paidById;
  SplitType splitType;

  /// personId -> amount that person owes toward this expense. Always sums
  /// to [amount].
  Map<String, double> shares;
  List<String> participantIds;
  ExpenseCategory category;
  List<BillItem> items;
  DateTime date;
  final DateTime createdAt;

  double shareOf(String personId) => shares[personId] ?? 0;

  Map<String, dynamic> toRow() => {
        'group_id': groupId,
        'description': description,
        'amount': amount,
        'paid_by': paidById,
        'split_type': splitType.name,
        'shares': shares,
        'participant_ids': participantIds,
        'category': category.name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Expense.fromRow(Map<String, dynamic> row) => Expense(
        id: row['id'] as String,
        groupId: row['group_id'] as String,
        description: row['description'] as String,
        amount: (row['amount'] as num).toDouble(),
        paidById: row['paid_by'] as String,
        splitType: SplitType.values.firstWhere(
          (t) => t.name == row['split_type'],
          orElse: () => SplitType.equal,
        ),
        shares: (row['shares'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        participantIds: (row['participant_ids'] as List).cast<String>(),
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == row['category'],
          orElse: () => ExpenseCategory.general,
        ),
        items: (row['items'] as List? ?? [])
            .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        date: DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
