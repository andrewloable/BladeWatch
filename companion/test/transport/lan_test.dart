import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/transport/lan_prober.dart';
import 'package:bladewatch_companion/transport/pinned_tls.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_certs.dart';


/// A car on loopback UDP that answers probes the way LanDiscoveryResponder does -- or misbehaves.
class FakeCar {
  FakeCar._(this.socket, this.key);

  final RawDatagramSocket socket;
  final List<int> key;
  String fingerprint = 'aa' * 32;
  bool corruptMac = false;
  bool otherNonce = false;
  bool silent = false;

  static Future<FakeCar> start(List<int> key) async {
    final car = FakeCar._(await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0), key);
    car.socket.listen((e) {
      if (e != RawSocketEvent.read) return;
      final d = car.socket.receive();
      if (d != null && !car.silent) car._answer(d);
    });
    return car;
  }

  void _answer(Datagram d) {
    final nonce = otherNonce ? Uint8List(16) : d.data.sublist(8, 24);
    final json = utf8.encode(jsonEncode({'ip': '127.0.0.1', 'port': 8443, 'fp': fingerprint, 'id': 'byd-test'}));
    final magicNonce = [...ascii.encode('BWREPLY1'), ...nonce];
    final mac = Hmac(sha256, key).convert([...magicNonce, ...json]).bytes.toList();
    if (corruptMac) mac[0] ^= 1;
    socket.send([...magicNonce, ...mac, ...json], d.address, d.port);
  }
}

void main() {
  final key = List<int>.generate(32, (i) => i);
  late FakeCar car;

  setUp(() async => car = await FakeCar.start(key));
  tearDown(() => car.socket.close());

  LanProber prober() => LanProber(key, port: car.socket.port);
  final here = [InternetAddress.loopbackIPv4];

  group('LanProber', () {
    test('a correctly signed reply with the pinned fingerprint finds the car', () async {
      final found = await prober().find(here, pinnedFingerprint: 'aa' * 32);
      expect(found?.address, InternetAddress.loopbackIPv4);
      expect(found?.port, 8443);
      expect(found?.fingerprint, 'aa' * 32);
    });

    test('a reply with an invalid signature is ignored', () async {
      car.corruptMac = true;
      expect(await prober().find(here, pinnedFingerprint: 'aa' * 32, timeout: const Duration(milliseconds: 400)), isNull);
    });

    test('a reply to somebody else\'s probe is ignored', () async {
      car.otherNonce = true;
      expect(await prober().find(here, pinnedFingerprint: 'aa' * 32, timeout: const Duration(milliseconds: 400)), isNull);
    });

    test('a car that answers with a different certificate pin is not ours', () async {
      car.fingerprint = 'bb' * 32;
      expect(await prober().find(here, pinnedFingerprint: 'aa' * 32, timeout: const Duration(milliseconds: 400)), isNull);
    });

    test('silence is not the car', () async {
      car.silent = true;
      expect(await prober().find(here, pinnedFingerprint: 'aa' * 32, timeout: const Duration(milliseconds: 300)), isNull);
      expect(await prober().find(const [], pinnedFingerprint: 'aa' * 32), isNull);
    });

    test('a probe has exactly the layout the car verifies', () {
      final nonce = Uint8List.fromList(List.generate(16, (i) => 100 + i));
      final probe = LanProber.buildProbe(key, nonce, 1700000000000);
      expect(probe, hasLength(256));
      expect(ascii.decode(probe.sublist(0, 8)), 'BWPROBE1');
      expect(probe.sublist(8, 24), nonce);
      expect(ByteData.sublistView(probe, 24, 32).getInt64(0), 1700000000000);
      expect(probe.sublist(32, 64), Hmac(sha256, key).convert(probe.sublist(0, 32)).bytes);
      expect(probe.sublist(64).every((b) => b == 0), isTrue);
    });

    test('candidates: the last-known address first, then this device\'s /24s, private ones only', () async {
      Future<List<InternetAddress>> own() async =>
          [InternetAddress('192.168.7.20'), InternetAddress('8.8.4.4'), InternetAddress('127.0.0.1')];
      final last = InternetAddress('192.168.7.9');
      final list = await LanProber.candidates(lastKnown: last, ownAddresses: own);
      expect(list.first, last);
      expect(list, hasLength(1 + 252), reason: '254 hosts, minus this device and the last-known one');
      expect(list.where((a) => a == last), hasLength(1));
      expect(list, isNot(contains(InternetAddress('192.168.7.20'))));
      expect(list.every((a) => a.address.startsWith('192.168.7.')), isTrue);
      expect(await LanProber.candidates(ownAddresses: () async => [InternetAddress('10.1.2.3')]), hasLength(253));
      expect(await LanProber.candidates(ownAddresses: () async => [InternetAddress('172.20.0.5')]), hasLength(253));
      expect(await LanProber.candidates(ownAddresses: () async => [InternetAddress('::1')]), isEmpty);
      // The real device lookup: whatever this machine has, it must not throw.
      expect(await LanProber.candidates(), isA<List<InternetAddress>>());
    });
  });

  group('PinnedTls', () {
    late SecureServerSocket server;

    setUp(() async {
      final ctx = SecurityContext()
        ..useCertificateChainBytes(utf8.encode(certA))
        ..usePrivateKeyBytes(utf8.encode(keyA));
      server = await SecureServerSocket.bind(InternetAddress.loopbackIPv4, 0, ctx);
      server.listen((s) {
        s.write('car');
        s.close();
      }, onError: (Object _) {});
    });
    tearDown(() => server.close());

    test('connects when the car presents the pinned certificate', () async {
      final s = await PinnedTls.connect(InternetAddress.loopbackIPv4, server.port, fingerprintOfPem(certA));
      expect(utf8.decode(await s.fold<List<int>>([], (a, b) => a..addAll(b))), 'car');
      expect(PinnedTls.fingerprintOf(s.peerCertificate!), fingerprintOfPem(certA));
    });

    test('REFUSES a certificate whose fingerprint does not match the pin', () async {
      expect(
        PinnedTls.connect(InternetAddress.loopbackIPv4, server.port, fingerprintOfPem(certB)),
        throwsA(isA<TlsException>()),
      );
    });
  });
}
