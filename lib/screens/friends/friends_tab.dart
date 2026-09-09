import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import 'friend_detail_screen.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  Future<void> _addFriend(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a friend'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      AppScope.of(context).addFriend(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final friends = store.friends;
    final overall = store.overallNetForMe();

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: friends.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                      child: Icon(Icons.person_add_alt_1, size: 44, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 20),
                    Text('No friends yet', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Add a friend to track what you owe each other, group or no group.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addFriend(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add a friend'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                if (overall.abs() > 0.005)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      overall > 0
                          ? 'Overall, you are owed ${currency.format(overall.abs())}'
                          : 'Overall, you owe ${currency.format(overall.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: overall > 0 ? kOwedColor : scheme.error,
                      ),
                    ),
                  ),
                for (final friend in friends)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: PersonAvatar(person: friend),
                        title: Text(friend.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: BalanceLabel(amount: store.friendBalance(friend.id)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FriendDetailScreen(friendId: friend.id)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFriend(context),
        icon: const Icon(Icons.add),
        label: const Text('Add friend'),
      ),
    );
  }
}
