import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:officesplit/main.dart';

void main() {
  testWidgets('App launches to the Groups tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OfficeSplitApp());
    await tester.pumpAndSettle();

    expect(find.text('Groups'), findsWidgets);
    expect(find.text('Start a group'), findsWidgets);
  });
}
