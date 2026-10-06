import 'package:bladewatch_ui/screens/settings/settings_relay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The daemon's pear_relay secret section, in memory. [failWrites]/[throwOnWrite] stand in
/// for a daemon that is down.
class _FakeSection {
  final Map<String, String> values = {};
  bool failWrites = false;
  bool throwOnWrite = false;
  bool throwOnRead = false;
  final List<String> writes = [];

  SettingsRelayController controller() => SettingsRelayController(
        read: (key) async {
          if (throwOnRead) throw StateError('daemon down');
          return values[key];
        },
        write: (key, value) async {
          writes.add('$key=$value');
          if (throwOnWrite) throw StateError('daemon down');
          if (failWrites) return false;
          values[key] = value;
          return true;
        },
        delete: (key) async {
          writes.add('-$key');
          if (throwOnWrite) throw StateError('daemon down');
          if (failWrites) return false;
          values.remove(key);
          return true;
        },
      );
}

void main() {
  group('normalize', () {
    test('accepts 12 ASCII digits, ignoring spaces and dashes', () {
      expect(SettingsRelayController.normalize('4821-0937-5562'), '482109375562');
      expect(SettingsRelayController.normalize(' 4821 0937 5562 '), '482109375562');
      expect(SettingsRelayController.normalize('482109375562'), '482109375562');
    });

    test('rejects anything else', () {
      for (final bad in ['', '4821-0937', '4821-0937-55621', 'abcd-0937-5562', '٤821-0937-5562']) {
        expect(SettingsRelayController.normalize(bad), isNull, reason: bad);
      }
    });
  });

  group('load', () {
    test('nothing stored: off, no key, the field is offered', () async {
      final c = _FakeSection().controller();
      expect(c.loading, isTrue);
      await c.load();
      expect(c.loading, isFalse);
      expect(c.enabled, isFalse);
      expect(c.hasKey, isFalse);
      expect(c.maskedKey, isNull);
      expect(c.showKeyField, isTrue);
    });

    test('on with a key: only the last group is ever exposed', () async {
      final s = _FakeSection()..values.addAll({'enabled': 'true', 'key': '482109375562'});
      final c = s.controller();
      await c.load();
      expect(c.enabled, isTrue);
      expect(c.hasKey, isTrue);
      expect(c.maskedKey, '••••-••••-5562');
      expect(c.showKeyField, isFalse);
    });

    test('a stored value that is not a relay key counts as no key', () async {
      final s = _FakeSection()..values.addAll({'enabled': 'true', 'key': '1234'});
      final c = s.controller();
      await c.load();
      expect(c.hasKey, isFalse);
    });

    test('an unreadable store loads as off', () async {
      final s = _FakeSection()
        ..values['enabled'] = 'true'
        ..throwOnRead = true;
      final c = s.controller();
      await c.load();
      expect(c.loading, isFalse);
      expect(c.enabled, isFalse);
      expect(c.hasKey, isFalse);
    });
  });

  group('setEnabled', () {
    test('writes the string the daemon reads', () async {
      final s = _FakeSection();
      final c = s.controller();
      await c.load();
      await c.setEnabled(true);
      expect(s.values['enabled'], 'true');
      expect(c.enabled, isTrue);
      await c.setEnabled(false);
      expect(s.values['enabled'], 'false');
      expect(c.enabled, isFalse);
      expect(c.error, isNull);
    });

    test('snaps back when the daemon refuses the write', () async {
      final s = _FakeSection()..failWrites = true;
      final c = s.controller();
      await c.load();
      await c.setEnabled(true);
      expect(c.enabled, isFalse);
      expect(c.error, RelayKeyError.saveFailed);
    });

    test('snaps back when the write throws', () async {
      final s = _FakeSection()..throwOnWrite = true;
      final c = s.controller();
      await c.load();
      await c.setEnabled(true);
      expect(c.enabled, isFalse);
      expect(c.error, RelayKeyError.saveFailed);
    });
  });

  group('saveKey', () {
    test('stores the bare digits and keeps only the last group', () async {
      final s = _FakeSection()..values['enabled'] = 'true';
      final c = s.controller();
      await c.load();
      expect(await c.saveKey('4821-0937-5562'), isTrue);
      expect(s.values['key'], '482109375562');
      expect(c.maskedKey, '••••-••••-5562');
      expect(c.showKeyField, isFalse);
      expect(c.saving, isFalse);
      expect(c.error, isNull);
    });

    test('a malformed key writes nothing and says why', () async {
      final s = _FakeSection();
      final c = s.controller();
      await c.load();
      expect(await c.saveKey('4821-0937'), isFalse);
      expect(s.writes, isEmpty);
      expect(c.error, RelayKeyError.invalid);
      expect(c.hasKey, isFalse);
    });

    test('a failed write keeps the old key and says so', () async {
      final s = _FakeSection()..values['key'] = '111122223333';
      final c = s.controller();
      await c.load();
      c.startEditing();
      s.failWrites = true;
      expect(await c.saveKey('4821-0937-5562'), isFalse);
      expect(c.error, RelayKeyError.saveFailed);
      expect(c.maskedKey, '••••-••••-3333');
      expect(c.showKeyField, isTrue);
    });
  });

  test('Change opens the field and Cancel closes it again', () async {
    final s = _FakeSection()..values['key'] = '482109375562';
    final c = s.controller();
    await c.load();
    expect(c.showKeyField, isFalse);
    c.startEditing();
    expect(c.showKeyField, isTrue);
    c.cancelEditing();
    expect(c.showKeyField, isFalse);
    expect(c.error, isNull);
  });

  group('removeKey', () {
    test('deletes the key and turns relay access off', () async {
      final s = _FakeSection()..values.addAll({'enabled': 'true', 'key': '482109375562'});
      final c = s.controller();
      await c.load();
      await c.removeKey();
      expect(s.values.containsKey('key'), isFalse);
      expect(s.values['enabled'], 'false');
      expect(c.hasKey, isFalse);
      expect(c.enabled, isFalse);
      expect(c.error, isNull);
    });

    test('a failed removal keeps what is stored and says so', () async {
      final s = _FakeSection()..values.addAll({'enabled': 'true', 'key': '482109375562'});
      final c = s.controller();
      await c.load();
      s.throwOnWrite = true;
      await c.removeKey();
      expect(c.hasKey, isTrue);
      expect(c.enabled, isTrue);
      expect(c.error, RelayKeyError.saveFailed);
    });
  });
}
