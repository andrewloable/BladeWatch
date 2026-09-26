// ignore_for_file: avoid_print -- this test's output IS the measurement
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/inbox_sync.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/local_gateway.dart';
import 'package:bladewatch_companion/transport/pear_link.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:bladewatch_rpc/rpc/connect_client.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_pear/flutter_pear.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// BladeWatch-rdtj.18/.19: the Pear path of docs/throughput-harness.md.
///
/// Opens the companion's own LocalGateway with the route FORCED to Pear (the LAN is never probed)
/// and runs the unchanged harness, tools/throughput/Throughput.java, through it -- the same code
/// that took the loopback and LAN baselines. Then what only a companion can measure: cold start
/// (Pear start to first status, the DHT lookup included), a dashboard-shaped burst of concurrent
/// calls, and thumbnails. Every result line is one JSON object.
///
/// Run it from a network that is NOT the car's (a phone hotspot): two peers behind one NAT fail
/// for router reasons, which measures nothing.
///
///     flutter test integration_test/pear_bench_test.dart -d macos \
///       --dart-define=BW_DIR=<dir> [--dart-define=BW_PAIRING=<qr text>] \
///       [--dart-define='BW_RUN=video --seconds 600 --probe-every 2;rpc --count 200'] \
///       [--dart-define=BW_QUALITY=MEDIUM] [--dart-define=BW_BURST=true] [--dart-define=BW_COLD_STARTS=20] \
///       [--dart-define=BW_INBOX=true|mark|send|collect]
///
/// BW_INBOX (BladeWatch-rdtj.14): the car's alert inbox over Pear, with the saved credential -- no
/// fresh QR needed. `true` raises a test alert and collects it, once, in one session. To prove
/// store and forward -- an alert raised while this companion is away arrives on its next
/// connection -- run three separate sessions: `mark` records where the inbox stands, `send`
/// raises the alert and leaves without collecting, `collect` reads from the mark.
///
/// BW_QUALITY sets the live-view preset BEFORE the harness starts (never during a run); the car's
/// current preset and the ones it offers are logged either way.
///
/// BW_DIR (mode 700) holds the harness classes (`javac --release 11 -d BW_DIR/classes
/// tools/throughput/Throughput.java`), bench.json (the pairing payload and the credential it was
/// redeemed for) and jwt, both mode 600. They are secrets: delete the directory afterwards and
/// remove the "pear bench" device in the car. The first run pairs with BW_PAIRING; later runs
/// reuse bench.json.
const _dir = String.fromEnvironment('BW_DIR');
const _qrText = String.fromEnvironment('BW_PAIRING');
const _run = String.fromEnvironment('BW_RUN');
const _burst = bool.fromEnvironment('BW_BURST');
const _coldStarts = int.fromEnvironment('BW_COLD_STARTS');
const _quality = String.fromEnvironment('BW_QUALITY');
const _inbox = String.fromEnvironment('BW_INBOX');

class _Link {
  _Link(this.gateway, this.pear, this.selector);

  final LocalGateway gateway;
  final Pear pear;
  final TransportSelector selector;

  Future<void> close() async {
    await selector.dispose();
    await gateway.close();
    await pear.dispose();
  }
}

/// A new Pear, a new gateway and a route to the car over Pear only.
Future<_Link> _connect(PairingPayload qr) async {
  final gateway = await LocalGateway.start();
  final pear = await Pear.start();
  final selector = TransportSelector(
    gateway: gateway,
    pinnedFingerprint: qr.tlsFingerprint,
    findOnLan: () async => null,
    connectPear: (onClosed) async {
      final swarm = await pear.join(PearKey.fromHex(qr.pearTopic), announce: false);
      // Enough to tell "no peer ever connected" (NAT) from "connected, but the car's pump never
      // answered the TLS handshake".
      swarm.state.listen((st) => _emit({'swarm': st.state.name, if (st.error != null) 'error': st.error!.code}));
      var peers = 0;
      return findCarOverPear(
        pearLinks(swarm).map((link) {
          _emit({'peer_connected': ++peers});
          return link;
        }),
        qr.tlsFingerprint,
        onClosed: onClosed,
      );
    },
  );
  final link = _Link(gateway, pear, selector);
  try {
    await selector.evaluate();
    if (selector.phase != TransportPhase.pear) throw StateError('route ${selector.phase.name}, not pear');
    return link;
  } catch (_) {
    await link.close();
    rethrow;
  }
}

/// Owner-only file: created and chmod-ed BEFORE the secret goes in.
Future<void> _writeSecret(String path, String content) async {
  final f = File(path)..writeAsStringSync('');
  await Process.run('chmod', ['600', path]);
  f.writeAsStringSync(content);
}

Map<String, Object> _stats(List<double> ms) {
  if (ms.isEmpty) return {'n': 0};
  final s = [...ms]..sort();
  double p(double q) => s[((s.length - 1) * q).round()];
  return {'n': s.length, 'p50': p(0.5), 'p90': p(0.9), 'p95': p(0.95), 'max': s.last};
}

void _emit(Map<String, Object?> line) => print(jsonEncode(line));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A plain test(), not testWidgets(): nothing here is a widget, and testWidgets' end-of-test
  // checks failed the run after every result had printed whenever a macOS accessibility client
  // switched semantics on mid-run ("A SemanticsHandle was active").
  test('pear bench', () async {
    final benchFile = File('$_dir/bench.json');
    late PairingPayload qr;
    late CompanionCredential credential;

    // Pair once over Pear, or reuse the credential of an earlier run.
    if (_qrText.isNotEmpty) {
      qr = PairingPayload.decode(_qrText);
      final link = await _connect(qr);
      try {
        credential = await CarAuth(link.gateway.baseUrl).redeem(qr.code, name: 'pear bench');
      } finally {
        await link.close();
      }
      await _writeSecret(
        benchFile.path,
        jsonEncode({'qr': _qrText, 'companionId': credential.companionId, 'token': credential.token}),
      );
      _emit({'paired': true});
    } else {
      final saved = jsonDecode(benchFile.readAsStringSync()) as Map<String, dynamic>;
      qr = PairingPayload.decode(saved['qr'] as String);
      credential = CompanionCredential(saved['companionId'] as String, saved['token'] as String);
    }

    if (_run.isNotEmpty || _burst) {
      final started = Stopwatch()..start();
      final link = await _connect(qr);
      try {
        _emit({'route': 'pear', 'route_ms': started.elapsedMilliseconds, 'base': '${link.gateway.baseUrl}'});
        final auth = CarAuth(link.gateway.baseUrl);
        final jwt = await auth.login(credential);
        await _writeSecret('$_dir/jwt', jwt);

        final stream = StreamServiceClient(
          ConnectClient(jwtSource: CompanionJwtSource(auth, credential), baseUrl: link.gateway.baseUrl),
        );
        if (_quality.isNotEmpty) {
          _emit({'set_quality': _quality, 'success': (await stream.setQuality(SetStreamQualityRequest(quality: _quality))).success});
        }
        final q = await stream.getQuality(GetStreamQualityRequest());
        _emit({'quality': q.current, 'options': [for (final o in q.options) o.toProto3Json()]});

        // The unchanged harness, through this gateway, one run after another.
        for (final run in _run.split(';').map((r) => r.trim()).where((r) => r.isNotEmpty)) {
          _emit({'harness': run});
          final p = await Process.start('java', [
            '-cp', '$_dir/classes', 'Throughput', ...run.split(RegExp(r'\s+')),
            '--base', '${link.gateway.baseUrl}', '--jwt-file', '$_dir/jwt',
          ]);
          final out = p.stdout.transform(utf8.decoder).transform(const LineSplitter()).forEach(print);
          final err = p.stderr.transform(utf8.decoder).transform(const LineSplitter()).forEach(print);
          final code = await p.exitCode;
          await Future.wait([out, err]);
          _emit({'harness_exit': code});
        }

        if (_burst) {
          final rpc = ConnectClient(jwtSource: CompanionJwtSource(auth, credential), baseUrl: link.gateway.baseUrl);
          final system = SystemServiceClient(rpc);
          final trips = TripsServiceClient(rpc);
          final recordings = RecordingsServiceClient(rpc);
          final vehicle = VehicleServiceClient(rpc);

          // A dashboard-shaped burst: the calls a dashboard load issues, all at once, 20 times.
          final rounds = <double>[];
          var failed = 0;
          for (var i = 0; i < 20; i++) {
            final w = Stopwatch()..start();
            try {
              await Future.wait([
                system.getStatus(GetStatusRequest()),
                trips.listTrips(ListTripsRequest()),
                recordings.listRecordings(ListRecordingsRequest(pageSize: 20)),
                vehicle.getState(GetVehicleStateRequest()),
              ]);
              rounds.add(w.elapsedMicroseconds / 1000);
            } catch (_) {
              failed++;
            }
          }
          _emit({'burst': 'status+trips+recordings+vehicle x4 concurrent', 'failed': failed, ..._stats(rounds)});

          // Thumbnails: many small requests, one after another, then four at a time as a grid does.
          final list = await recordings.listRecordings(ListRecordingsRequest(pageSize: 24));
          final names = [for (final r in list.recordings) r.filename];
          final client = HttpClient();
          // Outcome counts by status: a 404 (no thumbnail yet, e.g. the clip still recording) is the
          // car's answer, a transport error is the path's.
          final outcomes = <String, int>{};
          final sizes = <double>[];
          final types = <String, int>{};
          String? firstDims;
          Future<double?> thumb(String name) async {
            final w = Stopwatch()..start();
            try {
              final req = await client.getUrl(link.gateway.baseUrl.resolve('/thumb/${Uri.encodeComponent(name)}'));
              req.headers.set('Authorization', 'Bearer $jwt');
              final res = await req.close();
              var bytes = 0;
              final head = BytesBuilder();
              await res.forEach((chunk) {
                bytes += chunk.length;
                if (head.length < 4096) head.add(chunk);
              });
              if (firstDims == null && res.statusCode == 200) {
                // JPEG SOF0/SOF2: FF C0|C2, length(2), precision(1), height(2), width(2).
                final b = head.takeBytes();
                for (var i = 0; i + 8 < b.length; i++) {
                  if (b[i] == 0xFF && (b[i + 1] == 0xC0 || b[i + 1] == 0xC2)) {
                    firstDims = '${(b[i + 7] << 8) | b[i + 8]}x${(b[i + 5] << 8) | b[i + 6]} $bytes B ${res.headers.value('content-length')} CL';
                    break;
                  }
                }
              }
              if (res.statusCode == 200) sizes.add(bytes / 1024);
              types.update('${res.headers.contentType}', (n) => n + 1, ifAbsent: () => 1);
              outcomes.update('${res.statusCode}', (n) => n + 1, ifAbsent: () => 1);
              return res.statusCode == 200 ? w.elapsedMicroseconds / 1000 : null;
            } catch (e) {
              final what = '$e';
              outcomes.update(what.length > 90 ? what.substring(0, 90) : what, (n) => n + 1, ifAbsent: () => 1);
              return null;
            }
          }

          final sequential = [for (final n in names) await thumb(n)];
          final parallelWall = Stopwatch()..start();
          final parallel = <double?>[];
          for (var i = 0; i < names.length; i += 4) {
            parallel.addAll(await Future.wait(names.skip(i).take(4).map(thumb)));
          }
          client.close(force: true);
          _emit({
            'thumbs_sequential': _stats(sequential.whereType<double>().toList()),
            'thumbs_outcomes': outcomes,
            'thumb_kib': _stats(sizes),
            'thumb_types': types,
            'thumb_names': names.take(3).toList(),
            'thumb_first_dims': firstDims,
            'thumbs_by_4_wall_ms': parallelWall.elapsedMilliseconds,
            'thumbs_by_4': _stats(parallel.whereType<double>().toList()),
          });
        }
      } finally {
        await link.close();
        final jwtFile = File('$_dir/jwt');
        if (jwtFile.existsSync()) jwtFile.deleteSync();
      }
    }

    if (_inbox.isNotEmpty) {
      final mark = File('$_dir/inbox_cursor');
      final link = await _connect(qr);
      try {
        final rpc = ConnectClient(jwtSource: CompanionJwtSource(CarAuth(link.gateway.baseUrl), credential), baseUrl: link.gateway.baseUrl);
        final notifications = NotificationsServiceClient(rpc);
        Future<void> send() => notifications.sendTest(SendTestRequest(category: 'surveillance.motion', severity: 'info'));
        Future<void> collectFrom(Int64 cursor) async {
          var after = const InboxBatch([], Int64.ZERO);
          for (var i = 0; i < 20 && after.entries.isEmpty; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 250)); // the bus delivers async
            after = await collectInbox(notifications, cursor);
          }
          final again = await collectInbox(notifications, after.cursor);
          _emit({'inbox': after.entries.map((e) => e.title).toList(), 'then': again.entries.length});
          expect(after.entries.map((e) => e.title), ['Test notification']);
          expect(again.entries, isEmpty, reason: 'collected once');
        }

        switch (_inbox) {
          case 'mark':
            final cursor = (await collectInbox(notifications, Int64.ZERO)).cursor;
            mark.writeAsStringSync('$cursor');
            _emit({'inbox_mark': '$cursor'});
          case 'send':
            await send();
            _emit({'inbox_sent': true});
          case 'collect':
            await collectFrom(Int64.parseInt(mark.readAsStringSync()));
          default:
            final before = await collectInbox(notifications, Int64.ZERO);
            await send();
            await collectFrom(before.cursor);
        }
      } finally {
        await link.close();
      }
    }

    // Cold start: Pear start to the first answered status, the DHT lookup included, N times.
    final routeMs = <double>[], firstStatusMs = <double>[];
    var coldFailed = 0;
    for (var i = 0; i < _coldStarts; i++) {
      final w = Stopwatch()..start();
      _Link? link;
      try {
        final pending = _connect(qr);
        link = await pending.timeout(const Duration(seconds: 120), onTimeout: () {
          // Still connecting: close it when it lands, so it cannot skew the next attempt.
          unawaited(pending.then((l) => l.close(), onError: (_) {}));
          throw TimeoutException('no route in 120 s');
        });
        final route = w.elapsedMicroseconds / 1000;
        final auth = CarAuth(link.gateway.baseUrl);
        final rpc = ConnectClient(jwtSource: CompanionJwtSource(auth, credential), baseUrl: link.gateway.baseUrl);
        await SystemServiceClient(rpc).getStatus(GetStatusRequest());
        final total = w.elapsedMicroseconds / 1000;
        routeMs.add(route);
        firstStatusMs.add(total);
        _emit({'cold_start': i + 1, 'route_ms': route, 'first_status_ms': total});
      } catch (e) {
        coldFailed++;
        _emit({'cold_start': i + 1, 'failed': '$e', 'after_ms': w.elapsedMilliseconds});
      } finally {
        await link?.close();
      }
    }
    if (_coldStarts > 0) {
      _emit({'cold_start_summary': true, 'failed': coldFailed, 'route': _stats(routeMs), 'first_status': _stats(firstStatusMs)});
    }
  }, skip: _dir.isEmpty, timeout: const Timeout(Duration(minutes: 90)));
}
