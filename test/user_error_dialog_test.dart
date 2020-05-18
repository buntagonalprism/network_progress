import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_progress/src/user_error.dart';
import 'package:network_progress/src/user_error_dialog.dart';

import 'test_helpers.dart';

void main() {
  final dialogFinder = find.byType(UserErrorDialog);

  testWidgets('Message can be displayed without title',
      (WidgetTester tester) async {
    final request = UserError(message: 'Hello world', responses: []);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(find.text('Hello world'), findsOneWidget);
  });

  testWidgets('Title displayed if present with message',
      (WidgetTester tester) async {
    final request =
        UserError(title: 'I, title', message: 'I, message', responses: []);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(find.text('I, title'), findsOneWidget);
    expect(find.text('I, message'), findsOneWidget);
  });

  testWidgets('Each response displayed', (WidgetTester tester) async {
    final request = UserError(message: '', responses: [
      ErrorResponse('A', () {}),
      ErrorResponse('B', () {}),
      ErrorResponse('C', () {}),
    ]);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    for (ErrorResponse response in request.responses) {
      final btnFinder = find.descendant(
        of: find.byType(FlatButton),
        matching: find.text(response.label),
      );
      expect(btnFinder, findsOneWidget);
    }
  });

  testWidgets('Responses invoke their callback and dismiss dialog',
      (WidgetTester tester) async {
    bool calledA = false;
    bool calledB = false;
    final request = UserError(message: '', responses: [
      ErrorResponse('A', () => calledA = true),
      ErrorResponse('B', () => calledB = true),
    ]);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(calledA, isFalse);
    expect(dialogFinder, findsOneWidget);
    await tapWaitAnimation(tester, find.text('A'));
    expect(calledA, isTrue);
    expect(calledB, isFalse);
    expect(dialogFinder, findsNothing);

    // Re-test with other option
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(dialogFinder, findsOneWidget);
    await tapWaitAnimation(tester, find.text('B'));
    expect(calledB, isTrue);
    expect(dialogFinder, findsNothing);
  });

  test('Input request requires a response by default', () {
    final request = UserError(message: '', responses: []);
    expect(request.responseIsRequired, isTrue);
  });

  testWidgets('Cannot dismiss dialog if response required',
      (WidgetTester tester) async {
    final request =
        UserError(message: '', responses: [], responseIsRequired: true);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(dialogFinder, findsOneWidget);
    // Tap in the top corner, on the dialog barrier
    await tapAtWaitAnimation(tester, Offset(1, 1));
    expect(dialogFinder, findsOneWidget);
  });

  testWidgets('Can dismiss dialog if response is not required',
      (WidgetTester tester) async {
    final request =
        UserError(message: '', responses: [], responseIsRequired: false);
    await runLauncher(tester, (ctx) => UserErrorDialog.show(ctx, request));
    expect(dialogFinder, findsOneWidget);
    // Tap in the top corner, on the dialog barrier
    await tapAtWaitAnimation(tester, Offset(1, 1));
    expect(dialogFinder, findsNothing);
  });
}


