import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/group_avatar.dart';
import '../../widgets/person_avatar.dart';
import '../groups/group_detail_screen.dart';
import '../settle/settle_up_screen.dart';

/// A read-only view of your balance with one teammate, aggregated across
/// every group you both belong to.
class FriendDetailScreen extends StatelessWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final friend = store.personById(friendId);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);

    if (friend == null) return const Scaffold(body: Center(child: Text('Friend not found')));

    final balance = store.friendBalance(friendId);
    final sharedGroups = store.groups.where((g) => g.memberIds.contains(friendId)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(friend.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                PersonAvatar(person: friend, radius: 32),
                const SizedBox(height: 12),
                Text(friend.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                BalanceLabel(amount: balance, large: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Shared groups', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final group in sharedGroups)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: GroupAvatar(group: group, size: 40),
                  title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    currency.format(store.pairBalanceInGroup(store.meId, friendId, group.id).abs()),
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SettleUpScreen(groupId: group.id)),
                    ),
                    child: const Text('Settle up'),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
