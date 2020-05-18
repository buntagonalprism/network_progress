import 'package:building_blocs/building_blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_progress/src/progress_overlay.dart';

import 'test_helpers.dart';

void main() {
  final spinnerFinder = find.byType(CircularProgressIndicator);

  DataStreamController<ProgressState> progress;

  setUp(() {
    progress = DataStreamController<ProgressState>();
  });

  tearDown(() {
    progress.close();
  });

  testWidgets('No progress when stream empty', (WidgetTester tester) async {
    await runMaterial(tester, ProgressOverlay(progress: progress, child: Container()));
    expect(spinnerFinder, findsNothing);
  });

  testWidgets('Displays progress for initial loading state', (WidgetTester tester) async {
    progress.add(ProgressState.loading());
    await deliverStreamData(tester);
    await runMaterial(tester, ProgressOverlay(progress: progress, child: Container()));
    expect(spinnerFinder, findsOneWidget);
  });

  testWidgets('Shows and hides with stream events', (WidgetTester tester) async {
    await runMaterial(tester, ProgressOverlay(progress: progress, child: Container()));
    expect(spinnerFinder, findsNothing);
    progress.add(ProgressState.loading());
    await deliverStreamData(tester);
    expect(spinnerFinder, findsOneWidget);
    progress.add(ProgressState.finished());
    await deliverStreamData(tester);
    expect(spinnerFinder, findsNothing);
  });

  testWidgets('Displays default loading message if none provided', (WidgetTester tester) async {
    await runMaterial(tester, ProgressOverlay(progress: progress, child: Container()));
    progress.add(ProgressState.loading());
    await deliverStreamData(tester);
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('Displays supplied loading message', (WidgetTester tester) async {
    await runMaterial(tester, ProgressOverlay(progress: progress, child: Container()));
    progress.add(ProgressState.loading(message: 'Very busy right now'));
    await deliverStreamData(tester);
    expect(find.text('Very busy right now'), findsOneWidget);
  });

  group('Preventing pop', () {
    final overlayWidgetFinder = find.byType(ProgressOverlay);

    Future launchPopTest(WidgetTester tester, bool canPop) async {
      await runLauncher(tester, (ctx) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(),
              body: ProgressOverlay(
                progress: progress,
                child: Container(),
                canPopWhileLoading: canPop,
              ),
            ),
          ),
        );
      });
      expect(find.byType(ProgressOverlay), findsOneWidget);
    }

    test('Prevent pop is default', () {
      final progressOverlay = ProgressOverlay(progress: progress, child: Container());
      expect(progressOverlay.canPopWhileLoading, isFalse);
    });

    group('When canPop is false', () {
      testWidgets('Prevents pop while loading', (WidgetTester tester) async {
        progress.add(ProgressState.loading());
        await deliverStreamData(tester);
        await launchPopTest(tester, false);
        await pageBackWaitAnimation(tester);
        expect(overlayWidgetFinder, findsOneWidget);
      });

      testWidgets('Does not prevent pop while not loading', (WidgetTester tester) async {
        progress.add(ProgressState.finished());
        await deliverStreamData(tester);
        await launchPopTest(tester, false);
        await pageBackWaitAnimation(tester);
        expect(overlayWidgetFinder, findsNothing);
      });
    });

    group('When canPop is true', () {
      testWidgets('Does not prevent pop while loading', (WidgetTester tester) async {
        progress.add(ProgressState.loading());
        await deliverStreamData(tester);
        await launchPopTest(tester, true);
        await pageBackWaitAnimation(tester);
        expect(overlayWidgetFinder, findsNothing);
      });
    });
  });
}
