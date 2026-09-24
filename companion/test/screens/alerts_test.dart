import 'package:bladewatch_companion/screens/alerts/alert_settings_screen.dart';
import 'package:bladewatch_companion/screens/alerts/alerts_controller.dart';
import 'package:bladewatch_companion/screens/events/events_screen.dart';
import 'package:bladewatch_companion/screens/recordings/clips.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

Map<String, dynamic> entry(int id, {String category = 'surveillance.motion.alert', String severity = 'NOTIFICATION_SEVERITY_ALERT', String url = '', String body = 'b'}) =>
    {'id': '$id', 'timestampMs': '1700000000000', 'category': category, 'severity': severity, 'title': 'alert $id', 'body': body, 'clickUrl': url};

void inbox(TestSession s, List<Map<String, dynamic>> entries) => s.rpc.stubJson('NotificationsService', 'ListInbox', {
      'entries': entries,
      'latestId': entries.isEmpty ? '0' : entries.last['id'],
    });

void main() {
  group('AlertsController', () {
    test('fetches on connect and on a timer while connected, newest first, mutes left out', () async {
      final s = TestSession(phase: TransportPhase.discovering);
      final store = testStore(car: testCar(cursor: '1'))..mutedCategories = {'trips.ended'};
      inbox(s, [entry(1), entry(2, category: 'trips.ended'), entry(3)]);
      final c = AlertsController(session: s.session, store: store, every: const Duration(milliseconds: 20));
      expect(c.entries, isEmpty);
      expect(s.rpc.calls, isEmpty, reason: 'nothing to fetch from while unreachable');

      s.phases.add(TransportPhase.pear);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(c.entries.map((e) => e.id.toInt()), [3, 1]);
      expect(c.unseen, 1);
      expect(c.isNew(c.entries.first), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final polled = s.rpc.calls.length;
      expect(polled, greaterThan(1));
      s.phases.add(TransportPhase.failed);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(s.rpc.calls.length, lessThanOrEqualTo(polled + 1), reason: 'no polling while unreachable');
      c.dispose();
    });

    test('markSeen moves the cursor to the newest and persists it; a failed fetch keeps the list', () async {
      final s = TestSession();
      final store = testStore(car: testCar());
      inbox(s, [entry(4), entry(9)]);
      final c = AlertsController(session: s.session, store: store);
      await c.refresh();
      expect(c.unseen, 2);
      await c.markSeen();
      expect(c.unseen, 0);
      expect(store.car!.inboxCursor, Int64(9));
      await c.markSeen(); // nothing newer: no write
      s.rpc.stubError('NotificationsService', 'ListInbox', const ConnectError('unavailable', 'down'));
      await c.refresh();
      expect(c.entries, hasLength(2));
      c.dispose();
    });

    test('sendTest raises one in the car and fetches again', () async {
      final s = TestSession();
      inbox(s, []);
      s.rpc.stubJson('NotificationsService', 'SendTest', {'success': true});
      final c = AlertsController(session: s.session, store: testStore(car: testCar()));
      await c.sendTest();
      expect(s.rpc.calls.map((x) => x.method), containsAllInOrder(['SendTest', 'ListInbox']));
      final sent = s.rpc.calls.firstWhere((x) => x.method == 'SendTest').request as SendTestRequest;
      expect(sent.category, 'surveillance.motion');
      c.dispose();
    });
  });

  group('EventsScreen', () {
    testWidgets('alerts: new ones in bold, severities, a clip link opens the player; seen once shown', (tester) async {
      final s = TestSession();
      final store = testStore(car: testCar());
      inbox(s, [
        entry(1, severity: 'NOTIFICATION_SEVERITY_INFO', body: ''),
        entry(2, severity: 'NOTIFICATION_SEVERITY_CRITICAL', url: '/events?filter=sentry&file=clip-2.mp4'),
      ]);
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': []});
      final alerts = AlertsController(session: s.session, store: store);
      await alerts.refresh();

      await pumpScreen(tester, s, EventsScreen(alerts: alerts));
      await tester.pump();
      expect(find.text('alert 2'), findsOneWidget);
      expect(tester.widget<Text>(find.text('alert 2')).style?.fontWeight, FontWeight.bold);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(store.car!.inboxCursor, Int64(2), reason: 'opening the list counts as seeing it');

      inbox(s, [entry(1), entry(2, severity: 'NOTIFICATION_SEVERITY_CRITICAL', url: '/events?filter=sentry&file=clip-2.mp4'), entry(3)]);
      await alerts.refresh();
      await tester.pump();
      expect(store.car!.inboxCursor, Int64(3), reason: 'one that arrives while the list is open is seen too');
      expect(tester.widget<Text>(find.text('alert 3')).style?.fontWeight, FontWeight.bold);

      await tester.tap(find.text('alert 2'));
      await tester.pumpAndSettle();
      expect(find.byType(ClipPlayerScreen), findsOneWidget);
      expect(find.text('clip-2.mp4'), findsOneWidget);
      await unmount(tester);
      alerts.dispose();
    });

    testWidgets('no alerts says so; the clip tabs list the car\'s clips', (tester) async {
      final s = TestSession();
      inbox(s, []);
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          {'filename': 'sentry-1.mp4', 'type': 'RECORDING_TYPE_SENTRY', 'timestamp': '1700000000000', 'size': '1048576', 'durationSeconds': '30', 'detectedClasses': ['person']},
        ],
      });
      final alerts = AlertsController(session: s.session, store: testStore(car: testCar()));
      await pumpScreen(tester, s, EventsScreen(alerts: alerts));
      expect(find.text(t('companion.alerts_empty')), findsOneWidget);
      await tester.tap(find.text(t('events.badge_sentry')).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clip.sentry-1.mp4')), findsOneWidget);
      expect((s.rpc.calls.lastWhere((c) => c.method == 'ListRecordings').request as dynamic).type, 'sentry');

      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': []});
      await tester.tap(find.text(t('events.badge_proximity')).first);
      await tester.pumpAndSettle();
      expect(find.text(t('events.empty_none_title')), findsOneWidget);
      await unmount(tester);
      alerts.dispose();
    });
  });

  group('AlertSettingsScreen', () {
    testWidgets('lists the car\'s categories; hiding one is stored and filters the list; test alert', (tester) async {
      final s = TestSession();
      final store = testStore(car: testCar());
      s.rpc.stubJson('NotificationsService', 'GetCategories', {
        'categoriesJson': '{"categories":[{"id":"trips.ended","label":"Trip ended","group":"Trips"},{"id":"x.y"}]}',
      });
      s.rpc.stubJson('NotificationsService', 'SendTest', {'success': true});
      inbox(s, [entry(1, category: 'trips.ended')]);
      final alerts = AlertsController(session: s.session, store: store);
      await pumpScreen(tester, s, AlertSettingsScreen(alerts: alerts, store: store));
      expect(find.text('Trip ended'), findsOneWidget);
      expect(find.text('x.y'), findsOneWidget, reason: 'a category without a label shows its id');

      await tester.tap(find.byKey(const ValueKey('alerts.cat.trips.ended')));
      await tester.pumpAndSettle();
      expect(store.mutedCategories, {'trips.ended'});
      expect(alerts.entries, isEmpty);

      await tester.tap(find.byKey(const ValueKey('alerts.test')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.alerts_test_sent')), findsOneWidget);
      await unmount(tester);
      alerts.dispose();
    });

    test('parseCategories tolerates a registry it cannot read', () {
      expect(parseCategories('nope'), isEmpty);
      expect(parseCategories('{}'), isEmpty);
    });
  });
}
