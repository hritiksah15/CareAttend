import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/l10n/app_localizations.dart';
import 'package:care_attend_app/widgets/ui.dart';

/// Pump a widget inside a MaterialApp wired with the same localization
/// delegates/locales as main.dart, so components that call
/// AppLocalizations.of(context) / Theme.of(context) resolve.
Future<void> pumpLocalized(WidgetTester tester, Widget child,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  ));
  // Never pumpAndSettle here: SkeletonList runs an infinite repeat() animation.
  await tester.pump();
}

void main() {
  testWidgets('RiskBadge renders the uppercased tier label', (tester) async {
    await pumpLocalized(tester, const RiskBadge('High'));
    expect(find.text('HIGH RISK'), findsOneWidget);
  });

  testWidgets('EmptyState shows its title and message', (tester) async {
    await pumpLocalized(
      tester,
      const EmptyState(
          icon: Icons.inbox, title: 'Nothing here', message: 'Come back later'),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Come back later'), findsOneWidget);
  });

  testWidgets('ErrorView shows message and fires onRetry', (tester) async {
    var retried = false;
    await pumpLocalized(
      tester,
      ErrorView('Boom', onRetry: () => retried = true),
    );
    expect(find.text('Boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget); // EN commonRetry
    await tester.tap(find.byType(TextButton));
    expect(retried, isTrue);
  });

  testWidgets('ErrorView localizes Retry under Urdu locale', (tester) async {
    await pumpLocalized(tester, ErrorView('x', onRetry: () {}),
        locale: const Locale('ur'));
    expect(find.text('دوبارہ کوشش'), findsOneWidget); // ur commonRetry
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('SkeletonList renders without throwing', (tester) async {
    await pumpLocalized(tester, const SkeletonList(count: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SkeletonList), findsOneWidget);
  });
}
