// ignore_for_file: avoid_print -- this test's output IS the measurement
/// BladeWatch-tayl on real hardware: does a clip download survive a real Pear drop?
///
/// Opens the companion's own [CarSession] with the LAN route switched off, so every byte crosses
/// Pear, then downloads one clip over and over with the app's [downloadMedia] until the window
/// closes. The drop comes from the car's side: a script started on the car beforehand kills
/// pear_daemon at fixed times, and the car's health check relaunches it within ~30 s. Every
/// completed download is checked against the size and SHA-256 taken on the car, so a resume that
/// splices bytes wrongly fails here rather than passing as "completed".
///
///     flutter test integration_test/pear_drop_test.dart -d macos \
///       --dart-define=BW_DIR=<dir> --dart-define=BW_FILE=<clip name> \
///       --dart-define=BW_SIZE=<bytes> --dart-define=BW_SHA256=<hex> [--dart-define=BW_WINDOW_S=600]
///
/// BW_DIR is pear_bench_test's directory: its bench.json holds the pairing and the credential.
/// Run it from a network that is NOT the car's (a phone hotspot).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_pear/flutter_pear.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _dir = String.fromEnvironment('BW_DIR');
const _file = String.fromEnvironment('BW_FILE');
const _size = int.fromEnvironment('BW_SIZE');
const _sha256 = String.fromEnvironment('BW_SHA256');
const _windowS = int.fromEnvironment('BW_WINDOW_S', defaultValue: 600);
const _freshPear = bool.fromEnvironment('BW_FRESH_PEAR');

final _t0 = DateTime.now();
void _emit(Map<String, Object?> line) =>
    print(jsonEncode({'t_s': DateTime.now().difference(_t0).inMilliseconds / 1000, ...line}));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A plain test(), not testWidgets(): see pear_bench_test.
  test('clip downloads survive a real Pear drop', () async {
    final saved = jsonDecode(File('$_dir/bench.json').readAsStringSync()) as Map<String, dynamic>;
    final car = PairedCar.fromPairing(
      PairingPayload.decode(saved['qr'] as String),
      CompanionCredential(saved['companionId'] as String, saved['token'] as String),
    );
    // Observe the swarm without changing it: its state, and how many connections it has seen.
    // Never listen to swarm.connections here -- only its FIRST listener gets the replay of
    // connections that already exist, and the session must stay that listener.
    Pear? pear;
    Timer? probe;
    final session = await CarSession.open(
      car,
      findOnLan: () async => null,
      networkChanges: const Stream.empty(),
      joinTopic: (topic) async {
        // BW_FRESH_PEAR: a new worklet per join (diagnosis for BladeWatch-rdtj.24).
        if (_freshPear) {
          probe?.cancel();
          await pear?.dispose();
          pear = null;
        }
        final s = await (pear ??= await Pear.start()).join(topic, announce: false);
        s.state.listen((st) => _emit({'swarm': st.state.name, if (st.error != null) 'error': st.error!.code}));
        var seen = 0;
        probe = Timer.periodic(const Duration(seconds: 1), (_) {
          final n = s.establishedConnections.length;
          if (n != seen) _emit({'swarm_connections_seen': seen = n});
        });
        return s;
      },
    );
    var lastPhase = session.phase;
    void onChange() {
      if (session.phase == lastPhase) return;
      lastPhase = session.phase;
      _emit({'phase': lastPhase.name});
    }

    session.addListener(onChange);
    final dest = File('$_dir/clip.mp4');
    var ok = 0, failed = 0, corrupt = 0;
    try {
      final end = DateTime.now().add(const Duration(seconds: _windowS));
      while (DateTime.now().isBefore(end)) {
        if (session.phase != TransportPhase.pear) {
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        final started = Stopwatch()..start();
        final done = await downloadMedia(session, '/video/${Uri.encodeComponent(_file)}', dest);
        final ms = started.elapsedMilliseconds;
        if (!done) {
          failed++;
          _emit({'download': 'failed', 'ms': ms, 'phase': session.phase.name});
          continue;
        }
        final bytes = dest.lengthSync();
        final sha = sha256.convert(dest.readAsBytesSync()).toString();
        final intact = bytes == _size && sha == _sha256;
        intact ? ok++ : corrupt++;
        _emit({'download': intact ? 'ok' : 'CORRUPT', 'ms': ms, 'bytes': bytes, 'mbit_s': bytes * 8 / ms / 1000});
        dest.deleteSync();
      }
    } finally {
      probe?.cancel();
      session.removeListener(onChange);
      session.dispose();
      await pear?.dispose();
      if (dest.existsSync()) dest.deleteSync();
    }
    _emit({'summary': true, 'ok': ok, 'failed': failed, 'corrupt': corrupt});
    expect(corrupt, 0, reason: 'a resumed download must be byte-exact');
  }, skip: _dir.isEmpty || _file.isEmpty, timeout: const Timeout(Duration(minutes: 30)));
}
