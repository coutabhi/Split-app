import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bill.dart';

/// Persists finished splits to on-device storage so the team's history of
/// past office lunches / expenses survives app restarts.
class BillStore {
  static const _historyKey = 'officesplit.history.v1';
  static const _draftKey = 'officesplit.draft.v1';

  Future<List<Bill>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((s) => Bill.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveToHistory(Bill bill) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.removeWhere((b) => b.id == bill.id);
    history.add(bill);
    await prefs.setStringList(
      _historyKey,
      history.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> deleteFromHistory(String billId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.removeWhere((b) => b.id == billId);
    await prefs.setStringList(
      _historyKey,
      history.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  Future<void> saveDraft(Bill? bill) async {
    final prefs = await SharedPreferences.getInstance();
    if (bill == null) {
      await prefs.remove(_draftKey);
    } else {
      await prefs.setString(_draftKey, jsonEncode(bill.toJson()));
    }
  }

  Future<Bill?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    try {
      return Bill.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
