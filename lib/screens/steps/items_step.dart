import 'package:flutter/material.dart';

import '../../editor/bill_editor.dart';
import '../../models/bill_item.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import 'item_editor_sheet.dart';

class ItemsStep extends StatelessWidget {
  const ItemsStep({super.key, required this.editor});

  final BillEditor editor;

  Future<void> _addItem(BuildContext context) async {
    final result = await ItemEditorSheet.show(context, people: editor.bill.people);
    if (result != null) {
      editor.addItem(result.name, result.price, result.assigneeIds);
    }
  }

  Future<void> _editItem(BuildContext context, BillItem item) async {
    final result = await ItemEditorSheet.show(
      context,
      people: editor.bill.people,
      existing: item,
    );
    if (result != null) {
      editor.updateItem(
        item.id,
        name: result.name,
        price: result.price,
        assigneeIds: result.assigneeIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);

    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final bill = editor.bill;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                Text('What did everyone order?', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Add each item and tap who it belongs to.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                if (bill.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No items yet', style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                else ...[
                  for (final item in bill.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => editor.removeItem(item.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                        ),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            onTap: () => _editItem(context, item),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: item.assigneeIds.isEmpty
                                ? Text('Unassigned', style: TextStyle(color: scheme.error))
                                : Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: -6,
                                      children: [
                                        for (final id in item.assigneeIds)
                                          Builder(builder: (context) {
                                            final p = bill.people.where((p) => p.id == id).firstOrNull;
                                            if (p == null) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: PersonAvatar(person: p, radius: 11),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                            trailing: Text(
                              currency.format(item.price),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        currency.format(bill.subtotal),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _addItem(context),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
