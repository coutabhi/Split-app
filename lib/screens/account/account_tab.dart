import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Future<void> _renameMe(BuildContext context) async {
    final store = AppScope.of(context);
    final controller = TextEditingController(text: store.me.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      store.renamePerson(kMeId, name);
    }
  }

  void _pickCurrency(BuildContext context, String current, ValueChanged<String> onPicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currencyScope = CurrencyScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: PersonAvatar(person: store.me, radius: 22),
              title: Text(store.me.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              subtitle: const Text('This is you'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _renameMe(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Currency'),
              trailing: Text(currencyScope.symbol, style: const TextStyle(fontSize: 18)),
              onTap: () => _pickCurrency(context, currencyScope.symbol, currencyScope.setSymbol),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'OfficeSplit keeps everything on this device only — nothing is synced to the cloud, so balances are only visible here.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
