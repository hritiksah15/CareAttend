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
  testWidgets('AdminUserManagementCard exposes web-parity action icons',
      (tester) async {
    var savedRole = '';
    var approved = false;
    var deleted = false;
    var activity = false;

    await pumpLocalized(
      tester,
      AdminUserManagementCard(
        user: const {
          'userId': 'u-1',
          'username': 'clerk',
          'email': 'clerk@nhs.test',
          'role': 'user',
          'approved': false,
        },
        selectedRole: 'staff',
        onRoleChanged: (role) => savedRole = role,
        onApprove: () => approved = true,
        onSaveRole: () => savedRole = 'saved',
        onDelete: () => deleted = true,
        onToggleActivity: () => activity = true,
      ),
    );

    expect(find.byTooltip('Approve user'), findsOneWidget);
    expect(find.byTooltip('Save role'), findsOneWidget);
    expect(find.byTooltip('View login/activity'), findsOneWidget);
    expect(find.byTooltip('Delete user'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.byTooltip('Approve user'));
    await tester.tap(find.byTooltip('Save role'));
    await tester.tap(find.byTooltip('View login/activity'));
    await tester.tap(find.byTooltip('Delete user'));

    expect(approved, isTrue);
    expect(savedRole, 'saved');
    expect(activity, isTrue);
    expect(deleted, isTrue);
  });

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

  testWidgets('AdminSessionLogCard filters login sessions by username',
      (tester) async {
    await pumpLocalized(
      tester,
      const AdminSessionLogCard(
        usernameFilter: 'clerk',
        logs: [
          {
            'action': 'login_success',
            'username': 'boss',
            'detail': 'boss signed in',
            'createdAt': 1782600000.0,
          },
          {
            'action': 'login_success',
            'username': 'clerk',
            'detail': 'clerk signed in',
            'createdAt': 1782600300.0,
          },
        ],
      ),
    );

    expect(find.text('Login · clerk'), findsOneWidget);
    expect(find.text('clerk signed in'), findsOneWidget);
    expect(find.text('Login · boss'), findsNothing);
  });

  testWidgets('AdminUserActivityCard renders user-linked audit activity',
      (tester) async {
    await pumpLocalized(
      tester,
      const AdminUserActivityCard(
        username: 'clerk',
        logs: [
          {
            'action': 'login_success',
            'username': 'clerk',
            'detail': 'clerk signed in',
            'createdAt': 1782600000.0,
          },
          {
            'action': 'role_changed',
            'username': 'boss',
            'detail': 'clerk: user -> staff',
            'createdAt': 1782600300.0,
          },
        ],
      ),
    );

    expect(find.text('Activity for clerk'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Role changed'), findsOneWidget);
    expect(find.text('clerk: user -> staff'), findsOneWidget);
  });
}
