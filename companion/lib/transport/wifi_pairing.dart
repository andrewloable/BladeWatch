import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'lan_prober.dart';
import 'pinned_tls.dart';

/// A car that answered a pairing probe: where its LAN TLS listener is.
typedef PairingCar = ({InternetAddress address, int port});

/// The attempt is over: the owner refused, the window shut, someone else is pairing, or the car
/// changed certificate mid-flow. [code] is the car's stable error code, never localized text.
class WifiPairingRefused implements Exception {
  const WifiPairingRefused(this.code);

  final String code;

  @override
  String toString() => 'WifiPairingRefused($code)';
}

/// Pairing a device with no camera -- a TV, a desktop -- over the car's Wi-Fi with a matching
/// number instead of a QR (BladeWatch 1.4.1.2). The protocol, and why the number means something,
/// is the car's `WifiPairing` (app/src/main/java/com/loabletech/bladewatch/auth/WifiPairing.kt);
/// this is the device's half, and [number] must match the car's exactly.
///
/// It ends where QR pairing starts: the car hands over the same single-use payload a QR carries,
/// which [PairingController] checks against [fingerprint] and redeems as usual.
class WifiPairing {
  WifiPairing(this.car, {Random? random}) : _random = random ?? Random.secure();

  final PairingCar car;
  final Random _random;
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  String? _fingerprint;
  String? _id;

  /// The car's certificate, as first seen. Every later response must present the same one, and
  /// the payload the car hands over must name it.
  String? get fingerprint => _fingerprint;

  static const _probeMagic = 'BWPAIRQ1';
  static const _replyMagic = 'BWPAIRR1';

  /// Looks for a car with "Pair a device" open: an unsigned pairing probe to every host of this
  /// device's /24s -- unicast, as [LanProber] explains -- and the first reply that echoes it. A car
  /// answers only while the owner has the dialog open, so silence is the normal "not yet".
  static Future<PairingCar?> find({
    Future<List<InternetAddress>> Function()? candidates,
    int port = 18443,
    Duration timeout = const Duration(milliseconds: 1500),
    ProbeSend? send,
    Random? random,
  }) async {
    final targets = await (candidates ?? LanProber.candidates)();
    if (targets.isEmpty) return null;
    final rng = random ?? Random.secure();
    final nonce = List.generate(16, (_) => rng.nextInt(256));
    final probe = Uint8List(256)
      ..setRange(0, 8, ascii.encode(_probeMagic))
      ..setRange(8, 24, nonce);
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final result = Completer<PairingCar?>();
    final timer = Timer(timeout, () => result.isCompleted ? null : result.complete(null));
    socket.listen((event) {
      final d = event == RawSocketEvent.read ? socket.receive() : null;
      if (d == null || result.isCompleted || d.data.length <= 24) return;
      if (ascii.decode(d.data.sublist(0, 8), allowInvalid: true) != _replyMagic) return;
      if (!_same(d.data.sublist(8, 24), nonce)) return; // a reply to somebody else's probe
      try {
        final port = (jsonDecode(utf8.decode(d.data.sublist(24))) as Map)['port'] as int;
        result.complete((address: d.address, port: port));
      } catch (_) {
        // not a car's reply after all
      }
    }, onError: (Object _) {}); // a failed send surfaces here, as in LanProber
    try {
      for (final address in targets) {
        try {
          (send ?? (s, data, a, p) => s.send(data, a, p))(socket, probe, address, port);
        } on SocketException {
          // skip that host
        }
      }
      return await result.future;
    } finally {
      timer.cancel();
      socket.close();
    }
  }

  /// The search [PairingController] repeats: each call probes the next [slice] hosts of this
  /// device's /24s, on a fresh socket, so a whole sweep takes a few calls.
  ///
  /// Not all 254 at once. From a Sony BRAVIA a 254-probe burst never found the car, near the end
  /// of the /24, in a minute of searching, where slices of 32 found it on the first pass
  /// (2026-10-04); the same burst from a Mac found it every time. Likely cause: a probe to an empty address waits in the
  /// kernel for an ARP lookup that will fail, holding socket buffer, and once the buffer is full
  /// Dart's non-blocking send drops the rest.
  static Future<PairingCar?> Function() sweep({
    int slice = 32,
    Future<List<InternetAddress>> Function()? candidates,
    Future<PairingCar?> Function(List<InternetAddress> hosts)? probe,
  }) {
    List<InternetAddress>? all;
    var next = 0;
    return () async {
      final hosts = all ??= await (candidates ?? LanProber.candidates)();
      final part = [for (var i = 0; i < slice && i < hosts.length; i++) hosts[(next + i) % hosts.length]];
      next = hosts.isEmpty ? 0 : (next + part.length) % hosts.length;
      return (probe ?? (h) => find(candidates: () async => h))(part);
    };
  }

  /// Starts a request named [name] and returns the six digits to show: commit to a secret nonce,
  /// take the car's, reveal ours, and derive the number from both and the car's certificate.
  Future<String> start(String name) async {
    final nonce = List.generate(32, (_) => _random.nextInt(256));
    final started = await _post('/auth/wifi-pair/start', {'name': name, 'commitment': sha256.convert(nonce).toString()});
    _id = started['id'] as String;
    await _post('/auth/wifi-pair/reveal', {'id': _id, 'deviceNonce': _hex(nonce)});
    return number(_fingerprint!, nonce, _unhex(started['carNonce'] as String));
  }

  /// The pairing payload once the owner has confirmed in the car, null while they have not.
  /// Throws [WifiPairingRefused] when they refuse, or the request is over.
  Future<String?> result() async {
    final r = await _post('/auth/wifi-pair/result', {'id': _id});
    return r['state'] == 'accepted' ? r['payload'] as String : null;
  }

  void close() => _http.close(force: true);

  /// The six digits both screens show -- the car's `WifiPairing.number`, byte for byte: the first
  /// four bytes of SHA-256("bladewatch/wifi-pair/v1" | 0 | fingerprint | 0 | device nonce | car
  /// nonce), big-endian and unsigned, modulo 1 000 000, zero-padded.
  static String number(String fingerprint, List<int> deviceNonce, List<int> carNonce) {
    final digest = sha256.convert([
      ...utf8.encode('bladewatch/wifi-pair/v1'), 0, ...utf8.encode(fingerprint), 0, ...deviceNonce, ...carNonce,
    ]).bytes;
    final value = ByteData.sublistView(Uint8List.fromList(digest), 0, 4).getUint32(0);
    return (value % 1000000).toString().padLeft(6, '0');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, Object?> body) async {
    // The car's certificate is self-signed: the first one seen is the one this flow is bound to,
    // and the number the owner compares is what proves it is the car's.
    _http.badCertificateCallback = (cert, host, port) => (_fingerprint ??= PinnedTls.fingerprintOf(cert)) == PinnedTls.fingerprintOf(cert);
    final request = await _http.postUrl(Uri(scheme: 'https', host: car.address.address, port: car.port, path: path));
    // With a length: the car's server reads Content-Length bodies only, and a chunked one arrived
    // empty -- refused as "pairing closed" (seen on the BRAVIA, 2026-10-04).
    final bytes = utf8.encode(jsonEncode(body));
    request.headers.contentType = ContentType.json;
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close();
    final cert = response.certificate;
    if (cert == null || PinnedTls.fingerprintOf(cert) != _fingerprint) throw const WifiPairingRefused('certificate_changed');
    final Object? json;
    try {
      json = jsonDecode(await response.transform(utf8.decoder).join());
    } on FormatException {
      throw WifiPairingRefused('http_${response.statusCode}');
    }
    if (json is Map<String, dynamic> && json['success'] == true) return json;
    throw WifiPairingRefused(json is Map ? '${json['error']}' : 'http_${response.statusCode}');
  }

  static String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _unhex(String hex) => [for (var i = 0; i + 1 < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
