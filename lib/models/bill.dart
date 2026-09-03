import 'person.dart';
import 'bill_item.dart';

/// The full state of one bill-splitting session: who was there, what they
/// ordered, who paid, and any tax/tip/extra charges to spread across
/// everyone proportional to what they actually ordered.
class Bill {
  Bill({
    required this.id,
    this.title = '',
    DateTime? date,
    List<Person>? people,
    List<BillItem>? items,
    this.payerId,
    this.taxPercent = 0,
    this.tipPercent = 0,
    this.otherCharges = 0,
  })  : date = date ?? DateTime.now(),
        people = people ?? [],
        items = items ?? [];

  final String id;
  String title;
  DateTime date;
  List<Person> people;
  List<BillItem> items;
  String? payerId;
  double taxPercent;
  double tipPercent;
  double otherCharges;

  double get subtotal => items.fold(0, (sum, i) => sum + i.price);

  double get taxAmount => subtotal * taxPercent / 100;

  double get tipAmount => subtotal * tipPercent / 100;

  double get extraCharges => taxAmount + tipAmount + otherCharges;

  double get grandTotal => subtotal + extraCharges;

  Person? get payer =>
      payerId == null ? null : people.where((p) => p.id == payerId).firstOrNull;

  /// Items nobody has claimed yet.
  List<BillItem> get unassignedItems =>
      items.where((i) => i.assigneeIds.isEmpty).toList();

  double subtotalFor(String personId) {
    double sum = 0;
    for (final item in items) {
      if (item.assigneeIds.contains(personId)) {
        sum += item.sharePerAssignee;
      }
    }
    return sum;
  }

  double totalFor(String personId) {
    final sub = subtotalFor(personId);
    if (subtotal <= 0) return 0;
    final shareOfExtras = extraCharges * (sub / subtotal);
    return sub + shareOfExtras;
  }

  List<BillItem> itemsFor(String personId) =>
      items.where((i) => i.assigneeIds.contains(personId)).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'people': people.map((p) => p.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'payerId': payerId,
        'taxPercent': taxPercent,
        'tipPercent': tipPercent,
        'otherCharges': otherCharges,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        people: (json['people'] as List? ?? [])
            .map((p) => Person.fromJson(p as Map<String, dynamic>))
            .toList(),
        items: (json['items'] as List? ?? [])
            .map((i) => BillItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        payerId: json['payerId'] as String?,
        taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
        tipPercent: (json['tipPercent'] as num?)?.toDouble() ?? 0,
        otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0,
      );
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
