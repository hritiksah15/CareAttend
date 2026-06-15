import 'package:flutter_test/flutter_test.dart';

import 'package:care_attend_app/main.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CareAttendApp());
    await tester.pump();
    expect(find.text('Care Attend'), findsWidgets);
  });
}
