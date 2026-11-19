import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/trip_reminder_controller.dart';
import 'package:bladewatch_ui/shell/trip_reminder_host.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-gklt.6: the "trip still recording" dialog.
void main() {
  late FakeRpcClient rpc;
  late TripReminderController controller;
  var disposed = false;

  // A widget test checks for pending timers right after its body, BEFORE any tearDown runs, so
  // the controller's poll timer is cancelled at the end of each widget test body (hostTest).
  void disposeOnce() {
    if (disposed) return;
    disposed = true;
    controller.dispose();
  }

  void hostTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        disposeOnce();
      });

  Map<String, dynamic> status({
    bool manual = true,
    int seq = 0,
    int acked = 0,
    String reason = '',
    int startMs = 0,
  }) => {
    'status': {
      'active': true,
      'manual': manual,
      'startTimeMs': '$startMs',
      'reminderSeq': '$seq',
      'reminderReason': reason,
      'reminderAckedSeq': '$acked',
    },
  };

  void stubStatus(Map<String, dynamic> s) => rpc.stubJson('TripsService', 'GetActiveTrip', s);

  setUp(() {
    rpc = FakeRpcClient();
    rpc.stubJson('TripsService', 'AcknowledgeTripReminder', status(seq: 1, acked: 1));
    rpc.stubJson('TripsService', 'StopManualTrip', {'success': true, 'stopped': true});
    controller = TripReminderController(
      tripsService: TripsServiceClient(rpc),
      pollInterval: const Duration(hours: 1),
    );
    disposed = false;
    addTearDown(disposeOnce);
  });

  group('controller', () {
    test('pending: a manual trip with an unacknowledged reminder', () async {
      stubStatus(status(seq: 2, acked: 1, reason: 'acc_off'));
      await controller.refresh();

      expect(controller.pending, isNotNull);
      expect(controller.pending!.reminderReason, 'acc_off');
    });

    test('not pending: none raised, already acknowledged, or not a manual trip', () async {
      for (final s in [
        status(seq: 0),
        status(seq: 2, acked: 2),
        status(seq: 2, acked: 5),
        status(manual: false, seq: 3),
      ]) {
        stubStatus(s);
        await controller.refresh();
        expect(controller.pending, isNull, reason: '$s');
      }
    });

    test('a failed acknowledge still keeps the reminder from coming back', () async {
      stubStatus(status(seq: 1));
      await controller.refresh();
      rpc.stubError('TripsService', 'AcknowledgeTripReminder', const ConnectError('unavailable', 'down'));

      await controller.acknowledge(1);
      await controller.refresh();

      expect(controller.pending, isNull);
    });

    test('a dropped read keeps the last known status', () async {
      stubStatus(status(seq: 1));
      await controller.refresh();
      rpc.stubError('TripsService', 'GetActiveTrip', const ConnectError('unavailable', 'down'));

      await controller.refresh();

      expect(controller.pending, isNotNull);
    });

    test('stopTrip reports a failure instead of throwing', () async {
      rpc.stubError('TripsService', 'StopManualTrip', const ConnectError('unavailable', 'down'));
      expect(await controller.stopTrip(), isFalse);
    });

    test('start polls once immediately and is safe to call twice', () async {
      stubStatus(status(seq: 0));
      controller.start();
      controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(rpc.calls.where((c) => c.method == 'GetActiveTrip'), hasLength(2));
    });
  });

  group('dialog', () {
    Future<void> pumpHost(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: BladeWatchTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TripReminderHost(
            controller: controller,
            child: const Scaffold(body: Center(child: Text('screen'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    final dialog = find.byKey(const ValueKey('tripReminder.dialog'));

    hostTest('no reminder: no dialog', (tester) async {
      stubStatus(status(seq: 0));
      await pumpHost(tester);

      expect(dialog, findsNothing);
      expect(find.text('screen'), findsOneWidget);
    });

    hostTest('a new reminder shows one dialog, even across more polls', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch - 3_900_000));
      await pumpHost(tester);

      expect(dialog, findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const ValueKey('tripReminder.body'))).data, contains('turned the car off'));
      expect(tester.widget<Text>(find.byKey(const ValueKey('tripReminder.body'))).data, contains('1:05'));

      await controller.refresh();
      await controller.refresh();
      await tester.pumpAndSettle();
      expect(dialog, findsOneWidget);
    });

    hostTest('the parked reminder has its own wording', (tester) async {
      stubStatus(status(seq: 1, reason: 'parked_30m', startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpHost(tester);

      expect(tester.widget<Text>(find.byKey(const ValueKey('tripReminder.body'))).data, contains('30 minutes'));
    });

    hostTest('Keep recording acknowledges and does not stop the trip', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpHost(tester);

      await tester.tap(find.byKey(const ValueKey('tripReminder.keep')));
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(rpc.calls.where((c) => c.method == 'AcknowledgeTripReminder'), hasLength(1));
      expect(rpc.calls.where((c) => c.method == 'StopManualTrip'), isEmpty);
    });

    hostTest('Stop trip stops the trip and acknowledges', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpHost(tester);

      await tester.tap(find.byKey(const ValueKey('tripReminder.stop')));
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(rpc.calls.where((c) => c.method == 'StopManualTrip'), hasLength(1));
      expect(rpc.calls.where((c) => c.method == 'AcknowledgeTripReminder'), hasLength(1));
    });

    hostTest('a failed stop keeps the dialog open with an error', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      rpc.stubError('TripsService', 'StopManualTrip', const ConnectError('unavailable', 'down'));
      await pumpHost(tester);

      await tester.tap(find.byKey(const ValueKey('tripReminder.stop')));
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
      expect(find.byKey(const ValueKey('tripReminder.error')), findsOneWidget);
      expect(rpc.calls.where((c) => c.method == 'AcknowledgeTripReminder'), isEmpty);
    });

    hostTest('an acknowledged reminder is not shown', (tester) async {
      stubStatus(status(seq: 2, acked: 2, reason: 'acc_off'));
      await pumpHost(tester);

      expect(dialog, findsNothing);
    });

    hostTest('an auto trip never shows the dialog', (tester) async {
      stubStatus(status(manual: false, seq: 5));
      await pumpHost(tester);

      expect(dialog, findsNothing);
    });

    hostTest('coming back to the foreground re-reads the status and shows the dialog', (tester) async {
      stubStatus(status(seq: 0));
      await pumpHost(tester);
      expect(dialog, findsNothing);

      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      // The binding starts in `resumed`, and a repeat of the same state is not a transition.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
    });

    hostTest('a newer reminder shows again after the first was handled', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpHost(tester);
      await tester.tap(find.byKey(const ValueKey('tripReminder.keep')));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);

      stubStatus(status(seq: 2, acked: 1, reason: 'parked_30m', startMs: DateTime.now().millisecondsSinceEpoch));
      await controller.refresh();
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
    });

    hostTest('acknowledging reminder 1 never swallows a newer reminder 2 that arrived meanwhile', (tester) async {
      stubStatus(status(seq: 1, reason: 'acc_off', startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpHost(tester);
      expect(dialog, findsOneWidget);

      // Reminder 2 is raised while the dialog for reminder 1 is still up.
      stubStatus(status(seq: 2, acked: 0, reason: 'parked_30m', startMs: DateTime.now().millisecondsSinceEpoch));
      rpc.stubJson('TripsService', 'AcknowledgeTripReminder', status(seq: 2, acked: 1, reason: 'parked_30m'));
      await controller.refresh();
      await tester.pump();
      expect(dialog, findsOneWidget, reason: 'still the one dialog');

      await tester.tap(find.byKey(const ValueKey('tripReminder.keep')));
      await tester.pumpAndSettle();

      final ack = rpc.calls.singleWhere((c) => c.method == 'AcknowledgeTripReminder');
      expect((ack.request as dynamic).reminderSeq.toInt(), 1, reason: 'what the driver saw, not the latest');
      expect(dialog, findsOneWidget, reason: 'reminder 2 is shown next');
      expect(tester.widget<Text>(find.byKey(const ValueKey('tripReminder.body'))).data, contains('30 minutes'));
    });
  });
}
