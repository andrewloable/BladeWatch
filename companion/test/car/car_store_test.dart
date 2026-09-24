import 'dart:io';

import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  test('round-trips the car, the cursor, the language and the mutes', () async {
    final store = testStore(car: testCar().withCursor(Int64(41)))
      ..language = 'de'
      ..mutedCategories = {'b', 'a'};
    await store.save();

    final again = CarStore(store.file);
    await again.load();
    expect(again.car!.deviceId, 'dev-1');
    expect(again.car!.credential.token, 'tok');
    expect(again.car!.inboxCursor, Int64(41));
    expect(again.language, 'de');
    expect(again.mutedCategories, {'a', 'b'});
    expect(File('${store.file.path}.tmp').existsSync(), isFalse);
  });

  test('the file that holds the token is owner-only on a desktop', () async {
    final store = testStore(car: testCar());
    await store.save();
    final mode = (await store.file.stat()).mode & 0x1ff;
    if (Platform.isMacOS || Platform.isLinux) expect(mode, 0x180, reason: 'rw------- (0600), got ${mode.toRadixString(8)}');
  });

  test('a missing or unreadable file starts unpaired; forgetting the car persists', () async {
    final store = testStore();
    await store.load();
    expect(store.car, isNull);
    store.file.writeAsStringSync('{ nope');
    await store.load();
    expect(store.car, isNull);

    store.car = testCar();
    await store.save();
    store.car = null;
    await store.save();
    final again = CarStore(store.file);
    await again.load();
    expect(again.car, isNull);
  });

  test('a car is built from the pairing QR plus what its code earned', () {
    final qr = PairingPayload(
      deviceId: 'd',
      pearTopic: 'a' * 64,
      tlsPort: 8443,
      tlsFingerprint: 'b' * 64,
      probeKey: 'c' * 64,
      code: 'code',
      expiresAt: DateTime.utc(2030),
    );
    final car = PairedCar.fromPairing(qr, testCredential);
    expect(car.pearTopic, 'a' * 64);
    expect(car.credential.companionId, 'cid');
    expect(car.inboxCursor, Int64.ZERO);
    expect(PairedCar.fromJson({...car.toJson()..remove('inboxCursor')}).inboxCursor, Int64.ZERO);
  });
}
