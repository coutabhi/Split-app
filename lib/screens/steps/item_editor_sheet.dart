import 'package:flutter/material.dart';

import '../../models/bill_item.dart';
import '../../models/person.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';

/// Bottom sheet used to add or edit a single ordered item, including who
/// it should be split between.
class ItemEditorSheet extends StatefulWidget {
  const ItemEditorSheet({super.key, required this.people, this.existing});

  final List<Person> people;
  final BillItem? existing;

  static Future<({String name, double price, Set<String> assigneeIds})?> show(
    BuildContext context, {
    required List<Person> people,
    BillItem? existing,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ItemEditorSheet(people: people, existing: existing),
    );
  }

  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _priceController =
      TextEditingController(text: widget.existing?.price.toStringAsFixed(2) ?? '');
  late Set<String> _selected = {...(widget.existing?.assigneeIds ?? {})};
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll() => setState(() => _selected = widget.people.map((p) => p.id).toSet());

  void _submit() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Give the item a name');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _error = 'Enter a valid price');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Pick who ordered this');
      return;
    }
    Navigator.pop(context, (name: name, price: price, assigneeIds: _selected));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'Add item' : 'Edit item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What was ordered',
                hintText: 'e.g. Paneer Tikka',
              ),
              autofocus: widget.existing == null,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: currency.symbol,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Split between', style: Theme.of(context).textTheme.titleSmall),
                TextButton(onPressed: _selectAll, child: const Text('Select all')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.people.map((p) {
                final selected = _selected.contains(p.id);
                return GestureDetector(
                  onTap: () => _toggle(p.id),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 40,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? p.color.withValues(alpha: 0.16) : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? p.color : scheme.outlineVariant,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonAvatar(person: p, radius: 12, selected: selected, showCheck: true),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.existing == null ? 'Add item' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
