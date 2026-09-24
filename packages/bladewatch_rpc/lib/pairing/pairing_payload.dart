import 'dart:convert';

/// The pairing QR the car shows (BladeWatch-rdtj.7), as the companion reads it.
///
/// The mirror of `CompanionPairing.Payload` in the service host
/// (app/src/main/java/com/loabletech/bladewatch/auth/CompanionPairing.kt): unpadded base64url
/// of a JSON object with a format version. It carries what the companion needs to FIND and TRUST
/// the car, plus a single-use [code] -- never a credential. The companion redeems [code] exactly
/// once, at `POST /auth/pair`, for its own companion id and token, so a photographed QR is
/// worthless once it has been used or has expired.
class PairingPayload {
  /// The only format this build understands. A newer car's payload is refused, not guessed at.
  static const int formatVersion = 1;

  final String deviceId;

  /// The car's Hyperswarm topic, 64 lowercase hex characters.
  final String pearTopic;

  /// The LAN TLS listener's port.
  final int tlsPort;

  /// SHA-256 over the LAN TLS certificate's DER, 64 lowercase hex characters: the pin.
  final String tlsFingerprint;

  /// HMAC key for LAN discovery probes, 64 lowercase hex characters.
  final String probeKey;

  /// Single-use pairing code.
  final String code;

  final DateTime expiresAt;

  const PairingPayload({
    required this.deviceId,
    required this.pearTopic,
    required this.tlsPort,
    required this.tlsFingerprint,
    required this.probeKey,
    required this.code,
    required this.expiresAt,
  });

  /// Parses a scanned QR. Throws [FormatException] for anything that is not a well-formed
  /// version-[formatVersion] payload.
  factory PairingPayload.decode(String qr) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(qr.trim()))));
    } on FormatException {
      throw const FormatException('not a BladeWatch pairing code');
    }
    if (json is! Map<String, dynamic>) throw const FormatException('not a BladeWatch pairing code');
    if (json['v'] != formatVersion) {
      throw FormatException('unsupported pairing format ${json['v']} (this app reads $formatVersion)');
    }
    final port = json['tlsPort'];
    final exp = json['exp'];
    if (port is! int || port < 1 || port > 65535 || exp is! int) {
      throw const FormatException('malformed pairing code');
    }
    return PairingPayload(
      deviceId: _nonEmpty(json['deviceId']),
      pearTopic: _hex64(json['pearTopic']),
      tlsPort: port,
      tlsFingerprint: _hex64(json['tlsFp']),
      probeKey: _hex64(json['probeKey']),
      code: _nonEmpty(json['code']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(exp, isUtc: true),
    );
  }

  /// The QR text for this payload -- what the car encodes. Used by tests and tools.
  String encode() => base64Url
      .encode(utf8.encode(jsonEncode({
        'v': formatVersion,
        'deviceId': deviceId,
        'pearTopic': pearTopic,
        'tlsPort': tlsPort,
        'tlsFp': tlsFingerprint,
        'probeKey': probeKey,
        'code': code,
        'exp': expiresAt.millisecondsSinceEpoch,
      })))
      .replaceAll('=', '');

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  static final RegExp _hex = RegExp(r'^[0-9a-f]{64}$');

  static String _hex64(Object? value) {
    if (value is String && _hex.hasMatch(value)) return value;
    throw const FormatException('malformed pairing code');
  }

  static String _nonEmpty(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    throw const FormatException('malformed pairing code');
  }
}
