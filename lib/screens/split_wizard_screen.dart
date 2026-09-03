import 'package:flutter/material.dart';

import '../editor/bill_editor.dart';
import '../services/bill_store.dart';
import 'steps/charges_step.dart';
import 'steps/items_step.dart';
import 'steps/people_step.dart';
import 'summary_screen.dart';

const _stepTitles = ['People', 'Items', 'Charges'];

class SplitWizardScreen extends StatefulWidget {
  const SplitWizardScreen({super.key, required this.editor, required this.store});

  final BillEditor editor;
  final BillStore store;

  @override
  State<SplitWizardScreen> createState() => _SplitWizardScreenState();
}

class _SplitWizardScreenState extends State<SplitWizardScreen> {
  int _step = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    widget.editor.addListener(_onEditorChanged);
  }

  void _onEditorChanged() => widget.store.saveDraft(widget.editor.bill);

  @override
  void dispose() {
    widget.editor.removeListener(_onEditorChanged);
    _pageController.dispose();
    super.dispose();
  }

  String? get _blockReason {
    final bill = widget.editor.bill;
    if (_step == 0) {
      if (bill.people.length < 2) return 'Add at least 2 people';
      if (bill.payerId == null) return 'Mark who paid the bill';
    } else if (_step == 1) {
      if (bill.items.isEmpty) return 'Add at least 1 item';
      if (bill.unassignedItems.isNotEmpty) return 'Assign every item to someone';
    }
    return null;
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    final reason = _blockReason;
    if (reason != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(reason)));
      return;
    }
    if (_step < _stepTitles.length - 1) {
      _goTo(_step + 1);
    } else {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(editor: widget.editor, store: widget.store),
        ),
      );
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New split'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(false),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(_stepTitles.length, (i) {
                final active = i <= _step;
                return Expanded(
                  child: GestureDetector(
                    onTap: i < _step ? () => _goTo(i) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 4,
                            decoration: BoxDecoration(
                              color: active ? scheme.primary : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _stepTitles[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                              color: active ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PeopleStep(editor: widget.editor),
                ItemsStep(editor: widget.editor),
                ChargesStep(editor: widget.editor),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goTo(_step - 1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_step == _stepTitles.length - 1 ? 'See summary' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
