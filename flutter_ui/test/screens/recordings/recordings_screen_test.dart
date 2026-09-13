import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_controller.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_player_screen.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';
import '../../fakes/fake_video_player_platform.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'jwt-1';
  @override
  Future<int> stateVersion() async => 0;
}

Map<String, dynamic> _entry({
  required String filename,
  required String type,
  int timestampMs = 1000,
  int sizeBytes = 1500,
  int durationSeconds = 60,
  bool hasEvents = false,
  List<String> detectedClasses = const [],
  String severity = '',
  String proximity = '',
}) =>
    {
      'filename': filename,
      'path': '/storage/emulated/0/BladeWatch/recordings/$filename',
      'type': type,
      'timestamp': timestampMs.toString(),
      'size': sizeBytes.toString(),
      'durationSeconds': durationSeconds.toString(),
      'dateFormatted': 'May 23, 2026',
      'timeFormatted': '12:00:00 PM',
      'hasEvents': hasEvents,
      'detectedClasses': detectedClasses,
      'peakSeverity': severity,
      'peakProximity': proximity,
    };

void main() {
  late FakeRpcClient rpc;
  late RecordingsController controller;
  final now = DateTime(2026, 5, 23, 15, 0).millisecondsSinceEpoch;

  void stubStats({int total = 0, int recordings = 0, int surveillance = 0, int proximity = 0, int totalBytes = 0}) {
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {
        'recordingsSizeBytes': '0',
        'surveillanceSizeBytes': '0',
        'proximitySizeBytes': '0',
        'recordingsCount': recordings,
        'surveillanceCount': surveillance,
        'proximityCount': proximity,
        'totalSizeBytes': totalBytes.toString(),
        'totalCount': total,
      },
    });
  }

  setUp(() {
    FakeVideoPlayerPlatform.install();
    rpc = FakeRpcClient();
    controller = RecordingsController(recordingsService: RecordingsServiceClient(rpc), nowMs: () => now);
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  RecordingsScreen buildScreen({VoidCallback? onOpenSettings}) => RecordingsScreen(
        controller: controller,
        recordingsService: RecordingsServiceClient(rpc),
        jwtSource: _FakeJwtSource(),
        onOpenSettings: onOpenSettings ?? () {},
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
  }

  Future<void> pumpScreen(WidgetTester tester, {VoidCallback? onOpenSettings}) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(buildScreen(onOpenSettings: onOpenSettings)));
    await settle(tester);
  }

  testWidgets('shows an error state with a retry action', (tester) async {
    rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'no daemon'));
    stubStats();
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('recordings.error')), findsOneWidget);
  });

  testWidgets('shows an empty state with today\'s default filter (Dashcam, narrowed to today)', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
    stubStats();
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('recordings.empty')), findsOneWidget);
  });

  testWidgets('the empty state text is source/type specific', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
    stubStats();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeNormal')));
    await settle(tester);
    expect(find.text('No normal recordings'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeNormal')));
    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeProximity')));
    await settle(tester);
    expect(find.text('No proximity events'), findsOneWidget);

    controller.setSource(RecordingSource.surveillance);
    await settle(tester);
    expect(find.text('No sentry events'), findsOneWidget);
  });

  testWidgets('renders a grid card for each visible recording, grouped under a section header', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(filename: 'cam_20260523_083000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
      ],
    });
    stubStats(total: 1, recordings: 1);
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('recordings.grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsOneWidget);
    expect(find.text('12:00:00 PM'), findsOneWidget);
  });

  testWidgets('switching to Surveillance shows sentry clips and hides normal ones', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(filename: 'cam_20260523_083000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        _entry(filename: 'event_20260523_090000.mp4', type: 'RECORDING_TYPE_SENTRY', timestampMs: now),
      ],
    });
    stubStats(total: 2, recordings: 1, surveillance: 1);
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsOneWidget);

    await tester.tap(find.textContaining('Surveillance').first);
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.event_20260523_090000.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsNothing);
  });

  testWidgets('type chip narrows the Dashcam grid to Normal clips only', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(filename: 'cam_20260523_083000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        _entry(filename: 'proximity_20260523_090000.mp4', type: 'RECORDING_TYPE_PROXIMITY', timestampMs: now),
      ],
    });
    stubStats(total: 2, recordings: 1, proximity: 1);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeNormal')));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.proximity_20260523_090000.mp4')), findsNothing);
  });

  testWidgets('type chip narrows the Dashcam grid to Proximity clips only', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(filename: 'cam_20260523_083000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        _entry(filename: 'proximity_20260523_090000.mp4', type: 'RECORDING_TYPE_PROXIMITY', timestampMs: now),
      ],
    });
    stubStats(total: 2, recordings: 1, proximity: 1);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeProximity')));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.proximity_20260523_090000.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsNothing);
    expect(find.byKey(const ValueKey('recordings.resetChips')), findsOneWidget);
  });

  testWidgets('the reset chip button clears the active type filter', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(filename: 'cam_20260523_083000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        _entry(filename: 'proximity_20260523_090000.mp4', type: 'RECORDING_TYPE_PROXIMITY', timestampMs: now),
      ],
    });
    stubStats(total: 2, recordings: 1, proximity: 1);
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.chip.typeProximity')));
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.resetChips')));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.cam_20260523_083000.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.proximity_20260523_090000.mp4')), findsOneWidget);
  });

  testWidgets('the surveillance filter sheet toggles an actor chip and narrows the grid', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'event_a.mp4',
          type: 'RECORDING_TYPE_SENTRY',
          timestampMs: now,
          detectedClasses: ['person'],
          severity: 'ALERT',
        ),
        _entry(
          filename: 'event_b.mp4',
          type: 'RECORDING_TYPE_SENTRY',
          timestampMs: now,
          detectedClasses: ['vehicle'],
          severity: 'ALERT',
        ),
      ],
    });
    stubStats(total: 2, surveillance: 2);
    await pumpScreen(tester);
    await tester.tap(find.textContaining('Surveillance').first);
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.card.event_a.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.event_b.mp4')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.openFilterSheet')));
    // The modal bottom sheet slides in over a real animation duration --
    // plain pump()s (no elapsed time) leave it mid-transition, positioned
    // below its resting spot, so taps on it land past the viewport bounds.
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recordings.sheet.actor.person')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.sheet.apply')));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.event_a.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.card.event_b.mp4')), findsNothing);
  });

  testWidgets('every active-filter chip kind renders and can be removed', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'event_all.mp4',
          type: 'RECORDING_TYPE_SENTRY',
          timestampMs: now,
          detectedClasses: ['person', 'vehicle', 'bike', 'animal'],
          severity: 'CRITICAL',
        ),
      ],
    });
    stubStats(total: 1, surveillance: 1);
    await pumpScreen(tester);
    await tester.tap(find.textContaining('Surveillance').first);
    await settle(tester);
    controller
      ..toggleActorClass('person')
      ..toggleActorClass('vehicle')
      ..toggleActorClass('bike')
      ..toggleActorClass('animal')
      ..toggleSeverity('ALERT')
      ..toggleSeverity('CRITICAL');
    await settle(tester);

    for (final id in ['person', 'vehicle', 'bike', 'animal', 'severity-alert', 'severity-critical']) {
      expect(find.byKey(ValueKey('recordings.activeChip.$id')), findsOneWidget);
    }

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('recordings.activeChip.vehicle')),
      matching: find.byType(Icon),
    ));
    await settle(tester);
    expect(controller.filter.actorClasses, isNot(contains('vehicle')));
  });

  testWidgets('an inline active-filter chip removes that filter when deleted', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'event_a.mp4',
          type: 'RECORDING_TYPE_SENTRY',
          timestampMs: now,
          detectedClasses: ['person'],
        ),
      ],
    });
    stubStats(total: 1, surveillance: 1);
    await pumpScreen(tester);
    await tester.tap(find.textContaining('Surveillance').first);
    await settle(tester);
    controller.toggleActorClass('person');
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.activeChip.person')), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('recordings.activeChip.person')),
      matching: find.byType(Icon),
    ));
    await settle(tester);

    expect(controller.filter.actorClasses, isEmpty);
  });

  testWidgets('the sheet\'s Any chips clear their own row, and severity chips toggle', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'event_a.mp4',
          type: 'RECORDING_TYPE_SENTRY',
          timestampMs: now,
          detectedClasses: ['person'],
          severity: 'CRITICAL',
        ),
      ],
    });
    stubStats(total: 1, surveillance: 1);
    await pumpScreen(tester);
    await tester.tap(find.textContaining('Surveillance').first);
    await settle(tester);
    controller.toggleActorClass('person');
    await settle(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.openFilterSheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recordings.sheet.sev.CRITICAL')));
    await settle(tester);
    expect(controller.filter.severities, {'CRITICAL'});

    await tester.tap(find.byKey(const ValueKey('recordings.sheet.actorAny')));
    await settle(tester);
    expect(controller.filter.actorClasses, isEmpty);

    await tester.tap(find.byKey(const ValueKey('recordings.sheet.sevAny')));
    await settle(tester);
    expect(controller.filter.severities, isEmpty);
  });

  testWidgets('tapping the date field opens a date picker that narrows to the chosen day', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
    stubStats();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.datePick')));
    await tester.pumpAndSettle();
    // Land on a definitely-in-range day cell inside the calendar grid.
    await tester.tap(find.text('10').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.filter.dateNarrowed, isTrue);
  });

  testWidgets('the date field shows "Yesterday" the day before today', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
    stubStats();
    await pumpScreen(tester);
    controller.goYesterday();
    await settle(tester);

    expect(find.text('Yesterday'), findsOneWidget);
  });

  group('date navigation', () {
    testWidgets('the clear-date button widens to all days', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'cam_b.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now - 5 * 86400000),
        ],
      });
      stubStats(total: 2, recordings: 2);
      await pumpScreen(tester);
      expect(find.byKey(const ValueKey('recordings.card.cam_b.mp4')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('recordings.clearDate')));
      await settle(tester);

      expect(find.byKey(const ValueKey('recordings.card.cam_a.mp4')), findsOneWidget);
      expect(find.byKey(const ValueKey('recordings.card.cam_b.mp4')), findsOneWidget);
    });

    testWidgets('prev/next day buttons shift the selected day', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
      stubStats();
      await pumpScreen(tester);
      final todayMs = DateTime(2026, 5, 23).millisecondsSinceEpoch;
      expect(controller.filter.selectedDayMs, todayMs);

      await tester.tap(find.byKey(const ValueKey('recordings.prevDay')));
      await settle(tester);
      expect(controller.filter.selectedDayMs, DateTime(2026, 5, 22).millisecondsSinceEpoch);

      await tester.tap(find.byKey(const ValueKey('recordings.nextDay')));
      await settle(tester);
      expect(controller.filter.selectedDayMs, todayMs);
    });
  });

  group('multi-select', () {
    testWidgets('long-pressing a card enters select mode and shows the toolbar', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats(total: 1, recordings: 1);
      await pumpScreen(tester);

      await tester.longPress(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
      await settle(tester);

      expect(controller.selectMode, isTrue);
      expect(find.byKey(const ValueKey('recordings.select.cancel')), findsOneWidget);
    });

    testWidgets('cancel exits select mode', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats(total: 1, recordings: 1);
      await pumpScreen(tester);
      await tester.longPress(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('recordings.select.cancel')));
      await settle(tester);

      expect(controller.selectMode, isFalse);
      expect(find.byKey(const ValueKey('recordings.select.cancel')), findsNothing);
    });

    testWidgets('select all then batch delete removes every selected card', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'cam_b.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        ],
      });
      stubStats(total: 2, recordings: 2);
      await pumpScreen(tester);
      await tester.longPress(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey('recordings.select.all')));
      await settle(tester);
      expect(controller.selected, {'cam_a.mp4', 'cam_b.mp4'});

      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
      await tester.tap(find.byKey(const ValueKey('recordings.select.delete')));
      // The confirmation AlertDialog slides/fades in over a real animation
      // duration -- same reason as the filter sheet's own pumpAndSettle().
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recordings.confirmBatchDelete')));
      await settle(tester);

      expect(find.byKey(const ValueKey('recordings.card.cam_a.mp4')), findsNothing);
      expect(find.byKey(const ValueKey('recordings.card.cam_b.mp4')), findsNothing);
      expect(controller.selectMode, isFalse);
    });

    testWidgets('a batch delete failure shows the partial-failure toast', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats(total: 1, recordings: 1);
      await pumpScreen(tester);
      // A long-press already selects the pressed item -- with only one item
      // in the list, an additional "select all" tap would toggle it back
      // off (selectAllVisible deselects when everything is already
      // selected), so it is deliberately not tapped here.
      await tester.longPress(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
      await settle(tester);
      expect(controller.selected, {'cam_a.mp4'});

      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'locked'});
      await tester.tap(find.byKey(const ValueKey('recordings.select.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recordings.confirmBatchDelete')));
      await settle(tester);

      expect(find.textContaining('failed'), findsOneWidget);
      expect(find.byKey(const ValueKey('recordings.card.cam_a.mp4')), findsOneWidget);
    });

    testWidgets('tapping a card\'s own checkbox toggles its selection', (tester) async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats(total: 1, recordings: 1);
      await pumpScreen(tester);
      await tester.longPress(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
      await settle(tester);
      expect(controller.selected, {'cam_a.mp4'});

      await tester.tap(find.byType(Checkbox));
      await settle(tester);

      expect(controller.selected, isEmpty);
    });
  });

  testWidgets('deleting a single card via its delete button removes it after confirmation', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
    });
    stubStats(total: 1, recordings: 1);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.delete.cam_a.mp4')));
    await tester.pumpAndSettle();
    rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
    await tester.tap(find.byKey(const ValueKey('recordings.confirmDelete')));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.card.cam_a.mp4')), findsNothing);
  });

  testWidgets('tapping a card opens the player with the visible list as the playlist', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
    });
    stubStats(total: 1, recordings: 1);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.card.cam_a.mp4')));
    await settle(tester);

    expect(find.byType(RecordingsPlayerScreen), findsOneWidget);
  });

  testWidgets('section headers cover every time-of-day bucket', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'cam_evening.mp4',
          type: 'RECORDING_TYPE_NORMAL',
          timestampMs: DateTime(2026, 5, 23, 18).millisecondsSinceEpoch,
        ),
        _entry(
          filename: 'cam_night.mp4',
          type: 'RECORDING_TYPE_NORMAL',
          timestampMs: DateTime(2026, 5, 23, 2).millisecondsSinceEpoch,
        ),
      ],
    });
    stubStats(total: 2, recordings: 2);
    await pumpScreen(tester);

    expect(find.text('EVENING'), findsOneWidget);
    expect(find.text('NIGHT'), findsOneWidget);
  });

  testWidgets('every proximity band renders as label text on the card', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [
        _entry(
          filename: 'proximity_close.mp4',
          type: 'RECORDING_TYPE_PROXIMITY',
          timestampMs: now,
          proximity: 'CLOSE',
        ),
        _entry(
          filename: 'proximity_mid.mp4',
          type: 'RECORDING_TYPE_PROXIMITY',
          timestampMs: now,
          proximity: 'MID',
        ),
        _entry(
          filename: 'proximity_far.mp4',
          type: 'RECORDING_TYPE_PROXIMITY',
          timestampMs: now,
          proximity: 'FAR',
        ),
      ],
    });
    stubStats(total: 3, proximity: 3);
    await pumpScreen(tester);

    expect(find.textContaining('close'), findsOneWidget);
    expect(find.textContaining('mid'), findsOneWidget);
    expect(find.textContaining('far'), findsOneWidget);
  });

  testWidgets('the settings button invokes onOpenSettings', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': <dynamic>[]});
    stubStats();
    var tapped = false;
    await pumpScreen(tester, onOpenSettings: () => tapped = true);

    await tester.tap(find.byKey(const ValueKey('recordings.settings')));
    await settle(tester);

    expect(tapped, isTrue);
  });

  testWidgets('renders in dark theme without crashing', (tester) async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [_entry(filename: 'cam_a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
    });
    stubStats(total: 1, recordings: 1);
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: buildScreen(),
    ));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
