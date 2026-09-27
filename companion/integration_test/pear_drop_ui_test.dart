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
import 'package:intl/date_symbol_data_local.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';

const _dir = String.fromEnvironment('BW_DIR');
const _file = String.fromEnvironment('BW_FILE');
const _liveS = int.fromEnvironment('BW_LIVE_S', defaultValue: 240);
const _playS = int.fromEnvironment('BW_PLAY_S', defaultValue: 240);

/// BW_TRACE: put a logging proxy between the player and the gateway -- every request line and
/// Range header, and each connection's response bytes over time (BladeWatch-rdtj.28).
const _trace = bool.fromEnvironment('BW_TRACE');

/// BW_BASE: play from this base URL instead of the car (e.g. a local throttled server), to tell the
/// player's own start rules apart from the Pear path (BladeWatch-rdtj.28).
const _base = String.fromEnvironment('BW_BASE');

final _t0 = DateTime.now();
double _t() => DateTime.now().difference(_t0).inMilliseconds / 1000;
void _emit(Map<String, Object?> line) => print(jsonEncode({'t_s': _t(), ...line}));

void main() {
  // Frames as a real app renders them: the default policy draws only when the test pumps, and the
  // player's video output is consumed by rendered frames (BladeWatch-rdtj.28).
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('live view and playback ride out a real Pear drop', (tester) async {
    await initializeDateFormatting(); // as main() does: the Live page formats times by locale
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
      await show(LiveScreen(fetch: (s, path) async {
        final r = await fetchMedia(s, path);
        if (r.ok) _emit({'still': r.bytes.length});
        return r;
      }));
      await run(_liveS, () {});

      // Playback: the position every second, read off the player itself (the onPlayer seam).
      VideoPlayerController? player;
      final playSession = _base.isNotEmpty
          ? CarSession(rpc: session.rpc, baseUrl: Uri.parse(_base), jwt: () async => null, initialPhase: TransportPhase.pear)
          : _trace
              ? await _tracingSession(session)
              : session;
      Future<void> showPlayer(Widget child) => tester.pumpWidget(MaterialApp(
            builder: (context, nav) => TrScope(tr: tr, child: nav!),
            home: SessionScope(session: playSession, child: Scaffold(body: child)),
          ));
      await showPlayer(ClipPlayerScreen(
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
            'buffered_s': v.buffered.isEmpty ? 0 : v.buffered.last.end.inMilliseconds / 1000,
            // BladeWatch-rdtj.31: the "slower than this clip" line, shown after 5 s without moving.
            'slow_hint': find.byKey(const ValueKey('player.slow')).evaluate().isNotEmpty,
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

/// A session whose base URL is a logging proxy in front of [real]'s gateway (BW_TRACE only).
Future<CarSession> _tracingSession(CarSession real) async {
  final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  var connections = 0;
  proxy.listen((client) async {
    final n = ++connections;
    final opened = _t();
    final upstream = await Socket.connect(real.baseUrl.host, real.baseUrl.port);
    var head = <int>[];
    client.listen((bytes) {
      head.addAll(bytes);
      var end = _indexOf(head, const [13, 10, 13, 10]);
      while (end >= 0) {
        final lines = String.fromCharCodes(head.sublist(0, end)).split('\r\n');
        final range = lines.firstWhere((l) => l.toLowerCase().startsWith('range:'), orElse: () => '');
        _emit({'conn': n, 'request': lines.first, if (range.isNotEmpty) 'range': range.substring(6).trim()});
        head = head.sublist(end + 4);
        end = _indexOf(head, const [13, 10, 13, 10]);
      }
      upstream.add(bytes);
    }, onDone: () => upstream.destroy(), onError: (Object _) => upstream.destroy());
    var received = 0;
    var nextMark = 0;
    var statusLogged = false;
    upstream.listen((bytes) {
      if (!statusLogged) {
        statusLogged = true;
        final text = String.fromCharCodes(bytes.take(200));
        _emit({'conn': n, 'status': text.split('\r\n').first, 'first_byte_after_s': _t() - opened});
      }
      if (received < 131072) {
        File('$_dir/trace_conn$n.bin').writeAsBytesSync(bytes, mode: FileMode.append);
      }
      received += bytes.length;
      if (received >= nextMark) {
        _emit({'conn': n, 'received_mb': received / 1048576});
        nextMark += 8 * 1048576;
      }
      client.add(bytes);
    }, onDone: () {
      _emit({'conn': n, 'closed_after_mb': received / 1048576});
      client.destroy();
    }, onError: (Object _) => client.destroy());
  });
  final header = (await real.authHeaders())['Authorization'];
  return CarSession(
    rpc: real.rpc,
    baseUrl: Uri.parse('http://127.0.0.1:${proxy.port}'),
    jwt: () async => header?.substring('Bearer '.length),
    initialPhase: TransportPhase.pear,
  );
}

int _indexOf(List<int> hay, List<int> needle) {
  for (var i = 0; i + needle.length <= hay.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}
