import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ollie/screens/home/widgets/home_sidebar.dart';

void main() {
  testWidgets('HomeSidebar shows Projects and Archived navigation', (tester) async {
    var selectedView = 'projects';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSidebar(
            selectedView: selectedView,
            onViewChanged: (view) => selectedView = view,
            projectsCount: 3,
            archivedProjectsCount: 1,
          ),
        ),
      ),
    );

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Archived'));
    await tester.pump();
    expect(selectedView, 'archived');
  });
}
