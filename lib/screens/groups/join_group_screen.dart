import 'package:flutter/material.dart';

import '../../state/app_scope.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the invite code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppScope.of(context).joinGroupByCode(code);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Join a group')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(
            'Ask whoever started the group for their invite code.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Invite code', hintText: 'e.g. OFC-4X9'),
            autofocus: true,
            onSubmitted: (_) => _join(),
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
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Join group'),
            ),
          ),
        ),
      ),
    );
  }
}
