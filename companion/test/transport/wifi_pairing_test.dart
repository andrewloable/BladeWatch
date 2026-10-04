import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/transport/wifi_pairing.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_certs.dart';

/// BladeWatch 1.4.1.2: the device's half of Wi-Fi pairing, against a stand-in for the car's
/// LanDiscoveryResponder and AuthApiHandler.
void main() {
  // The same vector the car's WifiPairingTest asserts, computed outside both (Python's hashlib).
  test('the number matches the car\'s definition byte for byte', () {
    final device = List.generate(32, (i) => i);
    final car = List.generate(32, (i) => i + 32);
    expect(WifiPairing.number('a' * 64, device, car), '918234');
    expect(WifiPairing.number('b' * 64, device, car), '547028');
  });

  group('find', () {
    late RawDatagramSocket car;
    late List<int> Function(Datagram probe) reply;

    setUp(() async {
      car = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      reply = (p) => [...ascii.encode('BWPAIRR1'), ...p.data.sublist(8, 24), ...utf8.encode('{"port":8443}')];
      car.listen((event) {
        final p = event == RawSocketEvent.read ? car.receive() : null;
        if (p == null || p.data.length != 256 || ascii.decode(p.data.sublist(0, 8)) != 'BWPAIRQ1') return;
        car.send(reply(p), p.address, p.port);
      });
    });
    tearDown(() => car.close());

    Future<PairingCar?> find() => WifiPairing.find(
          candidates: () async => [InternetAddress.loopbackIPv4],
          port: car.port,
          timeout: const Duration(milliseconds: 500),
        );

    test('a car with pairing open answers with its TLS port, from its own address', () async {
      final found = await find();
      expect(found?.address, InternetAddress.loopbackIPv4);
      expect(found?.port, 8443);
    });

    test('a reply to another probe, a wrong magic or a garbled body is ignored', () async {
      reply = (p) => [...ascii.encode('BWPAIRR1'), ...List.filled(16, 0), ...utf8.encode('{"port":8443}')];
      expect(await find(), isNull);
      reply = (p) => [...ascii.encode('BWREPLY1'), ...p.data.sublist(8, 24), ...utf8.encode('{"port":8443}')];
      expect(await find(), isNull);
      reply = (p) => [...ascii.encode('BWPAIRR1'), ...p.data.sublist(8, 24), ...utf8.encode('nope')];
      expect(await find(), isNull);
    });

    test('nowhere to look, and a host that cannot be sent to, are not fatal', () async {
      expect(await WifiPairing.find(candidates: () async => []), isNull);
      final found = await WifiPairing.find(
        candidates: () async => [InternetAddress('10.255.255.1'), InternetAddress.loopbackIPv4],
        port: car.port,
        send: (s, data, a, p) => a.address == '10.255.255.1' ? throw const SocketException('unreachable') : s.send(data, a, p),
      );
      expect(found?.port, 8443);
    });
  });

  test('the search sweeps the /24 a slice at a time, round and round', () async {
    final hosts = [for (var i = 1; i <= 70; i++) InternetAddress('192.168.0.$i')];
    final probed = <List<String>>[];
    final search = WifiPairing.sweep(candidates: () async => hosts, probe: (h) async {
      probed.add([for (final a in h) a.address]);
      return null;
    });
    for (var i = 0; i < 3; i++) {
      await search();
    }
    expect(probed.map((p) => p.length), [32, 32, 32]);
    expect(probed[2].first, '192.168.0.65');
    expect(probed[2].last, '192.168.0.26', reason: 'wraps around to the start');
    expect({...probed.expand((p) => p)}, hasLength(70), reason: 'every host is probed');

    final none = WifiPairing.sweep(candidates: () async => [], probe: (h) async => h.isEmpty ? null : throw StateError('probed'));
    expect(await none(), isNull);
  });

  group('the request', () {
    late HttpServer server;
    late String state; // what the stand-in car answers to result: waiting, accepted, refused
    String? carNumber;
    final carNonce = List.generate(32, (i) => 255 - i);

    setUp(() async {
      final ctx = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(certA))
        ..usePrivateKeyBytes(utf8.encode(keyA));
      server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, ctx);
      state = 'waiting';
      List<int>? commitment;
      server.listen((request) async {
        // As strict as the car's server: a body without a Content-Length is no body at all.
        final text = request.contentLength > 0 ? await utf8.decoder.bind(request).join() : '{}';
        final body = jsonDecode(text) as Map<String, dynamic>;
        Object reply;
        switch (request.uri.path) {
          case '/auth/wifi-pair/start' when body['commitment'] == null:
            reply = {'success': false, 'error': 'wifi_pairing_closed'};
          case '/auth/wifi-pair/start':
            commitment = _unhex(body['commitment'] as String);
            reply = {'success': true, 'id': 'r1', 'carNonce': _hex(carNonce)};
          case '/auth/wifi-pair/reveal':
            final nonce = _unhex(body['deviceNonce'] as String);
            final ok = body['id'] == 'r1' && _hex(sha256.convert(nonce).bytes) == _hex(commitment!);
            carNumber = ok ? WifiPairing.number(fingerprintOfPem(certA), nonce, carNonce) : null;
            reply = ok ? {'success': true} : {'success': false, 'error': 'wifi_pairing_refused'};
          case '/auth/wifi-pair/result':
            reply = switch (state) {
              'waiting' => {'success': true, 'state': 'waiting'},
              'accepted' => {'success': true, 'state': 'accepted', 'payload': 'the-payload'},
              _ => {'success': false, 'error': 'wifi_pairing_refused'},
            };
          default:
            request.response.statusCode = 404;
            reply = 'Not Found';
        }
        request.response.write(reply is String ? reply : jsonEncode(reply));
        await request.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    WifiPairing open() => WifiPairing((address: InternetAddress.loopbackIPv4, port: server.port));

    test('commit, reveal and the number both sides show; the payload once the owner confirms', () async {
      final w = open();
      addTearDown(w.close);
      final number = await w.start('Living room TV');
      expect(number, carNumber, reason: 'the car checked the commitment and computed the same number');
      expect(w.fingerprint, fingerprintOfPem(certA));
      expect(await w.result(), isNull);
      state = 'accepted';
      expect(await w.result(), 'the-payload');
    });

    test('a refusal, and anything that is not the car\'s JSON, ends it', () async {
      final w = open();
      addTearDown(w.close);
      await w.start('TV');
      state = 'refused';
      await expectLater(w.result(), throwsA(isA<WifiPairingRefused>().having((e) => e.code, 'code', 'wifi_pairing_refused')));

      // A car that is not running Wi-Fi pairing on this listener answers 404 in plain text.
      server.close(force: true);
      final plain = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, SecurityContext()
        ..useCertificateChainBytes(utf8.encode(certA))
        ..usePrivateKeyBytes(utf8.encode(keyA)));
      addTearDown(() => plain.close(force: true));
      plain.listen((r) async {
        await r.drain<void>();
        r.response
          ..statusCode = 404
          ..write('Not Found');
        await r.response.close();
      });
      final old = WifiPairing((address: InternetAddress.loopbackIPv4, port: plain.port));
      addTearDown(old.close);
      await expectLater(old.start('TV'), throwsA(isA<WifiPairingRefused>().having((e) => e.code, 'code', 'http_404')));
      expect(const WifiPairingRefused('x').toString(), 'WifiPairingRefused(x)');
    });
  });
}

String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List _unhex(String h) => Uint8List.fromList([for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);
