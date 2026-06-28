import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:care_attend_app/l10n/app_localizations.dart';
import 'package:care_attend_app/screens/batch_screen.dart';

void main() {
  testWidgets('Batch screen exposes template download action', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: BatchScreen()),
    ));
    await tester.pump();

    expect(find.text('Download template CSV'), findsOneWidget);
  });
}
