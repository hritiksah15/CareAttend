import 'package:flutter/material.dart';

/// Simple sequential guided tour — one dialog per step, describing the app's
/// features for the current role. `onGoToTab(index)` switches the underlying
/// tab so the user sees each feature as the tour advances.
class GuidedTour {
  static const _steps = <Map<String, dynamic>>[
    {
      'title': 'Welcome to Care Attend',
      'body': 'This NHS tool predicts which patients may miss appointments (DNAs) '
          'and explains why with SHAP. This tour walks through the features '
          'available to your role.',
      'tab': null,
    },
    {
      'title': '1. Patient Assessment',
      'body': 'Enter age, gender, lead time, prior DNAs, clinical flags and IMD '
          'decile, then Assess Risk. Use EHR auto-fill or Carer Proxy for '
          'digitally excluded patients.',
      'tab': 0,
    },
    {
      'title': '2. Risk Results',
      'body': 'Read the DNA risk, the SHAP factors and recommended interventions. '
          'Log whether the patient attended with the feedback buttons.',
      'tab': 1,
    },
    {
      'title': '3. Practice Dashboard',
      'body': 'Session-wide overview: volume, risk breakdown by age group and '
          'recent assessments. (Staff/admin)',
      'tab': 2,
    },
    {
      'title': '4. More features',
      'body': 'Clinic list, Batch upload, Slot optimisation, Patient nudge, '
          'Bias monitor, Ethics and User management are in the bottom bar '
          'and the menu, depending on your role.',
      'tab': null,
    },
    {
      'title': 'AI Assistant',
      'body': 'Tap the robot button (bottom-right) any time to ask questions. '
          'Restart this tour from the ? icon in the top bar.',
      'tab': null,
    },
  ];

  static Future<void> start(
      BuildContext context, void Function(int) onGoToTab) async {
    for (var i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      if (step['tab'] != null) onGoToTab(step['tab'] as int);
      final next = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(step['title'] as String,
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Text(step['body'] as String),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(i == _steps.length - 1 ? 'Finish' : 'Next')),
          ],
        ),
      );
      if (next != true) break;
    }
  }
}
