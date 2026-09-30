import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_controller.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_player_screen.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import '../../fakes/fake_video_player_platform.dart';
import '../../fakes/hud_test_env.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:bladewatch_ui/widgets/hud_widgets.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'jwt-1';
  @override
  Future<int> stateVersion() async => 0;
}

Map<String, dynamic> _entry(String filename, {String type = 'RECORDING_TYPE_NORMAL', int timestampMs = 0, List<String> seen = const []}) => {
      'filename': filename,
      'path': '/storage/emulated/0/BladeWatch/recordings/$filename',
      'type': type,
      'timestamp': timestampMs.toString(),
      'size': '1500',
      'durationSeconds': '60',
      'detectedClasses': seen,
    };

/// BladeWatch-rdtj.70: the library as the companion presents it, a page at a time.
void main() {
  hudTestEnvironment();
  late FakeRpcClient rpc;
  late RecordingsController controller;
  final now = DateTime(2026, 5, 23, 15, 0).millisecondsSinceEpoch;

  void page(List<Map<String, dynamic>> entries, {int? total}) =>
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': entries, 'total': total ?? entries.length});

  List<ListRecordingsRequest> listCalls() =>
      [for (final call in rpc.calls.where((c) => c.method == 'ListRecordings')) call.request as ListRecordingsRequest];

  setUp(() {
    FakeVideoPlayerPlatform.install();
    rpc = FakeRpcClient();
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'totalCount': 1042, 'totalSizeBytes': '113100000000'},
    });
    rpc.stubJson('RecordingsService', 'GetDates', {
      'dates': ['2026-05-20', '2026-05-23'],
    });
    controller = RecordingsController(recordingsService: RecordingsServiceClient(rpc), nowMs: () => now, pageSize: 3);
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

  Future<void> pumpScreen(WidgetTester tester, {VoidCallback? onOpenSettings, Size size = const Size(1920, 1080)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(buildScreen(onOpenSettings: onOpenSettings)));
    await settle(tester);
  }

  testWidgets('rows as the companion shows them, with the totals and the Settings shortcut', (tester) async {
    page([_entry('event_1.mp4', type: 'RECORDING_TYPE_SENTRY', timestampMs: now, seen: ['person', 'vehicle'])]);
    var settings = 0;
    await pumpScreen(tester, onOpenSettings: () => settings++);

    expect(find.byKey(const ValueKey('recordings.row.event_1.mp4')), findsOneWidget);
    expect(find.text('Surveillance · 1:00 · 1.5 KB · person, vehicle'), findsOneWidget);
    expect(find.textContaining('May 23, 2026'), findsOneWidget);
    expect(find.text('1042 clips · 113.1 GB'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recordings.settings')));
    expect(settings, 1);
  });

  // BladeWatch-2llu.2: the library is on the HUD skin.
  group('HUD skin', () {
    testWidgets('the page has a HUD title bar with the totals; a row is a 4 dp HUD panel', (tester) async {
      page([_entry('a.mp4', timestampMs: now)]);
      await pumpScreen(tester);
      expect(find.byType(HudTitleBar), findsOneWidget);
      expect(find.text('RECORDINGS'), findsOneWidget);
      final stats = tester.widget<Text>(find.byKey(const ValueKey('recordings.stats')));
      expect((stats.style!.fontSize, stats.style!.color), (12, BwHud.light.statLabel));
      final row = tester.widget<HudPanel>(find.descendant(of: find.byKey(const ValueKey('recordings.row.a.mp4')), matching: find.byType(HudPanel)).first);
      expect((row.color, row.borderColor, row.radius), (BwHud.light.panel, BwHud.light.panelBorder, 4));
      // The delete control is the magenta (attention) icon.
      expect(tester.widget<Icon>(find.descendant(of: find.byKey(const ValueKey('recordings.delete.a.mp4')), matching: find.byType(Icon))).color, BwHud.light.magenta);
    });

    testWidgets('the clip in the detail pane is the accent border on the soft fill; the empty pane is a HUD panel', (tester) async {
      page([_entry('a.mp4', timestampMs: now), _entry('b.mp4', timestampMs: now)]);
      await pumpScreen(tester);
      final empty = tester.widget<HudPanel>(find.byKey(const ValueKey('recordings.detail.empty')));
      expect((empty.borderColor, empty.radius), (BwHud.light.panelBorder, 4));
      expect(find.text('SELECT A RECORDING'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recordings.row.a.mp4')));
      await settle(tester);
      HudPanel rowPanel(String f) => tester.widget<HudPanel>(find.descendant(of: find.byKey(ValueKey('recordings.row.$f')), matching: find.byType(HudPanel)).first);
      expect((rowPanel('a.mp4').borderColor, rowPanel('a.mp4').color), (BwHud.light.accent, Color.alphaBlend(BwHud.light.viewAllFill, BwHud.light.panel)));
      expect(rowPanel('b.mp4').borderColor, BwHud.light.panelBorder);
    });

    testWidgets('the sentry filters carry upper-case accent section labels', (tester) async {
      page([_entry('a.mp4')]);
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('recordings.type.sentry')));
      await settle(tester);
      final what = tester.widget<Text>(find.text('WHAT'));
      expect((what.style!.fontSize, what.style!.color, what.style!.fontWeight), (12, BwHud.light.accent, FontWeight.w700));
      expect(find.text('SEVERITY'), findsOneWidget);
    });

    testWidgets('the error state is the HUD error state with a working retry', (tester) async {
      rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'down'));
      await pumpScreen(tester);
      expect(find.byType(HudErrorState), findsOneWidget);
      page([_entry('a.mp4')]);
      await tester.tap(find.text('Retry'));
      await settle(tester);
      expect(find.byKey(const ValueKey('recordings.row.a.mp4')), findsOneWidget);
    });
  });

  testWidgets('the type chips ask the car, and sentry adds who and how bad', (tester) async {
    page([_entry('a.mp4')]);
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('recordings.filter.person')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recordings.type.sentry')));
    await settle(tester);
    expect(listCalls().last.type, 'sentry');
    await tester.tap(find.byKey(const ValueKey('recordings.filter.person')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.filter.CRITICAL')));
    await settle(tester);
    final r = listCalls().last;
    expect((r.classFilter, r.severityFilter, r.page), ('person', 'CRITICAL', 1));

    await tester.tap(find.byKey(const ValueKey('recordings.filter.reset')));
    await settle(tester);
    expect(listCalls().last.classFilter, '');
    expect(find.byKey(const ValueKey('recordings.filter.reset')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recordings.type.proximity')));
    await settle(tester);
    expect(listCalls().last.type, 'proximity');
    expect(find.byKey(const ValueKey('recordings.filter.person')), findsNothing);
  });

  testWidgets('a day, its arrows over the days with clips, and every day again', (tester) async {
    page([_entry('a.mp4')]);
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('recordings.day.previous')), findsNothing, reason: 'every day by default');

    await tester.tap(find.byKey(const ValueKey('recordings.day.today')));
    await settle(tester);
    expect(listCalls().last.date, '2026-05-23');
    expect(find.text('May 23, 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('recordings.day.next'))).onPressed, isNull, reason: 'never past today');

    await tester.tap(find.byKey(const ValueKey('recordings.day.previous')));
    await settle(tester);
    expect(listCalls().last.date, '2026-05-20', reason: 'skips the days without clips');

    await tester.tap(find.byKey(const ValueKey('recordings.day.yesterday')));
    await settle(tester);
    expect(listCalls().last.date, '2026-05-22');

    await tester.tap(find.byKey(const ValueKey('recordings.day.all')));
    await settle(tester);
    expect(listCalls().last.date, '');
    expect(find.byKey(const ValueKey('recordings.day.label')), findsNothing);
  });

  testWidgets('select, select all, and delete them together', (tester) async {
    page([_entry('a.mp4'), _entry('b.mp4')]);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('recordings.select')));
    await settle(tester);
    expect(find.text('0 selected'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('recordings.select.delete'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('recordings.row.a.mp4')));
    await settle(tester);
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recordings.select.all')));
    await settle(tester);
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Deselect all'), findsOneWidget);

    rpc.stubJson('RecordingsService', 'BatchDelete', {'deleted': 2, 'failed': 0});
    await tester.tap(find.byKey(const ValueKey('recordings.select.delete')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.confirmBatchDelete')));
    await settle(tester);
    expect((rpc.calls.lastWhere((c) => c.method == 'BatchDelete').request as BatchDeleteRequest).filenames, ['a.mp4', 'b.mp4']);
    expect(find.text('2 recordings deleted'), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.empty')), findsOneWidget);
  });

  testWidgets('a partly failed batch delete says so; cancel leaves select mode', (tester) async {
    page([_entry('a.mp4'), _entry('b.mp4')]);
    await pumpScreen(tester);
    await tester.longPress(find.byKey(const ValueKey('recordings.row.a.mp4')));
    await settle(tester);
    expect(find.text('1 selected'), findsOneWidget, reason: 'a long press starts selecting with that clip');
    await tester.tap(find.byKey(const ValueKey('recordings.check.b.mp4')));
    await settle(tester);

    rpc.stubJson('RecordingsService', 'BatchDelete', {'deleted': 1, 'failed': 1});
    await tester.tap(find.byKey(const ValueKey('recordings.select.delete')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.confirmBatchDelete')));
    await settle(tester);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.select')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.select.cancel')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.select')), findsOneWidget);
  });

  testWidgets('one clip deleted from its row, after confirming', (tester) async {
    page([_entry('a.mp4'), _entry('b.mp4')]);
    await pumpScreen(tester);
    rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
    await tester.tap(find.byKey(const ValueKey('recordings.delete.a.mp4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.confirmDelete')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.row.a.mp4')), findsNothing);
    expect(find.byKey(const ValueKey('recordings.row.b.mp4')), findsOneWidget);

    rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'locked'});
    await tester.tap(find.byKey(const ValueKey('recordings.delete.b.mp4')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('recordings.confirmDelete')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.row.b.mp4')), findsOneWidget);
  });

  testWidgets('the next page loads at the end of the list, with a retry when it fails', (tester) async {
    page([_entry('a.mp4'), _entry('b.mp4'), _entry('c.mp4')], total: 5);
    await pumpScreen(tester);
    expect(listCalls(), hasLength(2), reason: 'the end of a short list is on screen: page 2 at once');
    expect(listCalls().last.page, 2);
    expect(find.byKey(const ValueKey('recordings.more.loading')), findsNothing, reason: 'page 2 held nothing new: the end');

    rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'down'));
    await controller.reset();
    page([_entry('a.mp4'), _entry('b.mp4'), _entry('c.mp4')], total: 5);
    await controller.reset();
    rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'down'));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.more.retry')), findsOneWidget);

    page([_entry('d.mp4'), _entry('e.mp4')], total: 5);
    await tester.tap(find.byKey(const ValueKey('recordings.more.retry')));
    await settle(tester);
    expect(listCalls().last.page, 2);
    expect(find.byKey(const ValueKey('recordings.row.e.mp4')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.more.loading')), findsNothing, reason: 'all 5 here');
  });

  testWidgets('empty states say what is empty; a failed first page offers a retry', (tester) async {
    page([]);
    await pumpScreen(tester);
    expect(find.text('NO RECORDINGS'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recordings.type.sentry')));
    await settle(tester);
    expect(find.text('NO SENTRY EVENTS'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recordings.type.normal')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recordings.type.proximity')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.select')), findsNothing, reason: 'nothing to select');

    rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'down'));
    await tester.tap(find.byKey(const ValueKey('recordings.type.')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.error')), findsOneWidget);
    page([_entry('a.mp4')]);
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.row.a.mp4')), findsOneWidget);
  });

  testWidgets('tapping a row plays it in the pane, keeping the list; closing restores the placeholder', (tester) async {
    page([_entry('cam_a.mp4', timestampMs: now), _entry('cam_b.mp4', timestampMs: now)]);
    await pumpScreen(tester);
    expect(find.byKey(const ValueKey('recordings.detail.empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.row.cam_a.mp4')));
    await settle(tester);
    expect(find.byType(RecordingsPlayerScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.row.cam_a.mp4')), findsOneWidget, reason: 'the list stays');
    ListTile tile(String name) => tester.widget<ListTile>(find.descendant(of: find.byKey(ValueKey('recordings.row.$name')), matching: find.byType(ListTile)));
    expect(tile('cam_a.mp4').selected, isTrue);
    expect(tile('cam_b.mp4').selected, isFalse);

    await tester.tap(find.byKey(const ValueKey('recordings.row.cam_b.mp4')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.detail.cam_b.mp4')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.player.back')));
    await settle(tester);
    expect(find.byType(RecordingsPlayerScreen), findsNothing);
    expect(find.byKey(const ValueKey('recordings.detail.empty')), findsOneWidget);
  });

  testWidgets('below the breakpoint tapping a row pushes the full-screen player', (tester) async {
    page([_entry('cam_a.mp4', timestampMs: now)]);
    await pumpScreen(tester, size: const Size(800, 2200));
    expect(find.byKey(const ValueKey('recordings.detail.empty')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recordings.row.cam_a.mp4')));
    await tester.pumpAndSettle();
    expect(find.byType(RecordingsPlayerScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.row.cam_a.mp4')), findsNothing);
  });
}
