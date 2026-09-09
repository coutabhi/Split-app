import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/expense.dart';
import '../../models/settlement.dart';
import '../../state/app_scope.dart';
import '../../utils/category_icons.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/group_avatar.dart';
import '../../widgets/person_avatar.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expense_detail_screen.dart';
import '../settle/settle_up_screen.dart';
import 'edit_group_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final group = store.groupById(groupId);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);

    if (group == null) {
      return const Scaffold(body: Center(child: Text('Group not found')));
    }

    final memberBalances = store.groupMemberBalancesForMe(groupId);
    final net = store.groupNetForMe(groupId);

    final activity = <dynamic>[
      ...store.expensesForGroup(groupId),
      ...store.settlementsForGroup(groupId),
    ]..sort((a, b) {
        final da = a is Expense ? a.date : (a as Settlement).date;
        final db = b is Expense ? b.date : (b as Settlement).date;
        return db.compareTo(da);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Invite a colleague',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => Share.share(
              'Join "${group.name}" on OfficeSplit — enter this invite code in the app: ${group.inviteCode}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditGroupScreen(groupId: groupId)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Row(
            children: [
              GroupAvatar(group: group, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: -8,
                  children: [
                    for (final id in group.memberIds)
                      if (store.personById(id) != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PersonAvatar(person: store.personById(id)!, radius: 16),
                        ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: net.abs() < 0.005
                ? null
                : (net > 0 ? kOwedColor.withValues(alpha: 0.12) : scheme.errorContainer.withValues(alpha: 0.5)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    net.abs() < 0.005
                        ? 'You are all settled up'
                        : (net > 0 ? 'You are owed overall' : 'You owe overall'),
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                  if (net.abs() >= 0.005)
                    Text(
                      currency.format(net.abs()),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: net > 0 ? kOwedColor : scheme.error,
                      ),
                    ),
                  const SizedBox(height: 12),
                  for (final entry in memberBalances.entries)
                    if (entry.value.abs() >= 0.005)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.value > 0
                                    ? '${store.personById(entry.key)?.name ?? '—'} owes you'
                                    : 'You owe ${store.personById(entry.key)?.name ?? '—'}',
                                style: TextStyle(color: scheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              currency.format(entry.value.abs()),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: entry.value > 0 ? kOwedColor : scheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettleUpScreen(groupId: groupId)),
                      ),
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('Settle up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No expenses yet', style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            )
          else ...[
            Text('Activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in activity)
              item is Expense
                  ? _ExpenseRow(expense: item)
                  : _SettlementRow(settlement: item as Settlement),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(groupId: groupId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final payer = store.personById(expense.paidById);
    final me = expense.shareOf(store.meId);
    final isPayer = expense.paidById == store.meId;
    final involved = expense.participantIds.contains(store.meId) || isPayer;
    final yourEffect = isPayer ? expense.amount - me : -me;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expenseId: expense.id)),
          ),
          leading: CircleAvatar(
            backgroundColor: scheme.surfaceContainerHighest,
            child: Icon(categoryIcon(expense.category), color: scheme.onSurfaceVariant, size: 20),
          ),
          title: Text(expense.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${DateFormat('d MMM').format(expense.date)} • ${isPayer ? 'You' : payer?.name ?? '—'} paid ${currency.format(expense.amount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: !involved
              ? Text('not involved', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))
              : BalanceLabel(amount: yourEffect),
        ),
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.settlement});
  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final from = store.personById(settlement.fromId);
    final to = store.personById(settlement.toId);
    final fromName = settlement.fromId == store.meId ? 'You' : (from?.name ?? '—');
    final toName = settlement.toId == store.meId ? 'you' : (to?.name ?? '—');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: scheme.surfaceContainerHigh,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: kOwedColor.withValues(alpha: 0.15),
            child: const Icon(Icons.check_circle_outline, color: kOwedColor, size: 20),
          ),
          title: Text(
            '$fromName paid $toName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(DateFormat('d MMM yyyy').format(settlement.date)),
          trailing: Text(
            currency.format(settlement.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
