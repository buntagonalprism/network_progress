import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future runMaterial(WidgetTester tester, Widget child) async {
  final testWidget = MaterialApp(
    home: child,
  );
  await tester.pumpWidget(testWidget);
  await tester.pump();
}

Future runLauncher(
  WidgetTester tester,
  void Function(BuildContext context) launcher,
) async {
  final testWidget = MaterialApp(
    home: Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          launcher(context);
        });
        return Container();
      },
    ),
  );
  await tester.pumpWidget(testWidget);
  await tester.pump();
  // Delay to allow any route pushed by launcher to animate into place
  await tester.pump(Duration(seconds: 1));
}

Future tapWaitAnimation(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(Duration(seconds: 1));
}

Future tapAtWaitAnimation(WidgetTester tester, Offset offset) async {
  await tester.tapAt(offset);
  await tester.pump();
  await tester.pump(Duration(seconds: 1));
}

Future pageBackWaitAnimation(WidgetTester tester) async {
  await tester.pageBack(); // Trigger page back
  await tester.pump(); // Run first frame
  await tester.pump(Duration(seconds: 1)); // Wait for completion
}

Future deliverStreamData(WidgetTester tester) async {
  await tester.pump(); // Deliver data to wiget
  await tester.pump(); // Rebuild widget with new data
}
