import 'package:care_attend_app/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dashboard module cards navigate to their target modules',
      (tester) async {
    int? openedModule;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardModuleGrid(
          onOpenModule: (index) => openedModule = index,
          modules: const [
            DashboardModule(
              icon: Icons.edit_note,
              title: 'New Assessment',
              metric: 'Score one patient',
              detail: 'Start the workflow.',
              targetIndex: 0,
            ),
            DashboardModule(
              icon: Icons.upload_file,
              title: 'Batch Upload',
              metric: 'Up to 100 patients',
              detail: 'Score a cohort.',
              targetIndex: 9,
            ),
          ],
        ),
      ),
    ));

    expect(find.text('New Assessment'), findsOneWidget);
    expect(find.text('Batch Upload'), findsOneWidget);

    await tester.tap(find.text('Batch Upload'));
    await tester.pump();

    expect(openedModule, 9);
  });
}
