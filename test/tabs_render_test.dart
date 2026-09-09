import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:officesplit/screens/root_shell.dart';
import 'package:officesplit/state/app_scope.dart';
import 'package:officesplit/state/app_store.dart';
import 'package:officesplit/widgets/currency_scope.dart';

/// Renders the shell with an empty store. Layout overflows throw in tests,
/// so this catches the kind of "broken UI" regression that only shows up
/// once a widget is actually laid out.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });

  Widget wrap(Widget child, AppStore store) => CurrencyScope(
        symbol: '₹',
        setSymbol: (_) {},
        child: AppScope(
          store: store,
          child: MaterialApp(home: child),
        ),
      );

  testWidgets('every tab renders without layout errors', (tester) async {
    final store = AppStore(Supabase.instance.client);
    await tester.pumpWidget(wrap(const RootShell(), store));
    await tester.pump();

    expect(find.text('Groups'), findsWidgets);

    for (final tab in ['Friends', 'Activity', 'Account']) {
      await tester.tap(find.text(tab).last);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$tab tab should render cleanly');
    }
  });

  testWidgets('the empty Groups tab can be pulled to refresh', (tester) async {
    final store = AppStore(Supabase.instance.client);
    await tester.pumpWidget(wrap(const RootShell(), store));
    await tester.pump();

    // The empty state has to sit inside a scrollable for pull-to-refresh to
    // work at all.
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
