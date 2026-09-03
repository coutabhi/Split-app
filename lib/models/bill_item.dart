/// A single ordered item on the bill (e.g. "Chicken Biryani"), owned by
/// whoever ordered it. An item can be assigned to more than one person,
/// in which case its price is split evenly between the assignees.
class BillItem {
  BillItem({
    required this.id,
    required this.name,
    required this.price,
    required Set<String> assigneeIds,
  }) : assigneeIds = {...assigneeIds};

  final String id;
  String name;
  double price;
  Set<String> assigneeIds;

  double get sharePerAssignee =>
      assigneeIds.isEmpty ? 0 : price / assigneeIds.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'assigneeIds': assigneeIds.toList(),
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        assigneeIds: (json['assigneeIds'] as List).cast<String>().toSet(),
      );
}
