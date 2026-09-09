import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import 'group_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the group a name');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final group = await AppScope.of(context).createGroup(name);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not create the group. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'ll get an invite code to share with colleagues right after — they join with it and see the group\'s balances live.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
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
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create group'),
            ),
          ),
        ),
      ),
    );
  }
}
