import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';
import '../models/group.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../utils/error_text.dart';

class SettleSuggestion {
  SettleSuggestion({required this.fromId, required this.toId, required this.amount});
  final String fromId;
  final String toId;
  final double amount;
}

/// Central app state, backed by Supabase. Every list here is kept live via
/// realtime table streams — row-level security means each stream already
/// only ever contains what the signed-in user is allowed to see, so no
/// manual filtering by "my groups" is needed here.
class AppStore extends ChangeNotifier {
  AppStore(this._client);

  final SupabaseClient _client;

  String get meId => _client.auth.currentUser!.id;

  List<Person> people = [];
  List<Group> groups = [];
  List<Expense> expenses = [];
  List<Settlement> settlements = [];
  bool loaded = false;

  List<Map<String, dynamic>> _groupRows = [];
  List<Map<String, dynamic>> _memberRows = [];
  final Set<String> _readyStreams = {};

  /// Set if the initial load timed out before every stream connected, so
  /// the UI can show a retry option instead of spinning forever.
  String? loadError;

  StreamSubscription? _profilesSub;
  StreamSubscription? _groupsSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _settlementsSub;
  Timer? _loadTimeoutTimer;

  void startListening() {
    loaded = false;
    loadError = null;
    _readyStreams.clear();

    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(const Duration(seconds: 20), () {
      if (!loaded) {
        loadError = "Couldn't reach the server. Check your connection and try again.";
        notifyListeners();
      }
    });

    _profilesSub = _client.from('profiles').stream(primaryKey: ['id']).listen((rows) {
      people = rows.map(Person.fromRow).toList();
      _markReady('profiles');
    }, onError: (e) => _markReady('profiles', error: e));
    _groupsSub = _client.from('groups').stream(primaryKey: ['id']).listen((rows) {
      _groupRows = rows;
      _rebuildGroups();
      _markReady('groups');
    }, onError: (e) => _markReady('groups', error: e));
    _membersSub = _client.from('group_members').stream(primaryKey: ['group_id', 'user_id']).listen((rows) {
      _memberRows = rows;
      _rebuildGroups();
      _markReady('group_members');
    }, onError: (e) => _markReady('group_members', error: e));
    _expensesSub = _client.from('expenses').stream(primaryKey: ['id']).listen((rows) {
      expenses = rows.map(Expense.fromRow).toList();
      _markReady('expenses');
    }, onError: (e) => _markReady('expenses', error: e));
    _settlementsSub = _client.from('settlements').stream(primaryKey: ['id']).listen((rows) {
      settlements = rows.map(Settlement.fromRow).toList();
      _markReady('settlements');
    }, onError: (e) => _markReady('settlements', error: e));
  }

  void _rebuildGroups() {
    groups = _groupRows.map((row) {
      final memberIds = _memberRows
          .where((m) => m['group_id'] == row['id'])
          .map((m) => m['user_id'] as String)
          .toList();
      return Group.fromRow(row, memberIds);
    }).toList();
  }

  void _markReady(String stream, {Object? error}) {
    _readyStreams.add(stream);
    if (error != null && !loaded) {
      loadError = "Couldn't load $stream: ${describeError(error)}";
    }
    if (!loaded && _readyStreams.length == 5) {
      loaded = true;
      loadError = null;
      _loadTimeoutTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> stopListening() async {
    _loadTimeoutTimer?.cancel();
    await _profilesSub?.cancel();
    await _groupsSub?.cancel();
    await _membersSub?.cancel();
    await _expensesSub?.cancel();
    await _settlementsSub?.cancel();
    people = [];
    groups = [];
    expenses = [];
    settlements = [];
    loaded = false;
    notifyListeners();
  }

  Person? personById(String id) => people.where((p) => p.id == id).firstOrNull;

  Group? groupById(String id) => groups.where((g) => g.id == id).firstOrNull;

  List<Expense> expensesForGroup(String groupId) =>
      expenses.where((e) => e.groupId == groupId).toList()..sort((a, b) => b.date.compareTo(a.date));

  List<Settlement> settlementsForGroup(String groupId) =>
      settlements.where((s) => s.groupId == groupId).toList()..sort((a, b) => b.date.compareTo(a.date));

  // --- Profile ---------------------------------------------------------

  Future<void> renameMe(String name) async {
    await _client.from('profiles').update({'name': name.trim()}).eq('id', meId);
  }

  // --- Groups -------------------------------------------------------

  String _randomInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<Group> createGroup(String name) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final row = await _client
            .from('groups')
            .insert({
              'name': name.trim(),
              'color_value': kGroupPalette[groups.length % kGroupPalette.length],
              'invite_code': _randomInviteCode(),
              'created_by': meId,
            })
            .select()
            .single();
        await _client.from('group_members').insert({'group_id': row['id'], 'user_id': meId});
        return Group.fromRow(row, [meId]);
      } on PostgrestException catch (e) {
        if (e.code == '23505' && attempt < 5) continue;
        rethrow;
      }
    }
    throw Exception('Could not create the group. Try again.');
  }

  /// Throws with a friendly message on an invalid code.
  Future<void> joinGroupByCode(String code) async {
    await _client.rpc('join_group_by_code', params: {'p_code': code.trim()});
  }

  Future<void> renameGroup(String groupId, String name) async {
    await _client.from('groups').update({'name': name.trim()}).eq('id', groupId);
  }

  Future<void> leaveGroup(String groupId) async {
    await _client.from('group_members').delete().eq('group_id', groupId).eq('user_id', meId);
  }

  // --- Expenses -----------------------------------------------------

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidById,
    required SplitType splitType,
    required Map<String, double> shares,
    required List<String> participantIds,
    ExpenseCategory category = ExpenseCategory.general,
    List<dynamic>? items,
  }) async {
    final expense = Expense(
      id: '',
      groupId: groupId,
      description: description,
      amount: amount,
      paidById: paidById,
      splitType: splitType,
      shares: shares,
      participantIds: participantIds,
      category: category,
      items: items?.cast() ?? [],
    );
    await _client.from('expenses').insert({...expense.toRow(), 'created_by': meId});
  }

  Future<void> updateExpense(Expense expense) async {
    await _client.from('expenses').update(expense.toRow()).eq('id', expense.id);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // --- Settlements ----------------------------------------------------

  Future<void> addSettlement({
    required String groupId,
    required String fromId,
    required String toId,
    required double amount,
    String note = '',
  }) async {
    final settlement = Settlement(id: '', groupId: groupId, fromId: fromId, toId: toId, amount: amount, note: note);
    await _client.from('settlements').insert({...settlement.toRow(), 'created_by': meId});
  }

  // --- Balances -------------------------------------------------------

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

  /// Net balance between two people across every group they share.
  double pairBalanceGlobal(String a, String b) => _pairBalance(a, b, expenses, settlements);

  double friendBalance(String friendId) => pairBalanceGlobal(meId, friendId);

  /// Every friend (any other user sharing at least one group with you) and
  /// your aggregate balance with them.
  Map<String, double> friendBalances() {
    final ids = <String>{};
    for (final g in groups) {
      ids.addAll(g.memberIds.where((m) => m != meId));
    }
    return {for (final id in ids) id: friendBalance(id)};
  }

  double overallNetForMe() => friendBalances().values.fold(0.0, (a, b) => a + b);

  Map<String, double> groupMemberBalancesForMe(String groupId) {
    final g = groupById(groupId);
    if (g == null) return {};
    return {
      for (final m in g.memberIds)
        if (m != meId) m: pairBalanceInGroup(meId, m, groupId),
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
