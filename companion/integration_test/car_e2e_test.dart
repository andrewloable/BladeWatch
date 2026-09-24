import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/lan_prober.dart';
import 'package:bladewatch_companion/transport/local_gateway.dart';
import 'package:bladewatch_companion/transport/pear_link.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:bladewatch_rpc/rpc/connect_client.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:flutter_pear/flutter_pear.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// BladeWatch-rdtj.6/.7/.8 on real hardware: find the car, pair with it, and call it.
///
/// Needs a powered car and a FRESH pairing QR's text (single use, five minutes), so it is
/// skipped without one:
///
///     flutter test integration_test/car_e2e_test.dart -d macos \
///       --dart-define=BW_PAIRING=<qr text> --dart-define=BW_ROUTE=lan    # or pear
///
/// `lan` needs the car's LAN access on and this machine on the car's network. `pear` never
/// probes the LAN and needs the car's PEAR_PEER daemon; run it from a DIFFERENT network (a phone
/// hotspot) -- two peers behind one NAT fail for router reasons, which proves nothing.
///
/// Pairing adds this machine to the car's paired devices: remove it in the car afterwards.
const _qr = String.fromEnvironment('BW_PAIRING');
const _route = String.fromEnvironment('BW_ROUTE', defaultValue: 'lan');

/// Optional: keep calling the car for this many seconds after pairing, printing `soak start`
/// first so the runner can restart byd_cam_daemon mid-connection (BladeWatch-rdtj.6), e.g.
///   ... | while read l; do echo "$l"; case "$l" in *"soak start"*) adb -s ... shell killall -9 byd_cam_daemon;; esac; done
const _soakSeconds = int.fromEnvironment('BW_SOAK_SECONDS');

class _NoJwt implements JwtSource {
  @override
  Future<String?> mintJwt() async => null;

  @override
  Future<int> stateVersion() async => 0;
}

List<int> _hex(String s) => [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pairs with the car over $_route and calls it', (tester) async {
    final qr = PairingPayload.decode(_qr);
    final gateway = await LocalGateway.start();
    Pear? pear;
    final selector = TransportSelector(
      gateway: gateway,
      pinnedFingerprint: qr.tlsFingerprint,
      findOnLan: () async => _route == 'pear'
          ? null
          : LanProber(_hex(qr.probeKey)).find(await LanProber.candidates(), pinnedFingerprint: qr.tlsFingerprint),
      connectPear: (onClosed) async {
        if (_route != 'pear') return null;
        pear ??= await Pear.start();
        final swarm = await pear!.join(PearKey.fromHex(qr.pearTopic));
        // Enough to tell "no peer ever connected" (NAT) from "a peer connected but was not the car".
        // ignore: avoid_print
        swarm.state.listen((s) => print('swarm ${s.state.name}${s.error == null ? '' : ' ${s.error!.code}'}'));
        var peers = 0;
        final links = pearLinks(swarm).map((link) {
          // ignore: avoid_print
          print('peer ${++peers} connected');
          return link;
        });
        return findCarOverPear(links, qr.tlsFingerprint, onClosed: onClosed);
      },
    );
    try {
      final started = DateTime.now();
      await selector.evaluate();
      expect(selector.phase.name, _route);
      // ignore: avoid_print
      print('route ${selector.phase.name} in ${DateTime.now().difference(started).inMilliseconds} ms');

      // Through the route, the car refuses a caller with no JWT...
      final anonymous = SystemServiceClient(ConnectClient(jwtSource: _NoJwt(), baseUrl: gateway.baseUrl));
      await expectLater(
        anonymous.getStatus(GetStatusRequest()),
        throwsA(isA<ConnectError>().having((e) => e.httpStatus, 'httpStatus', 401)),
      );

      // ...and answers once the QR's code is redeemed and the companion has logged in.
      final auth = CarAuth(gateway.baseUrl);
      final credential = await auth.redeem(qr.code, name: 'companion e2e');
      final client = SystemServiceClient(ConnectClient(jwtSource: CompanionJwtSource(auth, credential), baseUrl: gateway.baseUrl));
      final status = await client.getStatus(GetStatusRequest());
      expect(status.deviceId, qr.deviceId, reason: 'the car that answered is the one that showed the QR');

      // A used code is worthless.
      await expectLater(auth.redeem(qr.code), throwsA(isA<CarAuthRefused>()));

      if (_soakSeconds > 0) {
        final reRouted = <TransportPhase>[];
        final phases = selector.phases.listen(reRouted.add);
        // ignore: avoid_print
        print('soak start');
        final end = DateTime.now().add(const Duration(seconds: _soakSeconds));
        var ok = 0, failed = 0;
        var lastOk = false;
        while (DateTime.now().isBefore(end)) {
          try {
            await client.getStatus(GetStatusRequest());
            ok++;
            lastOk = true;
          } catch (_) {
            failed++;
            lastOk = false;
          }
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        await phases.cancel();
        // ignore: avoid_print
        print('soak: $ok ok, $failed failed, re-routes: $reRouted');
        expect(lastOk, isTrue, reason: 'the car answers again once byd_cam_daemon is back');
        expect(reRouted, isEmpty, reason: 'the Pear connection itself outlived the restart');
      }
    } finally {
      await selector.dispose();
      await gateway.close();
      await pear?.dispose();
    }
  }, skip: _qr.isEmpty, timeout: const Timeout(Duration(minutes: 3)));
}
