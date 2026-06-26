import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'nhs_theme.dart';
import 'l10n/app_localizations.dart';
import 'state/locale_controller.dart';
import 'screens/login_screen.dart';

/// Global theme-mode switch — toggled from the home screen's dark-mode button,
/// mirroring the website's dark mode.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  runApp(const CareAttendApp());
  // Load persisted locale after first frame (non-blocking); avoids any startup
  // async work that can stall the web release boot.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    LocaleController.instance.load();
  });
}

class CareAttendApp extends StatelessWidget {
  const CareAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.instance.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Care Attend',
              theme: NHSTheme.theme,
              darkTheme: NHSTheme.darkTheme,
              themeMode: mode,
              locale: locale,
              supportedLocales: LocaleController.supported,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const LoginScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
        );
      },
    );
  }
}
