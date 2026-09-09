import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../models/settlement.dart';
import '../../state/app_scope.dart';
import '../../utils/category_icons.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expense_detail_screen.dart';
import '../settle/settle_up_screen.dart';

class FriendDetailScreen extends StatelessWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final friend = store.personById(friendId);
    final scheme = Theme.of(context).colorScheme;

    if (friend == null) return const Scaffold(body: Center(child: Text('Friend not found')));

    final balance = store.friendBalance(friendId);
    final history = store.historyWithFriend(friendId);

    return Scaffold(
      appBar: AppBar(title: Text(friend.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Center(
            child: Column(
              children: [
                PersonAvatar(person: friend, radius: 32),
                const SizedBox(height: 12),
                Text(friend.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                BalanceLabel(amount: balance, large: true),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettleUpScreen(friendId: friendId)),
                  ),
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text('Settle up'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No shared expenses yet', style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ),
            )
          else ...[
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in history)
              item is Expense
                  ? _FriendExpenseRow(expense: item)
                  : _FriendSettlementRow(settlement: item as Settlement),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(friendId: friendId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _FriendExpenseRow extends StatelessWidget {
  const _FriendExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isPayer = expense.paidById == kMeId;
    final me = expense.shareOf(kMeId);
    final yourEffect = isPayer ? expense.amount - me : -me;
    final groupName = expense.groupId == null ? null : store.groupById(expense.groupId!)?.name;

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
            '${DateFormat('d MMM').format(expense.date)}${groupName != null ? ' • $groupName' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: BalanceLabel(amount: yourEffect),
        ),
      ),
    );
  }
}

class _FriendSettlementRow extends StatelessWidget {
  const _FriendSettlementRow({required this.settlement});
  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final youPaid = settlement.fromId == kMeId;

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
          title: Text(youPaid ? 'You paid' : 'Paid you', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat('d MMM yyyy').format(settlement.date)),
          trailing: Text(currency.format(settlement.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
