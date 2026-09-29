import 'dart:async';

import 'package:bladewatch_companion/screens/common/loader.dart';
import 'package:bladewatch_companion/screens/recordings/clip_pages.dart';
import 'package:bladewatch_companion/screens/recordings/recordings_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

RecordingEntry entry(String name) =>
    RecordingEntry(filename: name, type: RecordingType.RECORDING_TYPE_NORMAL, timestampMs: Int64(1700000000000), sizeBytes: Int64(2048));

/// [count] clips served [ClipPages]-style, 1-based pages; [fail] names pages that throw once.
class FakeLibrary {
  FakeLibrary(this.count, {Set<int>? fail}) : fail = {...?fail};

  final int count;
  final Set<int> fail;
  final asked = <int>[];

  Future<ListRecordingsResponse> page(int page, int size) async {
    asked.add(page);
    if (fail.remove(page)) throw const ConnectError('unavailable', 'dropped');
    final from = (page - 1) * size;
    final names = [for (var i = from; i < from + size && i < count; i++) 'c$i.mp4'];
    return ListRecordingsResponse(recordings: names.map(entry), total: count);
  }
}

void main() {
  test('days are keyed as the car names them, yyyy-MM-dd: anything else filters to nothing', () {
    expect(RecordingsScreen.dayKey(DateTime(2026, 9, 7)), '2026-09-07');
  });

  // BladeWatch-rdtj.42: the library used to be one request of 200.
  group('ClipPages', () {
    test('pages through every clip and stops at the total', () async {
      final lib = FakeLibrary(5);
      final pages = ClipPages(lib.page, pageSize: 2);
      await pages.more();
      expect((pages.clips.length, pages.total, pages.done), (2, 5, false));
      await pages.more();
      await pages.more();
      expect((pages.clips.length, pages.done), (5, true));
      await pages.more();
      expect(lib.asked, [1, 2, 3], reason: 'nothing asked past the end');
      expect(pages.clips.map((c) => c.filename), [for (var i = 0; i < 5; i++) 'c$i.mp4']);
    });

    test('a clip seen twice (the car recorded meanwhile) is shown once; an empty page ends it', () async {
      var n = 0;
      final pages = ClipPages(
        (page, size) async => switch (n++) {
          0 => ListRecordingsResponse(recordings: [entry('a'), entry('b')], total: 9),
          1 => ListRecordingsResponse(recordings: [entry('b'), entry('c')], total: 9),
          _ => ListRecordingsResponse(total: 9),
        },
        pageSize: 2,
      );
      await pages.more();
      await pages.more();
      expect(pages.clips.map((c) => c.filename), ['a', 'b', 'c']);
      await pages.more();
      expect(pages.done, isTrue, reason: 'an empty page ends the list whatever total says');
    });

    // BladeWatch-rdtj.70: a page of clips already here must end the list too, or the list asks for
    // page after page for as long as it is on screen.
    test('a page with nothing new ends the list', () async {
      var asked = 0;
      final pages = ClipPages((page, size) async {
        asked++;
        return ListRecordingsResponse(recordings: [entry('a'), entry('b')], total: 9);
      }, pageSize: 2);
      await pages.more();
      await pages.more();
      expect(pages.done, isTrue);
      await pages.more();
      expect(asked, 2);
    });

    test('a failed first page is an error; a failed later page keeps the clips and retries', () async {
      final lib = FakeLibrary(4, fail: {1, 2});
      final pages = ClipPages(lib.page, pageSize: 2);
      await pages.more();
      expect(pages.loaded, isFalse);
      expect(pages.error, isA<ConnectError>());
      await pages.reset();
      expect((pages.clips.length, pages.error), (2, null));
      await pages.more();
      expect((pages.clips.length, pages.pageFailed), (2, true));
      await pages.more();
      expect((pages.clips.length, pages.pageFailed, pages.done), (4, false, true));
    });

    test('remove drops a clip; reset during a fetch ignores what that fetch returns', () async {
      final slow = Completer<ListRecordingsResponse>();
      var first = true;
      final pages = ClipPages((page, size) {
        if (first) {
          first = false;
          return slow.future;
        }
        return Future.value(ListRecordingsResponse(recordings: [entry('new')], total: 1));
      });
      final stale = pages.more();
      await pages.reset();
      slow.complete(ListRecordingsResponse(recordings: [entry('old')], total: 1));
      await stale;
      expect(pages.clips.map((c) => c.filename), ['new']);
      pages.remove('new');
      pages.remove('absent');
      expect(pages.clips, isEmpty);
      expect(pages.total, 0);
      pages.dispose();
      pages.remove('x'); // after dispose: no listener is told
    });
  });

  group('ClipPageList', () {
    testWidgets('loads the next page when the end comes into view; a failed page offers retry', (tester) async {
      final lib = FakeLibrary(30, fail: {2});
      final pages = ClipPages(lib.page, pageSize: 15);
      await pages.more();
      await pumpScreen(tester, TestSession(), ClipPageList(pages: pages));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('clips.retry')), 300);
      expect(lib.asked, [1, 2]);
      await tester.tap(find.byKey(const ValueKey('clips.retry')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('clip.c29.mp4')), 300);
      expect(pages.done, isTrue);
      expect(find.byKey(const ValueKey('clips.more')), findsNothing);
      await unmount(tester);
    });

    testWidgets('a first page that fails shows retry; an empty library says so', (tester) async {
      final pages = ClipPages(FakeLibrary(0, fail: {1}).page);
      await pages.more();
      await pumpScreen(tester, TestSession(), ClipPageList(pages: pages));
      expect(find.text(t('common.retry')), findsOneWidget);
      await tester.tap(find.text(t('common.retry')));
      await tester.pumpAndSettle();
      expect(find.text(t('events.empty_none_title')), findsOneWidget);
      await unmount(tester);
    });
  });

  group('RecordingsScreen days', () {
    DateTime today() => DateTime(2026, 9, 27, 15);
    String? dateAsked(TestSession s) => (s.rpc.calls.lastWhere((c) => c.method == 'ListRecordings').request as ListRecordingsRequest).date;

    void stub(TestSession s, {List<String>? dates}) {
      s.rpc.stubJson('RecordingsService', 'GetStats', {'stats': {'totalCount': 1}});
      if (dates == null) {
        s.rpc.stubError('RecordingsService', 'GetDates', const ConnectError('unimplemented', 'old car'));
      } else {
        s.rpc.stubJson('RecordingsService', 'GetDates', {'dates': dates});
      }
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    }

    testWidgets('today, yesterday and all; the arrows skip days with no clips and stop at today', (tester) async {
      final s = TestSession();
      stub(s, dates: ['2026-09-27', '2026-09-20', '2026-09-25']);
      await pumpScreen(tester, s, RecordingsScreen(today: today));
      expect(dateAsked(s), '', reason: 'every day to start with');
      expect(find.byKey(const ValueKey('rec.day.previous')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('rec.day.today')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-27');
      IconButton arrow(String k) => tester.widget<IconButton>(find.byKey(ValueKey('rec.day.$k')));
      expect(arrow('next').onPressed, isNull, reason: 'nothing after today');

      await tester.tap(find.byKey(const ValueKey('rec.day.previous')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-25', reason: 'the 26th has no clips');
      await tester.tap(find.byKey(const ValueKey('rec.day.previous')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-20');
      expect(arrow('previous').onPressed, isNull, reason: 'no earlier day has clips');
      await tester.tap(find.byKey(const ValueKey('rec.day.next')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-25');

      await tester.tap(find.byKey(const ValueKey('rec.day.yesterday')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-26');
      await tester.tap(find.byKey(const ValueKey('rec.type.sentry')));
      await tester.pumpAndSettle();
      final r = s.rpc.calls.lastWhere((c) => c.method == 'ListRecordings').request as ListRecordingsRequest;
      expect((r.type, r.date, r.page), ('sentry', '2026-09-26', 1), reason: 'type and day together, from page 1');
      await tester.tap(find.byKey(const ValueKey('rec.day.all')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '');
      await unmount(tester);
    });

    testWidgets('without the car\'s list of days the arrows step one day', (tester) async {
      final s = TestSession();
      stub(s);
      await pumpScreen(tester, s, RecordingsScreen(today: today));
      await tester.tap(find.byKey(const ValueKey('rec.day.yesterday')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.day.previous')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-25');
      await tester.tap(find.byKey(const ValueKey('rec.day.next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.day.next')));
      await tester.pumpAndSettle();
      expect(dateAsked(s), '2026-09-27');
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('rec.day.next'))).onPressed, isNull);
      await unmount(tester);
    });
  });

  // BladeWatch-rdtj.43: the web's who/severity chips and delete-several.
  group('RecordingsScreen filters and picking', () {
    Map<String, Object?> clipJson(String name) => {'filename': name, 'type': 'RECORDING_TYPE_SENTRY', 'timestamp': '1700000000000'};

    TestSession library(List<String> names) {
      final s = TestSession();
      s.rpc.stubJson('RecordingsService', 'GetStats', {'stats': {'totalCount': names.length}});
      s.rpc.stubJson('RecordingsService', 'GetDates', {'dates': []});
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [for (final n in names) clipJson(n)], 'total': names.length});
      return s;
    }

    ListRecordingsRequest asked(TestSession s) => s.rpc.calls.lastWhere((c) => c.method == 'ListRecordings').request as ListRecordingsRequest;

    testWidgets('who and severity narrow surveillance clips on the car; reset and other types clear them', (tester) async {
      final s = library(['a.mp4']);
      await pumpScreen(tester, s, const RecordingsScreen());
      expect(find.byKey(const ValueKey('rec.filter.person')), findsNothing, reason: 'surveillance only');
      await tester.tap(find.byKey(const ValueKey('rec.type.sentry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.filter.person')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.filter.animal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.filter.CRITICAL')));
      await tester.pumpAndSettle();
      expect((asked(s).classFilter, asked(s).severityFilter, asked(s).page), ('person,animal', 'CRITICAL', 1));
      await tester.tap(find.byKey(const ValueKey('rec.filter.animal')));
      await tester.pumpAndSettle();
      expect(asked(s).classFilter, 'person');

      await tester.tap(find.byKey(const ValueKey('rec.filter.reset')));
      await tester.pumpAndSettle();
      expect((asked(s).classFilter, asked(s).severityFilter), ('', ''));
      expect(find.byKey(const ValueKey('rec.filter.reset')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('rec.filter.bike')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.type.normal')));
      await tester.pumpAndSettle();
      expect((asked(s).type, asked(s).classFilter), ('normal', ''), reason: 'filters belong to surveillance clips');
      await tester.tap(find.byKey(const ValueKey('rec.type.sentry')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(find.byKey(const ValueKey('rec.filter.bike'))).selected, isFalse);
      await unmount(tester);
    });

    testWidgets('pick several, confirm once, and they go in one BatchDelete; cancel deletes nothing', (tester) async {
      final s = library(['a.mp4', 'b.mp4', 'c.mp4']);
      s.rpc.stubJson('RecordingsService', 'BatchDelete', {'success': true, 'deleted': 2});
      await pumpScreen(tester, s, const RecordingsScreen(), size: const Size(420, 1400));
      await tester.tap(find.byKey(const ValueKey('rec.select')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clip.delete.a.mp4')), findsNothing, reason: 'no per-clip delete while picking');
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('rec.delete_picked'))).onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('clip.a.mp4'))); // the row ticks, it does not play
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('clip.check.b.mp4')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.selected_count', {'count': 2})), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rec.select_all')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.selected_count', {'count': 3})), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('rec.select_all')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.selected_count', {'count': 0})), findsOneWidget, reason: 'deselect all');
      for (final name in ['a', 'b', 'c', 'c']) { // c unticked again
        await tester.tap(find.byKey(ValueKey('clip.check.$name.mp4')));
        await tester.pump();
      }

      await tester.tap(find.byKey(const ValueKey('rec.delete_picked')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.delete_selected_confirm', {'count': 2})), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(t('common.cancel'))));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'BatchDelete'), isEmpty);

      await tester.tap(find.byKey(const ValueKey('rec.delete_picked')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete.confirm')));
      await tester.pumpAndSettle();
      final req = s.rpc.calls.lastWhere((c) => c.method == 'BatchDelete').request as BatchDeleteRequest;
      expect(req.filenames.toSet(), {'a.mp4', 'b.mp4'});
      expect(find.text(t('companion.batch_deleted', {'count': 2})), findsOneWidget);
      expect(find.byKey(const ValueKey('clip.a.mp4')), findsNothing);
      expect(find.byKey(const ValueKey('clip.c.mp4')), findsOneWidget);
      expect(find.byKey(const ValueKey('rec.select')), findsOneWidget, reason: 'picking ends');
      await unmount(tester);
    });

    testWidgets('when some could not be deleted it says how many, and reloads', (tester) async {
      final s = library(['a.mp4', 'b.mp4']);
      s.rpc.stubJson('RecordingsService', 'BatchDelete', {'success': false, 'deleted': 1, 'failed': 1});
      await pumpScreen(tester, s, const RecordingsScreen());
      await tester.tap(find.byKey(const ValueKey('rec.select')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.select_all')));
      await tester.pumpAndSettle();
      final before = s.rpc.calls.where((c) => c.method == 'ListRecordings').length;
      await tester.tap(find.byKey(const ValueKey('rec.delete_picked')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.batch_delete_partial', {'deleted': 1, 'failed': 1})), findsOneWidget);
      expect(s.rpc.calls.where((c) => c.method == 'ListRecordings').length, greaterThan(before));

      await tester.tap(find.byKey(const ValueKey('rec.select')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.select_cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('rec.select')), findsOneWidget);
      s.rpc.stubError('RecordingsService', 'BatchDelete', const ConnectError('unavailable', 'x'));
      await tester.tap(find.byKey(const ValueKey('rec.select')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.select_all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rec.delete_picked')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('events.alert_delete_failed_generic')), findsOneWidget);
      await unmount(tester);
    });
  });

  // BladeWatch-rdtj.56: the design language's spacing tokens, and a reading width on desktops.
  group('layout', () {
    testWidgets('a page uses the token gutters; the clip list stops at the content width', (tester) async {
      await pumpScreen(tester, TestSession(), const PageList(children: [Section(title: 'T', children: [Text('x', key: ValueKey('body'))])]));
      expect(tester.getTopLeft(find.byType(Card)).dx, BwDimens.pagePaddingHorizontal);
      expect(tester.getTopLeft(find.byKey(const ValueKey('body'))).dx, BwDimens.pagePaddingHorizontal + BwDimens.cardPaddingStandard);
      await unmount(tester);

      final s = TestSession();
      s.rpc.stubJson('RecordingsService', 'GetStats', {'stats': {'totalCount': 1}});
      s.rpc.stubJson('RecordingsService', 'GetDates', {'dates': []});
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [{'filename': 'a.mp4', 'timestamp': '1700000000000'}], 'total': 1});
      await pumpScreen(tester, s, const RecordingsScreen(), size: const Size(1600, 1000));
      expect(tester.getSize(find.byKey(const ValueKey('clip.a.mp4'))).width, contentMaxWidth);
      await unmount(tester);
    });
  });
}
