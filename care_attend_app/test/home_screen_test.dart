import 'package:care_attend_app/l10n/app_localizations.dart';
import 'package:care_attend_app/nhs_theme.dart';
import 'package:care_attend_app/screens/admin_screen.dart';
import 'package:care_attend_app/screens/bias_screen.dart';
import 'package:care_attend_app/screens/clinic_screen.dart';
import 'package:care_attend_app/screens/dashboard_screen.dart';
import 'package:care_attend_app/screens/ethics_screen.dart';
import 'package:care_attend_app/screens/home_screen.dart';
import 'package:care_attend_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: NHSTheme.theme,
    home: const HomeScreen(username: 'user1'),
  ));
  await tester.pump();
}

void main() {
  setUp(() {
    ApiService.clearSession();
  });

  testWidgets('normal users do not mount restricted hidden tabs',
      (tester) async {
    ApiService.role = 'user';

    await pumpHome(tester);

    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.byType(ClinicScreen), findsNothing);
    expect(find.byType(BiasScreen), findsNothing);
    expect(find.byType(EthicsScreen), findsNothing);
    expect(find.byType(AdminScreen), findsNothing);
  });
}
