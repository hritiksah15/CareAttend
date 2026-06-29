import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/l10n/app_localizations.dart';
import 'package:care_attend_app/nhs_theme.dart';
import 'package:care_attend_app/screens/admin_screen.dart';

Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: NHSTheme.theme,
    darkTheme: NHSTheme.darkTheme,
    themeMode: themeMode,
    home: Scaffold(body: child),
  ));
  await tester.pump();
}

void expectVisibleActionButton(
  WidgetTester tester,
  String label,
  IconData icon,
) {
  final labelWidget = tester.widget<Text>(find.text(label));
  expect(labelWidget.style?.color, isNotNull);
  expect(labelWidget.style?.color, isNot(Colors.transparent));
  expect(labelWidget.style?.fontWeight, FontWeight.w800);

  final iconWidget = tester.widget<Icon>(find.byIcon(icon));
  expect(iconWidget.color, isNotNull);
  expect(iconWidget.color, isNot(Colors.transparent));
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

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Save role'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    expect(find.byIcon(Icons.manage_history), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expectVisibleActionButton(tester, 'Approve', Icons.verified_user_outlined);
    expectVisibleActionButton(tester, 'Save role', Icons.save_outlined);
    expectVisibleActionButton(tester, 'Activity', Icons.manage_history);
    expectVisibleActionButton(tester, 'Delete', Icons.delete_outline);

    await tester.tap(find.text('Approve'));
    await tester.tap(find.text('Save role'));
    await tester.tap(find.text('Activity'));
    await tester.tap(find.text('Delete'));

    expect(approved, isTrue);
    expect(savedRole, 'saved');
    expect(activity, isTrue);
    expect(deleted, isTrue);
  });

  testWidgets(
      'AdminUserManagementCard keeps action icons visible in dark theme',
      (tester) async {
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
        onRoleChanged: (_) {},
        onApprove: () {},
        onSaveRole: () {},
        onDelete: () {},
        onToggleActivity: () {},
      ),
      themeMode: ThemeMode.dark,
    );

    expectVisibleActionButton(tester, 'Approve', Icons.verified_user_outlined);
    expectVisibleActionButton(tester, 'Save role', Icons.save_outlined);
    expectVisibleActionButton(tester, 'Activity', Icons.manage_history);
    expectVisibleActionButton(tester, 'Delete', Icons.delete_outline);
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
