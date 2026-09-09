import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../widgets/person_avatar.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  final Set<String> _selected = {};
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _friendController.dispose();
    super.dispose();
  }

  void _addFriend(BuildContext context) {
    final name = _friendController.text.trim();
    if (name.isEmpty) return;
    final store = AppScope.of(context);
    final person = store.addFriend(name);
    _friendController.clear();
    setState(() => _selected.add(person.id));
  }

  void _create(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the group a name');
      return;
    }
    final store = AppScope.of(context);
    final group = store.addGroup(name, _selected.toList());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final friends = store.friends;

    return Scaffold(
      appBar: AppBar(title: const Text('New group')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Group name', hintText: 'e.g. Office'),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Text('Add people', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _friendController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Friend\'s name'),
                  onSubmitted: (_) => _addFriend(context),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => _addFriend(context),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No friends yet — add one above.', style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ...friends.map((p) {
              final selected = _selected.contains(p.id);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(p.id);
                  } else {
                    _selected.remove(p.id);
                  }
                }),
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: PersonAvatar(person: p),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => _create(context), child: const Text('Create group')),
          ),
        ),
      ),
    );
  }
}
