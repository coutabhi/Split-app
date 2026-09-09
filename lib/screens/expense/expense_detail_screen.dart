import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../utils/category_icons.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import 'add_expense_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final expense = store.expenses.where((e) => e.id == expenseId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);

    if (expense == null) {
      return const Scaffold(body: Center(child: Text('Expense not found')));
    }

    final payer = store.personById(expense.paidById);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddExpenseScreen(groupId: expense.groupId, existing: expense),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete expense?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) {
                store.deleteExpense(expenseId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(categoryIcon(expense.category), color: scheme.onPrimaryContainer, size: 26),
                ),
                const SizedBox(height: 12),
                Text(expense.description, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(DateFormat('EEE, d MMM yyyy').format(expense.date), style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                Text(currency.format(expense.amount), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                Text(
                  '${expense.paidById == kMeId ? 'You' : payer?.name ?? '—'} paid',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Split', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final id in expense.participantIds)
            if (store.personById(id) != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: PersonAvatar(person: store.personById(id)!),
                    title: Text(
                      id == kMeId ? 'You' : store.personById(id)!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      currency.format(expense.shareOf(id)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
