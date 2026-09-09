import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../state/app_store.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';

/// Suggested "settle up" payments for a group, computed from the minimal
/// set of transactions that would zero out every member's balance.
class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({super.key, required this.groupId});

  final String groupId;

  Future<void> _record(BuildContext context, String fromId, String toId, double amount) async {
    final store = AppScope.of(context);
    final controller = TextEditingController(text: amount.toStringAsFixed(2));
    final currency = CurrencyScope.of(context);
    final confirmedAmount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_name(store, fromId)} pays ${_name(store, toId)}'),
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
    try {
      await store.addSettlement(groupId: groupId, fromId: fromId, toId: toId, amount: confirmedAmount);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not record the payment. Try again.')));
      }
    }
  }

  static String _name(AppStore store, String id) => id == store.meId ? 'You' : (store.personById(id)?.name ?? '—');

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
}
