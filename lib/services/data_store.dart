import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/person.dart';
import '../models/settlement.dart';

/// Persists the whole app state (friends, groups, expenses, settlements) to
/// on-device storage.
class DataStore {
  static const _peopleKey = 'officesplit.people.v2';
  static const _groupsKey = 'officesplit.groups.v2';
  static const _expensesKey = 'officesplit.expenses.v2';
  static const _settlementsKey = 'officesplit.settlements.v2';

  Future<List<Person>> loadPeople() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_peopleKey) ?? [];
    return raw.map((s) => Person.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> savePeople(List<Person> people) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_peopleKey, people.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<List<Group>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_groupsKey) ?? [];
    return raw.map((s) => Group.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_groupsKey, groups.map((g) => jsonEncode(g.toJson())).toList());
  }

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_expensesKey) ?? [];
    return raw.map((s) => Expense.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_expensesKey, expenses.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<List<Settlement>> loadSettlements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_settlementsKey) ?? [];
    return raw.map((s) => Settlement.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> saveSettlements(List<Settlement> settlements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _settlementsKey,
      settlements.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }
}
