import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../editor/bill_editor.dart';
import '../models/bill.dart';
import '../services/bill_store.dart';
import '../widgets/currency_scope.dart';
import '../widgets/person_avatar.dart';
import 'split_wizard_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final BillStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Bill> _history = [];
  Bill? _draft;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await widget.store.loadHistory();
    final draft = await widget.store.loadDraft();
    if (!mounted) return;
    setState(() {
      _history = history;
      _draft = (draft != null && draft.people.isNotEmpty) ? draft : null;
      _loading = false;
    });
  }

  Future<void> _startNew({Bill? resume}) async {
    final editor = BillEditor(resume);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SplitWizardScreen(editor: editor, store: widget.store),
      ),
    );
    if (saved != true) {
      await widget.store.saveDraft(editor.bill.people.isEmpty ? null : editor.bill);
    }
    _load();
  }

  Future<void> _openHistory(Bill bill) async {
    final editor = BillEditor(bill);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SummaryScreen(editor: editor, store: widget.store, readOnly: true),
      ),
    );
  }

  Future<void> _deleteHistory(Bill bill) async {
    await widget.store.deleteFromHistory(bill.id);
    _load();
  }

  void _pickCurrency(String current, ValueChanged<String> onPicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Currency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final symbol in const ['₹', '\$', '€', '£', '¥'])
              ListTile(
                title: Text(symbol, style: const TextStyle(fontSize: 18)),
                trailing: symbol == current ? const Icon(Icons.check) : null,
                onTap: () {
                  onPicked(symbol);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currencyScope = CurrencyScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OfficeSplit'),
        actions: [
          TextButton.icon(
            onPressed: () => _pickCurrency(currencyScope.symbol, currencyScope.setSymbol),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(currencyScope.symbol),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  if (_draft != null) ...[
                    Card(
                      color: scheme.secondaryContainer,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Icon(Icons.edit_note, color: scheme.onSecondaryContainer),
                        title: Text(
                          _draft!.title.isEmpty ? 'Unfinished split' : _draft!.title,
                          style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Tap to continue • ${_draft!.people.length} people',
                          style: TextStyle(color: scheme.onSecondaryContainer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.arrow_forward, color: scheme.onSecondaryContainer),
                        onTap: () => _startNew(resume: _draft),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_history.isEmpty && _draft == null)
                    _EmptyHome(onStart: () => _startNew())
                  else ...[
                    Text('Past splits', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final bill in _history)
                      Dismissible(
                        key: ValueKey(bill.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteHistory(bill),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              onTap: () => _openHistory(bill),
                              title: Text(
                                bill.title.isEmpty ? 'Untitled split' : bill.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${DateFormat('d MMM yyyy').format(bill.date)} • ${bill.people.length} people',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: SizedBox(
                                width: 84,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyScope.format(bill.grandTotal),
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      height: 20,
                                      width: 20 + (bill.people.length.clamp(1, 4) - 1) * 14.0,
                                      child: Stack(
                                        children: [
                                          for (var i = 0; i < bill.people.length.clamp(0, 4); i++)
                                            Positioned(
                                              right: i * 14.0,
                                              child: PersonAvatar(person: bill.people[i], radius: 10),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startNew(),
        icon: const Icon(Icons.add),
        label: const Text('New split'),
      ),
    );
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long, size: 44, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text(
            'Split lunch the fair way',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Everyone pays for exactly what they ordered — not an equal share.',
            style: TextStyle(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.add),
            label: const Text('Start your first split'),
          ),
        ],
      ),
    );
  }
}
