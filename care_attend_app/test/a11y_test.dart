import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/main.dart';

/// Accessibility guideline checks on the unauthenticated login screen.
///
/// The app renders to CanvasKit, so DOM scanners (axe) can't evaluate it — these
/// Flutter guideline matchers are the honest automated a11y evidence for the app
/// (the web client's axe report covers the web client only).
void main() {
  testWidgets('Login screen meets tap-target and labelling guidelines',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CareAttendApp());
    await tester.pumpAndSettle();

    // Every tappable is at least the platform minimum size (>=48dp Android).
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    // Every tappable exposes a semantic label for screen readers.
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('Login screen meets text-contrast guideline',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CareAttendApp());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
