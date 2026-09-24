import 'dart:convert';

import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-rdtj.7: the pairing QR, as the companion reads what the car encodes.
void main() {
  // Byte for byte the GOLDEN in app/src/test/java/com/loabletech/bladewatch/auth/
  // CompanionPairingTest.kt: the car's encoder and this decoder are pinned to the same string.
  const golden = 'eyJ2IjoxLCJkZXZpY2VJZCI6ImJ5ZC10ZXN0IiwicGVhclRvcGljIjoiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYiIsInRsc1BvcnQiOjg0NDMsInRsc0ZwIjoiY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZCIsInByb2JlS2V5IjoiZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZiIsImNvZGUiOiJjMGRlIiwiZXhwIjoxNzAwMDAwMzAwMDAwfQ';

  String qr(Map<String, Object?> fields) => base64Url.encode(utf8.encode(jsonEncode(fields))).replaceAll('=', '');

  Map<String, Object?> valid() => {
        'v': 1,
        'deviceId': 'byd-test',
        'pearTopic': 'ab' * 32,
        'tlsPort': 8443,
        'tlsFp': 'cd' * 32,
        'probeKey': 'ef' * 32,
        'code': 'c0de',
        'exp': 1700000300000,
      };

  test('decodes the car-side golden exactly', () {
    final p = PairingPayload.decode(golden);
    expect(p.deviceId, 'byd-test');
    expect(p.pearTopic, 'ab' * 32);
    expect(p.tlsPort, 8443);
    expect(p.tlsFingerprint, 'cd' * 32);
    expect(p.probeKey, 'ef' * 32);
    expect(p.code, 'c0de');
    expect(p.expiresAt, DateTime.fromMillisecondsSinceEpoch(1700000300000, isUtc: true));
  });

  test('round-trips through encode, which pads nothing', () {
    final p = PairingPayload.decode(golden);
    expect(p.encode(), isNot(contains('=')));
    final again = PairingPayload.decode(p.encode());
    expect(again.code, p.code);
    expect(again.expiresAt, p.expiresAt);
    expect(again.tlsFingerprint, p.tlsFingerprint);
  });

  test('tolerates surrounding whitespace and padding a scanner might add', () {
    final padded = base64Url.encode(utf8.encode(jsonEncode(valid())));
    expect(PairingPayload.decode(' $padded\n').code, 'c0de');
  });

  test('knows when it has expired', () {
    final p = PairingPayload.decode(golden);
    expect(p.isExpiredAt(p.expiresAt.subtract(const Duration(seconds: 1))), isFalse);
    expect(p.isExpiredAt(p.expiresAt), isTrue);
  });

  test('refuses a newer format instead of guessing', () {
    expect(() => PairingPayload.decode(qr(valid()..['v'] = 2)), throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('unsupported'))));
  });

  test('refuses anything that is not a pairing code', () {
    for (final bad in ['', 'not base64 !!', qr({'hello': 'world'}), base64Url.encode(utf8.encode('[1,2]')), base64Url.encode([0xff, 0xfe])]) {
      expect(() => PairingPayload.decode(bad), throwsFormatException, reason: bad);
    }
  });

  test('refuses malformed fields', () {
    final cases = <String, Object?>{
      'deviceId': '',
      'pearTopic': 'AB' * 32, // upper case is not what the car writes
      'tlsFp': 'cd' * 31,
      'probeKey': 42,
      'code': null,
      'tlsPort': 0,
      'exp': '1700000300000',
    };
    cases.forEach((field, value) {
      expect(() => PairingPayload.decode(qr(valid()..[field] = value)), throwsFormatException, reason: field);
    });
    expect(() => PairingPayload.decode(qr(valid()..['tlsPort'] = 70000)), throwsFormatException);
  });
}
