import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../state/app_store.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';

class SettleUpScreen extends StatefulWidget {
  const SettleUpScreen({super.key, this.groupId, this.friendId});

  final String? groupId;
  final String? friendId;

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.groupId != null) return _GroupSettleView(groupId: widget.groupId!);
    return _FriendSettleView(friendId: widget.friendId!);
  }
}

class _GroupSettleView extends StatelessWidget {
  const _GroupSettleView({required this.groupId});
  final String groupId;

  Future<void> _record(BuildContext context, String fromId, String toId, double amount) async {
    final store = AppScope.of(context);
    final controller = TextEditingController(text: amount.toStringAsFixed(2));
    final currency = CurrencyScope.of(context);
    final confirmedAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${store.personById(fromId)?.name ?? '—'} pays ${store.personById(toId)?.name ?? '—'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(prefixText: currency.symbol, labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (confirmedAmount == null || confirmedAmount <= 0) return;
    store.addSettlement(groupId: groupId, fromId: fromId, toId: toId, amount: confirmedAmount);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final group = store.groupById(groupId);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final List<SettleSuggestion> suggestions = group == null ? [] : store.simplifyGroupDebts(groupId);

    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: suggestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('Everyone is settled up', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  'The fewest payments to settle everyone up:',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                for (final s in suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (store.personById(s.fromId) != null) PersonAvatar(person: store.personById(s.fromId)!, radius: 16),
                            Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant, size: 18),
                            if (store.personById(s.toId) != null) PersonAvatar(person: store.personById(s.toId)!, radius: 16),
                          ],
                        ),
                        title: Text(
                          '${_name(store, s.fromId)} pays ${_name(store, s.toId)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(currency.format(s.amount)),
                        trailing: FilledButton(
                          onPressed: () => _record(context, s.fromId, s.toId, s.amount),
                          child: const Text('Record'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _name(AppStore store, String id) => id == kMeId ? 'You' : (store.personById(id)?.name ?? '—');
}

class _FriendSettleView extends StatefulWidget {
  const _FriendSettleView({required this.friendId});
  final String friendId;

  @override
  State<_FriendSettleView> createState() => _FriendSettleViewState();
}

class _FriendSettleViewState extends State<_FriendSettleView> {
  late bool _youPay;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final store = AppScope.of(context);
    final balance = store.friendBalance(widget.friendId);
    _youPay = balance < 0;
    _controller = TextEditingController(text: balance.abs() > 0 ? balance.abs().toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _record() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) return;
    final store = AppScope.of(context);
    store.addSettlement(
      fromId: _youPay ? kMeId : widget.friendId,
      toId: _youPay ? widget.friendId : kMeId,
      amount: amount,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final friend = store.personById(widget.friendId);
    final currency = CurrencyScope.of(context);
    if (friend == null) return const Scaffold(body: Center(child: Text('Friend not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Settle up')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                PersonAvatar(person: friend, radius: 32),
                const SizedBox(height: 12),
                Text(friend.name, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text('You paid ${friend.name}')),
              ButtonSegment(value: false, label: Text('${friend.name} paid you')),
            ],
            selected: {_youPay},
            onSelectionChanged: (s) => setState(() => _youPay = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount', prefixText: currency.symbol),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _record, child: const Text('Record payment')),
          ),
        ],
      ),
    );
  }
}
