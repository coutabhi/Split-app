import 'bill_item.dart';

enum SplitType { equal, exact, percent, items }

enum ExpenseCategory { general, food, transport, entertainment, home, utilities, shopping, travel }

/// One logged expense: who paid, the total, and how it's split between the
/// participants. Belongs to a [groupId], or is a direct expense between
/// friends when null.
class Expense {
  Expense({
    required this.id,
    this.groupId,
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
  String? groupId;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'description': description,
        'amount': amount,
        'paidById': paidById,
        'splitType': splitType.name,
        'shares': shares,
        'participantIds': participantIds,
        'category': category.name,
        'items': items.map((i) => i.toJson()).toList(),
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        groupId: json['groupId'] as String?,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidById: json['paidById'] as String,
        splitType: SplitType.values.firstWhere(
          (t) => t.name == json['splitType'],
          orElse: () => SplitType.equal,
        ),
        shares: (json['shares'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        participantIds: (json['participantIds'] as List).cast<String>(),
        category: ExpenseCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ExpenseCategory.general,
        ),
        items: (json['items'] as List? ?? [])
            .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
