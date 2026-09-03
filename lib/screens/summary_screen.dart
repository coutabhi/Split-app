import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../editor/bill_editor.dart';
import '../models/bill.dart';
import '../models/person.dart';
import '../services/bill_store.dart';
import '../widgets/currency_scope.dart';
import '../widgets/person_avatar.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.editor, required this.store, this.readOnly = false});

  final BillEditor editor;
  final BillStore store;
  final bool readOnly;

  String _shareText(BuildContext context) {
    final bill = editor.bill;
    final currency = CurrencyScope.of(context);
    final payer = bill.payer;
    final buffer = StringBuffer();
    buffer.writeln('🧾 ${bill.title.isEmpty ? "Split" : bill.title}');
    buffer.writeln(DateFormat('EEE, d MMM yyyy').format(bill.date));
    buffer.writeln('');
    for (final p in bill.people) {
      final items = bill.itemsFor(p.id);
      final total = bill.totalFor(p.id);
      buffer.writeln('${p.name} — ${currency.format(total)}');
      for (final item in items) {
        final share = item.sharePerAssignee;
        final label = item.assigneeIds.length > 1
            ? '${item.name} (split ${item.assigneeIds.length}-way)'
            : item.name;
        buffer.writeln('   • $label: ${currency.format(share)}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Subtotal: ${currency.format(bill.subtotal)}');
    if (bill.taxAmount > 0) buffer.writeln('Tax: ${currency.format(bill.taxAmount)}');
    if (bill.tipAmount > 0) buffer.writeln('Tip: ${currency.format(bill.tipAmount)}');
    if (bill.otherCharges > 0) buffer.writeln('Other: ${currency.format(bill.otherCharges)}');
    buffer.writeln('Grand total: ${currency.format(bill.grandTotal)}');
    if (payer != null) {
      buffer.writeln('');
      buffer.writeln('💳 ${payer.name} paid. Everyone else owes ${payer.name}:');
      for (final p in bill.people) {
        if (p.id == payer.id) continue;
        buffer.writeln('   ${p.name} → ${currency.format(bill.totalFor(p.id))}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Split with OfficeSplit');
    return buffer.toString();
  }

  Future<void> _save(BuildContext context) async {
    await store.saveToHistory(editor.bill);
    await store.saveDraft(null);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Split saved')));
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = editor.bill;
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final payer = bill.payer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.share(_shareText(context), subject: bill.title),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  bill.title.isEmpty ? 'Untitled split' : bill.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, d MMM yyyy').format(bill.date),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  currency.format(bill.grandTotal),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                ),
                Text('grand total', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Who owes what', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final p in bill.people) _PersonBreakdown(bill: bill, person: p, isPayer: p.id == bill.payerId),
          if (payer != null) ...[
            const SizedBox(height: 20),
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: scheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${payer.name} paid ${currency.format(bill.grandTotal)}',
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final p in bill.people)
                      if (p.id != payer.id)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '${p.name} owes ${payer.name} ${currency.format(bill.totalFor(p.id))}',
                            style: TextStyle(color: scheme.onPrimaryContainer),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Share.share(_shareText(context), subject: bill.title),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => _save(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Save split'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PersonBreakdown extends StatefulWidget {
  const _PersonBreakdown({required this.bill, required this.person, required this.isPayer});

  final Bill bill;
  final Person person;
  final bool isPayer;

  @override
  State<_PersonBreakdown> createState() => _PersonBreakdownState();
}

class _PersonBreakdownState extends State<_PersonBreakdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final items = widget.bill.itemsFor(widget.person.id);
    final total = widget.bill.totalFor(widget.person.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PersonAvatar(person: widget.person),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.person.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isPayer) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.emoji_events, size: 16, color: scheme.primary),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      currency.format(total),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: scheme.onSurfaceVariant),
                  ],
                ),
                if (_expanded) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                  if (items.isEmpty)
                    Text('No items', style: TextStyle(color: scheme.onSurfaceVariant))
                  else
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.assigneeIds.length > 1
                                    ? '${item.name} (÷${item.assigneeIds.length})'
                                    : item.name,
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                            Text(
                              currency.format(item.sharePerAssignee),
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  if (widget.bill.extraCharges > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Tax, tip & other', style: TextStyle(color: scheme.onSurfaceVariant)),
                          ),
                          Text(
                            currency.format(total - widget.bill.subtotalFor(widget.person.id)),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
