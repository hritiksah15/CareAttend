import 'package:flutter/material.dart';
import 'nhs_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const CareAttendApp());
}

class CareAttendApp extends StatelessWidget {
  const CareAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Attend',
      theme: NHSTheme.theme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
