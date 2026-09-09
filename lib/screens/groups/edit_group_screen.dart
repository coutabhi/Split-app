import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../widgets/person_avatar.dart';

class EditGroupScreen extends StatefulWidget {
  const EditGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late final _nameController = TextEditingController(
    text: AppScope.of(context).groupById(widget.groupId)?.name ?? '',
  );
  final _friendController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _friendController.dispose();
    super.dispose();
  }

  void _addFriend() {
    final name = _friendController.text.trim();
    if (name.isEmpty) return;
    final store = AppScope.of(context);
    final group = store.groupById(widget.groupId);
    if (group == null) return;
    final person = store.addFriend(name);
    store.updateGroupMembers(widget.groupId, [...group.memberIds, person.id]);
    _friendController.clear();
    setState(() {});
  }

  Future<void> _delete() async {
    final store = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete group?'),
        content: const Text('This removes the group and its expense history. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = store.deleteGroup(widget.groupId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final group = store.groupById(widget.groupId);
    final scheme = Theme.of(context).colorScheme;

    if (group == null) {
      return const Scaffold(body: Center(child: Text('Group not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Group settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Group name'),
            onChanged: (v) => store.renameGroup(widget.groupId, v),
          ),
          const SizedBox(height: 24),
          Text('People', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final id in group.memberIds)
            if (store.personById(id) != null)
              _MemberTile(
                person: store.personById(id)!,
                isMe: id == kMeId,
                onRemove: id == kMeId
                    ? null
                    : () => store.updateGroupMembers(
                          widget.groupId,
                          group.memberIds.where((m) => m != id).toList(),
                        ),
              ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _friendController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Add a person'),
                  onSubmitted: (_) => _addFriend(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _addFriend,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete group'),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.person, required this.isMe, this.onRemove});

  final Person person;
  final bool isMe;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PersonAvatar(person: person),
      title: Text(isMe ? '${person.name} (you)' : person.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onRemove == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}
