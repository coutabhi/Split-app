/// A recorded payment from one person to another that pays down a debt
/// (Splitwise's "Settle up"). Belongs to a group, or is a direct
/// friend-to-friend settlement when [groupId] is null.
class Settlement {
  Settlement({
    required this.id,
    this.groupId,
    required this.fromId,
    required this.toId,
    required this.amount,
    DateTime? date,
    this.note = '',
  }) : date = date ?? DateTime.now();

  final String id;
  String? groupId;
  String fromId;
  String toId;
  double amount;
  DateTime date;
  String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        groupId: json['groupId'] as String?,
        fromId: json['fromId'] as String,
        toId: json['toId'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String? ?? '',
      );
}
