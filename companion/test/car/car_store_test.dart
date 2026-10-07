import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  test('round-trips the car, the cursor, the language and the mutes', () async {
    final store = testStore(car: testCar().withLanHint('192.0.2.7').withCursor(Int64(41)))
      ..language = 'de'
      ..mutedCategories = {'b', 'a'};
    await store.save();

    final again = CarStore(store.file);
    await again.load();
    expect(again.car!.deviceId, 'dev-1');
    expect(again.car!.credential.token, 'tok');
    expect(again.car!.inboxCursor, Int64(41));
    expect(again.car!.lanHint, '192.0.2.7', reason: 'kept, and not lost by withCursor (BladeWatch-rdtj.38)');
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
    // BladeWatch-w7by: what would not load is kept, owner-only, before any save can overwrite it.
    final kept = store.file.parent.listSync().whereType<File>().where((f) => f.path.contains('.damaged-')).toList();
    expect(kept, hasLength(1));
    expect(kept.single.readAsStringSync(), '{ nope');
    if (Platform.isMacOS || Platform.isLinux) expect((kept.single.statSync().mode & 0x1ff), 0x180);

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
    expect(car.toJson().containsKey('lanHint'), isFalse, reason: 'no hint until the car has been reached on Wi-Fi');
    expect(PairedCar.fromJson(car.toJson()).lanHint, isNull);
  });

  group('relay access (BladeWatch-a7mu)', () {
    test('round-trips the switch and the key', () async {
      final store = testStore(car: testCar())
        ..relayEnabled = true
        ..relayKey = '482109375562';
      await store.save();
      final again = CarStore(store.file);
      await again.load();
      expect(again.relayEnabled, isTrue);
      expect(again.relayKey, '482109375562');
      expect(again.relayKeyInUse, '482109375562');
    });

    test('a file from before the relay loads as off, still paired', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>..remove('relay');
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull);
      expect(again.relayEnabled, isFalse);
      expect(again.relayKeyInUse, isNull);
    });

    test('a bad relay entry never un-pairs this device', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>;
      raw['relay'] = {'enabled': 'yes', 'key': 482109375562};
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull, reason: 'the pairing is kept');
      expect(again.relayEnabled, isFalse);
      expect(again.relayKey, isNull);
    });

    test('the key in use needs the switch on and a well-formed key', () {
      final store = testStore()..relayKey = '482109375562';
      expect(store.relayKeyInUse, isNull, reason: 'switched off keeps the key but uses none');
      store.relayEnabled = true;
      expect(store.relayKeyInUse, '482109375562');
      store.relayKey = '4821';
      expect(store.relayKeyInUse, isNull, reason: 'Pear would refuse it on every search');
    });
  });

  group('settings lock cache (BladeWatch-hr6r)', () {
    test('round-trips the known lock state', () async {
      final store = testStore(car: testCar())..settingsLockKnown = true;
      await store.save();
      final again = CarStore(store.file);
      await again.load();
      expect(again.settingsLockKnown, isTrue);
    });

    test('a file from before the settings lock loads as unknown (false), still paired', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>..remove('settingsLock');
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull);
      expect(again.settingsLockKnown, isFalse);
    });

    test('a malformed settingsLock entry never un-pairs this device', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>;
      raw['settingsLock'] = 'not a map';
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull, reason: 'the pairing is kept');
      expect(again.settingsLockKnown, isFalse);
    });
  });

  group('biometric unlock opt-in (BladeWatch-hr6r.6)', () {
    test('round-trips the opt-in', () async {
      final store = testStore(car: testCar())..biometricUnlockEnabled = true;
      await store.save();
      final again = CarStore(store.file);
      await again.load();
      expect(again.biometricUnlockEnabled, isTrue);
    });

    test('a file from before biometric unlock existed loads as off, still paired', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>..remove('biometricUnlock');
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull);
      expect(again.biometricUnlockEnabled, isFalse);
    });

    test('a malformed biometricUnlock entry never un-pairs this device', () async {
      final store = testStore(car: testCar());
      await store.save();
      final raw = jsonDecode(await store.file.readAsString()) as Map<String, Object?>;
      raw['biometricUnlock'] = 'not a bool';
      await store.file.writeAsString(jsonEncode(raw));
      final again = CarStore(store.file);
      await again.load();
      expect(again.car, isNotNull, reason: 'the pairing is kept');
      expect(again.biometricUnlockEnabled, isFalse);
    });
  });
}
