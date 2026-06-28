import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/l10n/app_localizations.dart';
import 'package:care_attend_app/screens/admin_screen.dart';

Future<void> pumpLocalized(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  ));
  await tester.pump();
}

void main() {
  testWidgets('AdminSessionLogCard renders login and logout events',
      (tester) async {
    await pumpLocalized(
      tester,
      const AdminSessionLogCard(logs: [
        {
          'action': 'login_success',
          'username': 'boss',
          'detail': 'boss signed in',
          'ipAddress': '127.0.0.1',
          'createdAt': 1782600000.0,
        },
        {
          'action': 'logout',
          'username': 'boss',
          'detail': 'boss signed out',
          'ipAddress': '127.0.0.1',
          'createdAt': 1782600300.0,
        },
      ]),
    );

    expect(find.text('Login Session Log'), findsOneWidget);
    expect(find.text('Login · boss'), findsOneWidget);
    expect(find.text('Logout · boss'), findsOneWidget);
    expect(find.text('boss signed in'), findsOneWidget);
    expect(find.text('boss signed out'), findsOneWidget);
  });

  testWidgets('AdminSessionLogCard ignores unrelated audit rows',
      (tester) async {
    await pumpLocalized(
      tester,
      const AdminSessionLogCard(logs: [
        {
          'action': 'role_changed',
          'username': 'boss',
          'detail': 'clerk: user -> staff',
          'createdAt': 1782600000.0,
        },
      ]),
    );

    expect(find.text('No login session events yet.'), findsOneWidget);
    expect(find.textContaining('role_changed'), findsNothing);
  });
}
