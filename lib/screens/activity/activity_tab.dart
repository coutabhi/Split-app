import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../models/settlement.dart';
import '../../state/app_scope.dart';
import '../../utils/category_icons.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../expense/expense_detail_screen.dart';

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final items = <dynamic>[...store.expenses, ...store.settlements]..sort((a, b) {
        final da = a is Expense ? a.date : (a as Settlement).date;
        final db = b is Expense ? b.date : (b as Settlement).date;
        return db.compareTo(da);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text('Nothing yet', style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(
                      'Expenses and payments show up here as you add them.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                for (final item in items)
                  item is Expense ? _ActivityExpenseRow(expense: item) : _ActivitySettlementRow(settlement: item as Settlement),
              ],
            ),
    );
  }
}

class _ActivityExpenseRow extends StatelessWidget {
  const _ActivityExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isPayer = expense.paidById == kMeId;
    final me = expense.shareOf(kMeId);
    final involved = expense.participantIds.contains(kMeId) || isPayer;
    final yourEffect = isPayer ? expense.amount - me : -me;
    final context_ = expense.groupId != null
        ? store.groupById(expense.groupId!)?.name
        : (expense.participantIds.where((id) => id != kMeId).map((id) => store.personById(id)?.name).whereType<String>().firstOrNull);

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
            '${DateFormat('d MMM').format(expense.date)}${context_ != null ? ' • $context_' : ''}',
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

class _ActivitySettlementRow extends StatelessWidget {
  const _ActivitySettlementRow({required this.settlement});
  final Settlement settlement;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final fromName = settlement.fromId == kMeId ? 'You' : (store.personById(settlement.fromId)?.name ?? '—');
    final toName = settlement.toId == kMeId ? 'you' : (store.personById(settlement.toId)?.name ?? '—');

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
          title: Text('$fromName paid $toName', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat('d MMM yyyy').format(settlement.date)),
          trailing: Text(currency.format(settlement.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
