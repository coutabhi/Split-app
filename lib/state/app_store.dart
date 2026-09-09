import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../services/data_store.dart';

const _uuid = Uuid();

class SettleSuggestion {
  SettleSuggestion({required this.fromId, required this.toId, required this.amount});
  final String fromId;
  final String toId;
  final double amount;
}

/// Central app state: the friends directory (always including "me"),
/// groups, expenses and settlements, plus every balance computation the UI
/// needs. Mirrors how Splitwise itself models data - balances accumulate
/// across every expense in a group (or between two friends) over time,
/// rather than resetting per bill.
class AppStore extends ChangeNotifier {
  AppStore(this._store);

  final DataStore _store;

  List<Person> people = [];
  List<Group> groups = [];
  List<Expense> expenses = [];
  List<Settlement> settlements = [];
  bool loaded = false;

  List<Person> get friends => people.where((p) => p.id != kMeId).toList();

  Person get me => people.firstWhere((p) => p.id == kMeId);

  Future<void> load() async {
    people = await _store.loadPeople();
    if (people.every((p) => p.id != kMeId)) {
      people.insert(0, Person(id: kMeId, name: 'You', colorValue: kPersonPalette[0]));
      await _store.savePeople(people);
    }
    groups = await _store.loadGroups();
    expenses = await _store.loadExpenses();
    settlements = await _store.loadSettlements();
    loaded = true;
    notifyListeners();
  }

  Person? personById(String id) => people.where((p) => p.id == id).firstOrNull;

  Group? groupById(String id) => groups.where((g) => g.id == id).firstOrNull;

  List<Expense> expensesForGroup(String groupId) =>
      expenses.where((e) => e.groupId == groupId).toList()..sort((a, b) => b.date.compareTo(a.date));

  List<Settlement> settlementsForGroup(String groupId) =>
      settlements.where((s) => s.groupId == groupId).toList()..sort((a, b) => b.date.compareTo(a.date));

  /// Every expense and settlement involving both [kMeId] and [friendId],
  /// in any group or none, newest first.
  List<dynamic> historyWithFriend(String friendId) {
    final items = <dynamic>[
      ...expenses.where(
        (e) => e.participantIds.contains(friendId) && e.participantIds.contains(kMeId),
      ),
      ...settlements.where(
        (s) => (s.fromId == friendId && s.toId == kMeId) || (s.fromId == kMeId && s.toId == friendId),
      ),
    ];
    items.sort((a, b) {
      final da = a is Expense ? a.date : (a as Settlement).date;
      final db = b is Expense ? b.date : (b as Settlement).date;
      return db.compareTo(da);
    });
    return items;
  }

  // --- Friends ----------------------------------------------------------

  Person addFriend(String name) {
    final usedColors = people.map((p) => p.colorValue).toSet();
    final color = kPersonPalette.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => kPersonPalette[people.length % kPersonPalette.length],
    );
    final person = Person(id: _uuid.v4(), name: name.trim(), colorValue: color);
    people.add(person);
    _store.savePeople(people);
    notifyListeners();
    return person;
  }

  void renamePerson(String id, String name) {
    final p = personById(id);
    if (p == null) return;
    p.name = name.trim();
    _store.savePeople(people);
    notifyListeners();
  }

  /// Returns null on success, or an error message if the friend can't be
  /// removed (still has a non-zero balance, matching Splitwise's rule).
  String? removeFriend(String id) {
    if (friendBalance(id).abs() > 0.005) {
      return "You can't remove a friend you still owe or who owes you.";
    }
    people.removeWhere((p) => p.id == id);
    for (final g in groups) {
      g.memberIds.remove(id);
    }
    _store.savePeople(people);
    _store.saveGroups(groups);
    notifyListeners();
    return null;
  }

  // --- Groups -------------------------------------------------------

  Group addGroup(String name, List<String> memberIds, {int? colorValue}) {
    final ids = {kMeId, ...memberIds}.toList();
    final group = Group(
      id: _uuid.v4(),
      name: name.trim(),
      colorValue: colorValue ?? kGroupPalette[groups.length % kGroupPalette.length],
      memberIds: ids,
    );
    groups.add(group);
    _store.saveGroups(groups);
    notifyListeners();
    return group;
  }

  void updateGroupMembers(String groupId, List<String> memberIds) {
    final g = groupById(groupId);
    if (g == null) return;
    g.memberIds = {kMeId, ...memberIds}.toList();
    _store.saveGroups(groups);
    notifyListeners();
  }

  void renameGroup(String groupId, String name) {
    final g = groupById(groupId);
    if (g == null) return;
    g.name = name.trim();
    _store.saveGroups(groups);
    notifyListeners();
  }

  String? deleteGroup(String groupId) {
    if (groupNetForMe(groupId).abs() > 0.005) {
      return "Settle up in this group before deleting it.";
    }
    groups.removeWhere((g) => g.id == groupId);
    expenses.removeWhere((e) => e.groupId == groupId);
    settlements.removeWhere((s) => s.groupId == groupId);
    _store.saveGroups(groups);
    _store.saveExpenses(expenses);
    _store.saveSettlements(settlements);
    notifyListeners();
    return null;
  }

  // --- Expenses -----------------------------------------------------

  Expense addExpense({
    String? groupId,
    required String description,
    required double amount,
    required String paidById,
    required SplitType splitType,
    required Map<String, double> shares,
    required List<String> participantIds,
    ExpenseCategory category = ExpenseCategory.general,
    List<dynamic>? items,
    DateTime? date,
  }) {
    final expense = Expense(
      id: _uuid.v4(),
      groupId: groupId,
      description: description.trim(),
      amount: amount,
      paidById: paidById,
      splitType: splitType,
      shares: shares,
      participantIds: participantIds,
      category: category,
      items: items?.cast() ?? [],
      date: date,
    );
    expenses.add(expense);
    _store.saveExpenses(expenses);
    notifyListeners();
    return expense;
  }

  void updateExpense(Expense expense) {
    final i = expenses.indexWhere((e) => e.id == expense.id);
    if (i == -1) return;
    expenses[i] = expense;
    _store.saveExpenses(expenses);
    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    _store.saveExpenses(expenses);
    notifyListeners();
  }

  // --- Settlements ----------------------------------------------------

  Settlement addSettlement({
    String? groupId,
    required String fromId,
    required String toId,
    required double amount,
    String note = '',
  }) {
    final settlement = Settlement(
      id: _uuid.v4(),
      groupId: groupId,
      fromId: fromId,
      toId: toId,
      amount: amount,
      note: note,
    );
    settlements.add(settlement);
    _store.saveSettlements(settlements);
    notifyListeners();
    return settlement;
  }

  void deleteSettlement(String id) {
    settlements.removeWhere((s) => s.id == id);
    _store.saveSettlements(settlements);
    notifyListeners();
  }

  // --- Balances -------------------------------------------------------

  /// Amount [b] owes [a], scoped to a single group. Negative means [a]
  /// owes [b].
  double _pairBalance(String a, String b, Iterable<Expense> exps, Iterable<Settlement> setts) {
    double bal = 0;
    for (final e in exps) {
      if (e.paidById == a) bal += e.shareOf(b);
      if (e.paidById == b) bal -= e.shareOf(a);
    }
    for (final s in setts) {
      if (s.fromId == b && s.toId == a) bal -= s.amount;
      if (s.fromId == a && s.toId == b) bal += s.amount;
    }
    return bal;
  }

  double pairBalanceInGroup(String a, String b, String groupId) => _pairBalance(
        a,
        b,
        expenses.where((e) => e.groupId == groupId),
        settlements.where((s) => s.groupId == groupId),
      );

  /// Net balance between two people across every group and every direct
  /// expense/settlement between them - what Splitwise shows as the
  /// friend-level balance.
  double pairBalanceGlobal(String a, String b) => _pairBalance(a, b, expenses, settlements);

  double friendBalance(String friendId) => pairBalanceGlobal(kMeId, friendId);

  double overallNetForMe() => friends.fold(0.0, (sum, f) => sum + friendBalance(f.id));

  Map<String, double> groupMemberBalancesForMe(String groupId) {
    final g = groupById(groupId);
    if (g == null) return {};
    return {
      for (final m in g.memberIds)
        if (m != kMeId) m: pairBalanceInGroup(kMeId, m, groupId),
    };
  }

  double groupNetForMe(String groupId) =>
      groupMemberBalancesForMe(groupId).values.fold(0.0, (a, b) => a + b);

  /// Net position of every member within a group (positive = owed money by
  /// the group, negative = owes the group), used to compute the minimal
  /// "settle up" suggestions.
  Map<String, double> groupNetBalances(String groupId) {
    final g = groupById(groupId);
    if (g == null) return {};
    final net = {for (final m in g.memberIds) m: 0.0};
    for (final e in expensesForGroup(groupId)) {
      net[e.paidById] = (net[e.paidById] ?? 0) + e.amount;
      for (final entry in e.shares.entries) {
        net[entry.key] = (net[entry.key] ?? 0) - entry.value;
      }
    }
    for (final s in settlementsForGroup(groupId)) {
      net[s.fromId] = (net[s.fromId] ?? 0) + s.amount;
      net[s.toId] = (net[s.toId] ?? 0) - s.amount;
    }
    return net;
  }

  /// The fewest possible transactions that would zero out every balance in
  /// the group, via the classic greedy largest-creditor/largest-debtor
  /// match Splitwise uses for "simplify debts".
  List<SettleSuggestion> simplifyGroupDebts(String groupId) {
    final net = groupNetBalances(groupId);
    final creditors = net.entries.where((e) => e.value > 0.005).map((e) => MapEntry(e.key, e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = net.entries.where((e) => e.value < -0.005).map((e) => MapEntry(e.key, -e.value)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <SettleSuggestion>[];
    var ci = 0, di = 0;
    while (ci < creditors.length && di < debtors.length) {
      final credit = creditors[ci].value;
      final debt = debtors[di].value;
      final amount = credit < debt ? credit : debt;
      if (amount > 0.005) {
        result.add(SettleSuggestion(fromId: debtors[di].key, toId: creditors[ci].key, amount: amount));
      }
      creditors[ci] = MapEntry(creditors[ci].key, credit - amount);
      debtors[di] = MapEntry(debtors[di].key, debt - amount);
      if (creditors[ci].value < 0.01) ci++;
      if (debtors[di].value < 0.01) di++;
    }
    return result;
  }
}

extension FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
