import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:officesplit/main.dart';

void main() {
  testWidgets('Signed-out app shows the sign-in screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
    await tester.pumpWidget(const OfficeSplitApp());
    await tester.pumpAndSettle();

    expect(find.text('OfficeSplit'), findsWidgets);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
