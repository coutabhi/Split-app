import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/person.dart';

const _uuid = Uuid();

/// Mutable wrapper around a [Bill] draft used while the user is building a
/// split. Every mutation notifies listeners so the wizard screens rebuild.
class BillEditor extends ChangeNotifier {
  BillEditor([Bill? bill]) : bill = bill ?? Bill(id: _uuid.v4());

  Bill bill;

  void replaceWith(Bill newBill) {
    bill = newBill;
    notifyListeners();
  }

  void setTitle(String title) {
    bill.title = title;
    notifyListeners();
  }

  // --- People -------------------------------------------------------

  Person addPerson(String name) {
    final usedColors = bill.people.map((p) => p.colorValue).toSet();
    final color = kPersonPalette.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => kPersonPalette[bill.people.length % kPersonPalette.length],
    );
    final person = Person(id: _uuid.v4(), name: name.trim(), colorValue: color);
    bill.people.add(person);
    bill.payerId ??= person.id;
    notifyListeners();
    return person;
  }

  void removePerson(String personId) {
    bill.people.removeWhere((p) => p.id == personId);
    for (final item in bill.items) {
      item.assigneeIds.remove(personId);
    }
    if (bill.payerId == personId) {
      bill.payerId = bill.people.isEmpty ? null : bill.people.first.id;
    }
    notifyListeners();
  }

  void renamePerson(String personId, String name) {
    final person = bill.people.where((p) => p.id == personId).firstOrNull;
    if (person != null) {
      person.name = name.trim();
      notifyListeners();
    }
  }

  void setPayer(String personId) {
    bill.payerId = personId;
    notifyListeners();
  }

  // --- Items ----------------------------------------------------------

  BillItem addItem(String name, double price, Set<String> assigneeIds) {
    final item = BillItem(
      id: _uuid.v4(),
      name: name.trim(),
      price: price,
      assigneeIds: assigneeIds,
    );
    bill.items.add(item);
    notifyListeners();
    return item;
  }

  void updateItem(String itemId, {String? name, double? price, Set<String>? assigneeIds}) {
    final item = bill.items.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    if (name != null) item.name = name.trim();
    if (price != null) item.price = price;
    if (assigneeIds != null) item.assigneeIds = assigneeIds;
    notifyListeners();
  }

  void removeItem(String itemId) {
    bill.items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  // --- Charges ----------------------------------------------------------

  void setTaxPercent(double v) {
    bill.taxPercent = v;
    notifyListeners();
  }

  void setTipPercent(double v) {
    bill.tipPercent = v;
    notifyListeners();
  }

  void setOtherCharges(double v) {
    bill.otherCharges = v;
    notifyListeners();
  }
}
