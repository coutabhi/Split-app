import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:officesplit/main.dart';
import 'package:officesplit/screens/groups/create_group_screen.dart';
import 'package:officesplit/state/app_scope.dart';
import 'package:officesplit/state/app_store.dart';
import 'package:officesplit/widgets/currency_scope.dart';

/// Pushed routes are built by the Navigator inside MaterialApp, so anything
/// the app provides through an InheritedWidget has to sit *above*
/// MaterialApp or those routes can't see it.
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

  testWidgets('AppScope resolves from a route pushed on the root navigator', (tester) async {
    final store = AppStore(Supabase.instance.client);
    Object? thrown;

    await tester.pumpWidget(
      AppScope(
        store: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Builder(builder: (routeContext) {
                    try {
                      AppScope.of(routeContext);
                    } catch (e) {
                      thrown = e;
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ),
              child: const Text('push'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    expect(thrown, isNull, reason: 'a pushed route must still see the AppScope');
  });

  testWidgets('tapping Create group reaches the store rather than crashing on lookup', (tester) async {
    final store = AppStore(Supabase.instance.client);

    await tester.pumpWidget(
      CurrencyScope(
        symbol: '₹',
        setSymbol: (_) {},
        child: AppScope(
          store: store,
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Office');
    await tester.tap(find.text('Create group'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Offline in tests, so saving fails either way - but it must fail on the
    // store call, never on the inherited-widget lookup that reaches it.
    expect(find.textContaining('Null check operator'), findsNothing);
    expect(find.textContaining('No AppScope found'), findsNothing);
  });

  testWidgets('the app puts AppScope above MaterialApp', (tester) async {
    await tester.pumpWidget(const OfficeSplitApp());
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: find.byType(MaterialApp), matching: find.byType(AppScope)),
      findsOneWidget,
      reason: 'AppScope must wrap MaterialApp so pushed routes inherit it',
    );
  });
}
