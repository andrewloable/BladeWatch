import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The car, found on this network: where to connect, and the certificate pin it answered with.
class LanEndpoint {
  final InternetAddress address;
  final int port;
  final String fingerprint;

  const LanEndpoint(this.address, this.port, this.fingerprint);
}

/// Finds the car on the local network with a signed discovery probe (BladeWatch-rdtj.5/.8).
///
/// UNICAST, never broadcast: on the head unit the Wi-Fi firmware drops broadcast (measured
/// 2026-09-24, BladeWatch-rdtj.5), and iOS forbids sending it without Apple's multicast
/// entitlement. So the probe goes to the car's last-known address first, then to every host of
/// this device's /24 -- 254 datagrams of 256 bytes, and only the car holding the key answers.
///
/// Wire format: `LanDiscoveryResponder` (app/src/main/java/com/loabletech/bladewatch/server/). A
/// reply counts only if its HMAC verifies under the probe key, it echoes THIS probe's nonce, and
/// the fingerprint it carries is the one pinned at pairing; anything else is silently ignored.
class LanProber {
  LanProber(this._key, {this.port = 18443, Random? random, DateTime Function()? now})
      : _random = random ?? Random.secure(),
        _now = now ?? DateTime.now;

  final List<int> _key;
  final int port;
  final Random _random;
  final DateTime Function() _now;

  static const _probeMagic = 'BWPROBE1';
  static const _replyMagic = 'BWREPLY1';
  static const _probeBytes = 256;

  /// Sends one probe to [candidates] (in order, all at once) and returns the first valid reply,
  /// or null after [timeout].
  Future<LanEndpoint?> find(List<InternetAddress> candidates, {required String pinnedFingerprint, Duration timeout = const Duration(milliseconds: 800)}) async {
    if (candidates.isEmpty) return null;
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final nonce = Uint8List.fromList(List.generate(16, (_) => _random.nextInt(256)));
    final probe = buildProbe(_key, nonce, _now().millisecondsSinceEpoch);
    final result = Completer<LanEndpoint?>();
    final timer = Timer(timeout, () => result.isCompleted ? null : result.complete(null));
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null || result.isCompleted) return;
      final endpoint = _verifyReply(datagram, nonce, pinnedFingerprint);
      if (endpoint != null) result.complete(endpoint);
    });
    for (final address in candidates) {
      socket.send(probe, address, port);
    }
    final endpoint = await result.future;
    timer.cancel();
    socket.close();
    return endpoint;
  }

  LanEndpoint? _verifyReply(Datagram d, Uint8List nonce, String pinnedFingerprint) {
    final b = d.data;
    if (b.length <= 56 || ascii.decode(b.sublist(0, 8), allowInvalid: true) != _replyMagic) return null;
    if (!_equal(b.sublist(8, 24), nonce)) return null; // a reply to somebody else's probe
    final mac = b.sublist(24, 56);
    final json = b.sublist(56);
    if (!_equal(Hmac(sha256, _key).convert([...b.sublist(0, 24), ...json]).bytes, mac)) return null;
    try {
      final body = jsonDecode(utf8.decode(json)) as Map<String, dynamic>;
      if (body['fp'] != pinnedFingerprint) return null; // not the car we paired with, or re-keyed
      return LanEndpoint(d.address, body['port'] as int, pinnedFingerprint);
    } catch (_) {
      return null;
    }
  }

  /// A probe exactly as the car expects it: magic, nonce, ms timestamp, HMAC, zero padding.
  static Uint8List buildProbe(List<int> key, Uint8List nonce, int timestampMs) {
    final signed = Uint8List(32)
      ..setRange(0, 8, ascii.encode(_probeMagic))
      ..setRange(8, 24, nonce);
    ByteData.sublistView(signed, 24, 32).setInt64(0, timestampMs);
    final probe = Uint8List(_probeBytes)
      ..setRange(0, 32, signed)
      ..setRange(32, 64, Hmac(sha256, key).convert(signed).bytes);
    return probe;
  }

  /// Where to look: [lastKnown] first, then every other host on each of this device's private
  /// IPv4 /24s. Capped at /24 even on larger subnets; a car not found here is reached over Pear.
  static Future<List<InternetAddress>> candidates({InternetAddress? lastKnown, Future<List<InternetAddress>> Function()? ownAddresses}) async {
    final out = <InternetAddress>[?lastKnown];
    for (final a in await (ownAddresses ?? _ownAddresses)()) {
      if (a.type != InternetAddressType.IPv4 || a.isLoopback || !_isPrivate(a.rawAddress)) continue;
      final r = a.rawAddress;
      for (var host = 1; host < 255; host++) {
        if (host == r[3]) continue;
        final candidate = InternetAddress.fromRawAddress(Uint8List.fromList([r[0], r[1], r[2], host]));
        if (candidate != lastKnown) out.add(candidate);
      }
    }
    return out;
  }

  /// This device's IPv4 addresses, on every interface.
  static Future<List<InternetAddress>> _ownAddresses() async =>
      [for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) ...iface.addresses];

  static bool _isPrivate(List<int> r) =>
      r[0] == 10 || (r[0] == 172 && r[1] >= 16 && r[1] <= 31) || (r[0] == 192 && r[1] == 168);

  static bool _equal(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
