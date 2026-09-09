import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Future<void> _renameMe(BuildContext context, Person me) async {
    final store = AppScope.of(context);
    final controller = TextEditingController(text: me.name);
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
    if (name != null && name.trim().isNotEmpty) {
      await store.renameMe(name);
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

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currencyScope = CurrencyScope.of(context);
    final me = store.personById(store.meId);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          if (me != null)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: PersonAvatar(person: me, radius: 22),
                title: Text(me.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                subtitle: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _renameMe(context, me),
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
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Groups and expenses sync live with your team through OfficeSplit\'s shared backend.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
