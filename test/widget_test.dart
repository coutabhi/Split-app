import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:officesplit/main.dart';

void main() {
  testWidgets('App launches to the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OfficeSplitApp());
    await tester.pumpAndSettle();

    expect(find.text('OfficeSplit'), findsWidgets);
    expect(find.text('New split'), findsOneWidget);
  });
}
