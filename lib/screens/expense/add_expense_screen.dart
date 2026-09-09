import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/bill_item.dart';
import '../../models/expense.dart';
import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../utils/category_icons.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import '../steps/item_editor_sheet.dart';

const _uuid = Uuid();

/// Add or edit an expense in [groupId]. Pass [existing] to edit.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId, this.existing});

  final String groupId;
  final Expense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late final _descController = TextEditingController(text: widget.existing?.description ?? '');
  late final _amountController = TextEditingController(
    text: widget.existing == null ? '' : _trimZeros(widget.existing!.amount),
  );

  late SplitType _splitType = widget.existing?.splitType ?? SplitType.equal;
  late String _paidById = widget.existing?.paidById ?? AppScope.of(context).meId;
  late ExpenseCategory _category = widget.existing?.category ?? ExpenseCategory.general;
  late final Set<String> _participants = {...(widget.existing?.participantIds ?? _pool)};
  late final List<BillItem> _items = [...(widget.existing?.items ?? [])];

  final Map<String, TextEditingController> _exactControllers = {};
  final Map<String, TextEditingController> _percentControllers = {};
  String? _error;
  bool _saving = false;

  List<String> get _pool => AppScope.of(context).groupById(widget.groupId)?.memberIds ?? [];

  static String _trimZeros(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  TextEditingController _exactCtrl(String id) => _exactControllers.putIfAbsent(
        id,
        () => TextEditingController(
          text: widget.existing?.splitType == SplitType.exact
              ? _trimZeros(widget.existing!.shareOf(id))
              : '',
        ),
      );

  TextEditingController _percentCtrl(String id) => _percentControllers.putIfAbsent(
        id,
        () {
          final existingShare = widget.existing?.splitType == SplitType.percent && widget.existing!.amount > 0
              ? widget.existing!.shareOf(id) / widget.existing!.amount * 100
              : null;
          return TextEditingController(text: existingShare == null ? '' : _trimZeros(existingShare));
        },
      );

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    for (final c in _percentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _itemsTotal => _items.fold(0.0, (s, i) => s + i.price);

  Map<String, double> _computeShares() {
    switch (_splitType) {
      case SplitType.equal:
        if (_participants.isEmpty) return {};
        final n = _participants.length;
        final base = (_amount / n * 100).floor() / 100;
        final remainder = _amount - base * n;
        final ids = _participants.toList();
        final shares = <String, double>{};
        for (var i = 0; i < ids.length; i++) {
          shares[ids[i]] = base + (i == ids.length - 1 ? remainder : 0);
        }
        return shares;
      case SplitType.exact:
        return {
          for (final id in _participants) id: double.tryParse(_exactCtrl(id).text.trim()) ?? 0,
        };
      case SplitType.percent:
        return {
          for (final id in _participants)
            id: _amount * (double.tryParse(_percentCtrl(id).text.trim()) ?? 0) / 100,
        };
      case SplitType.items:
        final shares = <String, double>{};
        for (final item in _items) {
          final share = item.sharePerAssignee;
          for (final id in item.assigneeIds) {
            shares[id] = (shares[id] ?? 0) + share;
          }
        }
        return shares;
    }
  }

  Future<void> _addItem() async {
    final store = AppScope.of(context);
    final poolPeople = _pool.map((id) => store.personById(id)).whereType<Person>().toList();
    final result = await ItemEditorSheet.show(context, people: poolPeople);
    if (result != null) {
      setState(() {
        _items.add(BillItem(id: _uuid.v4(), name: result.name, price: result.price, assigneeIds: result.assigneeIds));
        _amountController.text = _trimZeros(_itemsTotal);
      });
    }
  }

  Future<void> _editItem(BillItem item) async {
    final store = AppScope.of(context);
    final poolPeople = _pool.map((id) => store.personById(id)).whereType<Person>().toList();
    final result = await ItemEditorSheet.show(context, people: poolPeople, existing: item);
    if (result != null) {
      setState(() {
        item
          ..name = result.name
          ..price = result.price
          ..assigneeIds = result.assigneeIds;
        _amountController.text = _trimZeros(_itemsTotal);
      });
    }
  }

  void _removeItem(BillItem item) {
    setState(() {
      _items.remove(item);
      _amountController.text = _trimZeros(_itemsTotal);
    });
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      setState(() => _error = 'Give the expense a description');
      return;
    }
    if (_splitType == SplitType.items) {
      if (_items.isEmpty) {
        setState(() => _error = 'Add at least one item');
        return;
      }
    } else if (_amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (_splitType != SplitType.items && _participants.isEmpty) {
      setState(() => _error = 'Pick who this is split between');
      return;
    }

    final shares = _computeShares();
    final amount = _splitType == SplitType.items ? _itemsTotal : _amount;
    final participantIds = _splitType == SplitType.items ? shares.keys.toList() : _participants.toList();

    if (_splitType == SplitType.exact) {
      final sum = shares.values.fold(0.0, (a, b) => a + b);
      if ((sum - amount).abs() > 0.01) {
        setState(() => _error = 'Amounts must add up to the total (${(amount - sum).abs().toStringAsFixed(2)} left)');
        return;
      }
    }
    if (_splitType == SplitType.percent) {
      final sumPct = _participants.fold(
          0.0, (a, id) => a + (double.tryParse(_percentCtrl(id).text.trim()) ?? 0));
      if ((sumPct - 100).abs() > 0.5) {
        setState(() => _error = 'Percentages must add up to 100% (currently ${sumPct.toStringAsFixed(0)}%)');
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final store = AppScope.of(context);
    try {
      if (widget.existing != null) {
        widget.existing!
          ..description = desc
          ..amount = amount
          ..paidById = _paidById
          ..splitType = _splitType
          ..shares = shares
          ..participantIds = participantIds
          ..category = _category
          ..items = _items;
        await store.updateExpense(widget.existing!);
      } else {
        await store.addExpense(
          groupId: widget.groupId,
          description: desc,
          amount: amount,
          paidById: _paidById,
          splitType: _splitType,
          shares: shares,
          participantIds: participantIds,
          category: _category,
          items: _items,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final pool = _pool.map((id) => store.personById(id)).whereType<Person>().toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add expense' : 'Edit expense')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Team lunch'),
            autofocus: widget.existing == null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  enabled: _splitType != SplitType.items,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: currency.symbol,
                    helperText: _splitType == SplitType.items ? 'Set by your items below' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              _CategoryPicker(value: _category, onChanged: (c) => setState(() => _category = c)),
            ],
          ),
          const SizedBox(height: 20),
          Text('Paid by', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: pool.map((p) {
              final selected = _paidById == p.id;
              return _Choice(
                selected: selected,
                onTap: () => setState(() => _paidById = p.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PersonAvatar(person: p, radius: 12),
                    const SizedBox(width: 8),
                    Text(p.id == store.meId ? 'You' : p.name),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Split', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<SplitType>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: SplitType.equal, label: Text('Equal', softWrap: false)),
                ButtonSegment(value: SplitType.exact, label: Text('Unequal', softWrap: false)),
                ButtonSegment(value: SplitType.percent, label: Text('%', softWrap: false)),
                ButtonSegment(value: SplitType.items, label: Text('Items', softWrap: false)),
              ],
              selected: {_splitType},
              onSelectionChanged: (s) => setState(() => _splitType = s.first),
            ),
          ),
          const SizedBox(height: 16),
          if (_splitType == SplitType.items)
            _ItemsEditor(items: _items, onAdd: _addItem, onEdit: _editItem, onRemove: _removeItem)
          else
            _ParticipantsEditor(
              splitType: _splitType,
              pool: pool,
              meId: store.meId,
              participants: _participants,
              amount: _amount,
              onToggle: (id) => setState(() {
                if (_participants.contains(id)) {
                  _participants.remove(id);
                } else {
                  _participants.add(id);
                }
              }),
              exactCtrl: _exactCtrl,
              percentCtrl: _percentCtrl,
              onChanged: () => setState(() {}),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.6 : 1),
        ),
        child: DefaultTextStyle(
          style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
          child: child,
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.value, required this.onChanged});
  final ExpenseCategory value;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showModalBottomSheet<ExpenseCategory>(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => SafeArea(
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                for (final c in ExpenseCategory.values)
                  ListTile(
                    leading: Icon(categoryIcon(c)),
                    title: Text(categoryLabel(c)),
                    trailing: c == value ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Icon(categoryIcon(value), color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _ParticipantsEditor extends StatelessWidget {
  const _ParticipantsEditor({
    required this.splitType,
    required this.pool,
    required this.meId,
    required this.participants,
    required this.amount,
    required this.onToggle,
    required this.exactCtrl,
    required this.percentCtrl,
    required this.onChanged,
  });

  final SplitType splitType;
  final List<Person> pool;
  final String meId;
  final Set<String> participants;
  final double amount;
  final ValueChanged<String> onToggle;
  final TextEditingController Function(String) exactCtrl;
  final TextEditingController Function(String) percentCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final n = participants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split between', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final p in pool)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Checkbox(
                  value: participants.contains(p.id),
                  onChanged: (_) => onToggle(p.id),
                ),
                PersonAvatar(person: p, radius: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.id == meId ? 'You' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!participants.contains(p.id))
                  const SizedBox.shrink()
                else if (splitType == SplitType.equal)
                  Text(
                    n == 0 ? '' : currency.format(amount / n),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                else if (splitType == SplitType.exact)
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: exactCtrl(p.id),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(prefixText: currency.symbol, isDense: true),
                      onChanged: (_) => onChanged(),
                    ),
                  )
                else if (splitType == SplitType.percent)
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: percentCtrl(p.id),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(suffixText: '%', isDense: true),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ItemsEditor extends StatelessWidget {
  const _ItemsEditor({required this.items, required this.onAdd, required this.onEdit, required this.onRemove});

  final List<BillItem> items;
  final VoidCallback onAdd;
  final ValueChanged<BillItem> onEdit;
  final ValueChanged<BillItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                onTap: () => onEdit(item),
                title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Split ${item.assigneeIds.length} way${item.assigneeIds.length == 1 ? '' : 's'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.format(item.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                      onPressed: () => onRemove(item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add item')),
      ],
    );
  }
}
