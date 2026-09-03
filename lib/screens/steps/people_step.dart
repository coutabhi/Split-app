import 'package:flutter/material.dart';

import '../../editor/bill_editor.dart';
import '../../models/person.dart';
import '../../widgets/person_avatar.dart';

class PeopleStep extends StatefulWidget {
  const PeopleStep({super.key, required this.editor});

  final BillEditor editor;

  @override
  State<PeopleStep> createState() => _PeopleStepState();
}

class _PeopleStepState extends State<PeopleStep> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.editor.addPerson(name);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.editor.bill;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.editor,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Text('Who\'s splitting this?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add everyone in the office who ordered something.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'e.g. Priya'),
                    onSubmitted: (_) => _addPerson(),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _addPerson,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (bill.people.isEmpty)
              _EmptyState(color: scheme.onSurfaceVariant)
            else ...[
              Text(
                '${bill.people.length} ${bill.people.length == 1 ? "person" : "people"}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              ...bill.people.map((p) => _PersonTile(
                    person: p,
                    isPayer: bill.payerId == p.id,
                    onSetPayer: () => widget.editor.setPayer(p.id),
                    onRemove: () => widget.editor.removePerson(p.id),
                    onRename: (name) => widget.editor.renamePerson(p.id, name),
                  )),
              const SizedBox(height: 8),
              Card(
                color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tap the crown to mark who paid the bill.',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, size: 56, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text('Nobody added yet', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.isPayer,
    required this.onSetPayer,
    required this.onRemove,
    required this.onRename,
  });

  final Person person;
  final bool isPayer;
  final VoidCallback onSetPayer;
  final VoidCallback onRemove;
  final ValueChanged<String> onRename;

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: person.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) onRename(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: PersonAvatar(person: person),
          title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: isPayer
              ? Text('Paid the bill', style: TextStyle(color: scheme.primary, fontSize: 12))
              : null,
          onTap: () => _rename(context),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Mark as payer',
                icon: Icon(
                  isPayer ? Icons.emoji_events : Icons.emoji_events_outlined,
                  color: isPayer ? scheme.primary : scheme.onSurfaceVariant,
                ),
                onPressed: onSetPayer,
              ),
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
