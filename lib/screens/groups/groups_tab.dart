import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../widgets/balance_label.dart';
import '../../widgets/currency_scope.dart';
import '../../widgets/group_avatar.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'join_group_screen.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final overall = store.overallNetForMe();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            tooltip: 'Join a group',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinGroupScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: store.refresh,
        child: store.groups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _EmptyGroups(onCreate: () => _createGroup(context), onJoin: () => _joinGroup(context)),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (overall.abs() > 0.005)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          overall > 0 ? Icons.trending_up : Icons.trending_down,
                          color: overall > 0 ? kOwedColor : scheme.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: scheme.onSurface, fontSize: 15),
                              children: [
                                TextSpan(text: overall > 0 ? 'Overall, you are owed ' : 'Overall, you owe '),
                                TextSpan(
                                  text: CurrencyScopeAmount.of(context, overall.abs()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: overall > 0 ? kOwedColor : scheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final group in store.groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: GroupAvatar(group: group),
                        title: Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${group.memberIds.length} people'),
                        trailing: BalanceLabel(amount: store.groupNetForMe(group.id)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGroup(context),
        icon: const Icon(Icons.add),
        label: const Text('Start a group'),
      ),
    );
  }

  void _createGroup(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
  }

  void _joinGroup(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JoinGroupScreen()));
  }
}

/// Small helper so we can format a currency amount inside a TextSpan
/// without pulling the whole widget in.
class CurrencyScopeAmount {
  static String of(BuildContext context, num amount) => CurrencyScope.of(context).format(amount);
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups({required this.onCreate, required this.onJoin});
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.groups, size: 44, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text('No groups yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Start a group for your office, a trip, or roommates and track shared expenses over time.',
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Start a group')),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: onJoin, icon: const Icon(Icons.group_add_outlined), label: const Text('Join a group with a code')),
          ],
        ),
      ),
    );
  }
}
