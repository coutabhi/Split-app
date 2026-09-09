import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/app_scope.dart';
import '../../utils/error_text.dart';
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
  bool _leaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    final store = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You\'ll stop seeing this group\'s expenses. Anyone with the invite code can add you back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _leaving = true);
    try {
      await store.leaveGroup(widget.groupId);
      if (mounted) {
        Navigator.of(context)
          ..pop()
          ..pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeError(e))));
      }
    }
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PersonAvatar(person: store.personById(id)!),
                title: Text(
                  id == store.meId ? '${store.personById(id)!.name} (you)' : store.personById(id)!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite code', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.inviteCode,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy_outlined),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: group.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                        },
                      ),
                      IconButton(
                        tooltip: 'Share',
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => Share.share(
                          'Join "${group.name}" on OfficeSplit — enter this invite code in the app: ${group.inviteCode}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _leaving ? null : _leave,
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error)),
            icon: const Icon(Icons.logout),
            label: const Text('Leave group'),
          ),
        ],
      ),
    );
  }
}
