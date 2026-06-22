import 'package:flutter/material.dart';
import 'nhs_theme.dart';
import 'screens/login_screen.dart';

/// Global theme-mode switch — toggled from the home screen's dark-mode button,
/// mirroring the website's dark mode.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  runApp(const CareAttendApp());
}

class CareAttendApp extends StatelessWidget {
  const CareAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Care Attend',
          theme: NHSTheme.theme,
          darkTheme: NHSTheme.darkTheme,
          themeMode: mode,
          home: const LoginScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
