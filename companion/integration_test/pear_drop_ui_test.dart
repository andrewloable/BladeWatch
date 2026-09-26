// ignore_for_file: avoid_print -- this test's output IS the measurement
/// BladeWatch-tayl on real hardware: do live view and playback ride out a real Pear drop?
///
/// Mounts the real [LiveScreen], then the real [ClipPlayerScreen], on a [CarSession] with the LAN
/// route switched off, while a script on the car kills pear_daemon on a schedule (the same drop as
/// pear_drop_test.dart). It logs:
/// - every still the live view gets, with the phase changes, so the time from "route back" to
///   "picture again" can be read off (the plan: within 5 s);
/// - the player's position every second, so a resume can be checked against where it was.
///
///     flutter test integration_test/pear_drop_ui_test.dart -d macos \
///       --dart-define=BW_DIR=<dir> --dart-define=BW_FILE=<clip name> \
///       [--dart-define=BW_LIVE_S=240] [--dart-define=BW_PLAY_S=240]
///
/// BW_DIR is pear_bench_test's directory (bench.json holds the pairing and the credential).
///
/// On macOS the run can end in "A SemanticsHandle was active at the end of the test" when an
/// accessibility client switched semantics on mid-run: testWidgets' end-of-test check, after every
/// measurement has printed (semanticsEnabled: false does not prevent it). Read the JSON lines.
library;

import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/car/car_page.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/live/live_screen.dart';
import 'package:bladewatch_companion/screens/recordings/clips.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

const _dir = String.fromEnvironment('BW_DIR');
const _file = String.fromEnvironment('BW_FILE');
const _liveS = int.fromEnvironment('BW_LIVE_S', defaultValue: 240);
const _playS = int.fromEnvironment('BW_PLAY_S', defaultValue: 240);

final _t0 = DateTime.now();
double _t() => DateTime.now().difference(_t0).inMilliseconds / 1000;
void _emit(Map<String, Object?> line) => print(jsonEncode({'t_s': _t(), ...line}));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live view and playback ride out a real Pear drop', (tester) async {
    final saved = jsonDecode(File('$_dir/bench.json').readAsStringSync()) as Map<String, dynamic>;
    final car = PairedCar.fromPairing(
      PairingPayload.decode(saved['qr'] as String),
      CompanionCredential(saved['companionId'] as String, saved['token'] as String),
    );
    final tr = await Tr.load(rootBundle, 'en');
    final session = await CarSession.open(car, findOnLan: () async => null, networkChanges: const Stream.empty());
    var phase = session.phase;
    void onChange() {
      if (session.phase == phase) return;
      phase = session.phase;
      _emit({'phase': phase.name});
    }

    session.addListener(onChange);

    Future<void> show(Widget child) => tester.pumpWidget(MaterialApp(
          builder: (context, nav) => TrScope(tr: tr, child: nav!),
          home: SessionScope(session: session, child: Scaffold(body: child)),
        ));

    // Real timers, not tester.pump: a macOS window that is covered or in the background stops
    // producing frames, and pump waits for one. Only mounting a screen needs a frame -- keep the
    // test window visible while a screen is swapped in.
    Future<void> run(int seconds, void Function() sample) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        sample();
      }
    }

    try {
      while (session.phase != TransportPhase.pear) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      // Live view: every still it gets. The picture after a drop is the first 'still' after the
      // phase is back at pear.
      await show(LiveScreen(fetch: (s) async {
        final r = await fetchMedia(s, '/api/stream/still');
        if (r.ok) _emit({'still': r.bytes.length});
        return r;
      }));
      await run(_liveS, () {});

      // Playback: the position every second, read off the player itself (the onPlayer seam).
      VideoPlayerController? player;
      await show(ClipPlayerScreen(
        filename: _file,
        canPlay: true,
        onPlayer: (c) {
          player = c;
          _emit({'play': 'new player'});
        },
      ));
      var lastLogged = -1;
      await run(_playS, () {
        final second = _t().floor();
        if (second == lastLogged) return;
        lastLogged = second;
        final p = player;
        if (p == null) {
          _emit({'play': 'waiting'});
        } else {
          final v = p.value;
          _emit({
            'play_pos_s': v.position.inMilliseconds / 1000,
            'playing': v.isPlaying,
            'buffering': v.isBuffering,
            if (v.hasError) 'error': v.errorDescription,
          });
        }
      });
    } finally {
      session.removeListener(onChange);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    }
  }, skip: _dir.isEmpty || _file.isEmpty, semanticsEnabled: false, timeout: const Timeout(Duration(minutes: 20)));
}
