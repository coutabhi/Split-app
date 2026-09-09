import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../state/app_scope.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/person_avatar.dart';
import 'friend_detail_screen.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final currency = CurrencyScope.of(context);
    final balances = store.friendBalances();
    final friends = balances.keys.map((id) => store.personById(id)).whereType<Person>().toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
                      child: Icon(Icons.people_outline, size: 44, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 20),
                    Text('No shared groups yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Anyone who joins one of your groups shows up here with a running balance.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                        trailing: BalanceLabel(amount: balances[friend.id]!),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FriendDetailScreen(friendId: friend.id)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
