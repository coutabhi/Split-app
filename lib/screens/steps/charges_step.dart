import 'package:flutter/material.dart';

import '../../editor/bill_editor.dart';
import '../../widgets/currency_scope.dart';

class ChargesStep extends StatefulWidget {
  const ChargesStep({super.key, required this.editor});

  final BillEditor editor;

  @override
  State<ChargesStep> createState() => _ChargesStepState();
}

class _ChargesStepState extends State<ChargesStep> {
  late final _titleController = TextEditingController(text: widget.editor.bill.title);
  late final _taxController =
      TextEditingController(text: _fmt(widget.editor.bill.taxPercent));
  late final _tipController =
      TextEditingController(text: _fmt(widget.editor.bill.tipPercent));
  late final _otherController =
      TextEditingController(text: _fmt(widget.editor.bill.otherCharges));

  static String _fmt(double v) => v == 0 ? '' : (v % 1 == 0 ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    _titleController.dispose();
    _taxController.dispose();
    _tipController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final editor = widget.editor;

    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) {
        final bill = editor.bill;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Any extra charges?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Tax and tip are shared based on how much each person ordered.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Split title',
                hintText: 'e.g. Friday team lunch',
              ),
              onChanged: editor.setTitle,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tax %', suffixText: '%'),
                    onChanged: (v) => editor.setTaxPercent(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tipController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Tip %', suffixText: '%'),
                    onChanged: (v) => editor.setTipPercent(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _otherController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Other charges (delivery, packaging...)',
                prefixText: currency.symbol,
              ),
              onChanged: (v) => editor.setOtherCharges(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: currency.format(bill.subtotal)),
                    if (bill.taxAmount > 0)
                      _SummaryRow(label: 'Tax', value: currency.format(bill.taxAmount)),
                    if (bill.tipAmount > 0)
                      _SummaryRow(label: 'Tip', value: currency.format(bill.tipAmount)),
                    if (bill.otherCharges > 0)
                      _SummaryRow(label: 'Other', value: currency.format(bill.otherCharges)),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                    _SummaryRow(
                      label: 'Grand total',
                      value: currency.format(bill.grandTotal),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      fontSize: bold ? 17 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
