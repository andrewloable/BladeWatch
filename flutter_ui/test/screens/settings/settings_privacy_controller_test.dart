import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_privacy_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  SettingsPrivacyController build({
    Future<({bool timingLogsEnabled, bool debugLogsEnabled})> Function()? loadLogging,
    Future<void> Function(String key, bool value)? persistLogging,
  }) =>
      SettingsPrivacyController(
        storageService: StorageServiceClient(rpc),
        loadLoggingSettings: loadLogging,
        persistLogging: persistLogging,
      );

  setUp(() {
    rpc = FakeRpcClient();
  });

  group('load()', () {
    test('populates clip count and total size from StorageService', () async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 42, 'recordingsSize': 5242880});
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.clipCount, 42);
      expect(c.storageAvailable, isTrue);
      expect(c.formattedSize, '5.0 MB');
    });

    test('a storage RPC failure marks storage unavailable rather than crashing', () async {
      rpc.stubError('StorageService', 'GetStorageSettings', const ConnectError('unavailable', 'down'));
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.storageAvailable, isFalse);
    });

    test('logging toggles default to native (timing=on, debug=off) with no loader injected', () async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
      final c = build();

      await c.load();

      expect(c.timingLogsEnabled, isTrue);
      expect(c.debugLogsEnabled, isFalse);
    });

    test('logging toggles reflect an injected loader', () async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
      final c = build(loadLogging: () async => (timingLogsEnabled: false, debugLogsEnabled: true));

      await c.load();

      expect(c.timingLogsEnabled, isFalse);
      expect(c.debugLogsEnabled, isTrue);
    });

    test('a logging loader that throws falls back to native defaults', () async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
      final c = build(loadLogging: () async => throw StateError('boom'));

      await c.load();

      expect(c.timingLogsEnabled, isTrue);
      expect(c.debugLogsEnabled, isFalse);
    });
  });

  group('formattedSize()', () {
    Future<String> sizeFor(int bytes) async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 1, 'recordingsSize': bytes});
      final c = build();
      await c.load();
      return c.formattedSize!;
    }

    test('bytes under 1KB show as B', () async => expect(await sizeFor(512), '512 B'));
    test('under 1MB shows as KB', () async => expect(await sizeFor(2048), '2.0 KB'));
    test('under 1GB shows as MB', () async => expect(await sizeFor(3 * 1024 * 1024), '3.0 MB'));
    test('under 1TB shows as GB', () async => expect(await sizeFor(2 * 1024 * 1024 * 1024), '2.00 GB'));
    test('1TB and above shows as TB', () async => expect(await sizeFor(2 * 1024 * 1024 * 1024 * 1024), '2.00 TB'));
  });

  group('toggles', () {
    test('with no persist function injected, toggling still updates state (default no-op persist)', () async {
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
      final c = build();
      await c.load();

      await c.setTimingLogsEnabled(false);
      await c.setDebugLogsEnabled(true);

      expect(c.timingLogsEnabled, isFalse);
      expect(c.debugLogsEnabled, isTrue);
    });

    test('setTimingLogsEnabled updates state, notifies, and persists', () async {
      final calls = <(String, bool)>[];
      final c = build(persistLogging: (k, v) async => calls.add((k, v)));
      var notified = 0;
      c.addListener(() => notified++);

      await c.setTimingLogsEnabled(false);

      expect(c.timingLogsEnabled, isFalse);
      expect(notified, 1);
      expect(calls, [('timingLogsEnabled', false)]);
    });

    test('setDebugLogsEnabled updates state, notifies, and persists', () async {
      final calls = <(String, bool)>[];
      final c = build(persistLogging: (k, v) async => calls.add((k, v)));

      await c.setDebugLogsEnabled(true);

      expect(c.debugLogsEnabled, isTrue);
      expect(calls, [('debugLogsEnabled', true)]);
    });

    // BladeWatch-hygs: persistLogging is now a real IPC write — see
    // SettingsOverlayController's matching tests.
    test('a failed timing-logs write snaps the switch back and notifies again', () async {
      final c = build(persistLogging: (k, v) async => throw StateError('daemon down'));
      var notified = 0;
      c.addListener(() => notified++);

      await c.setTimingLogsEnabled(false);

      expect(c.timingLogsEnabled, isTrue);
      expect(notified, 2);
    });

    test('a failed debug-logs write snaps the switch back', () async {
      final c = build(persistLogging: (k, v) async => throw StateError('daemon down'));

      await c.setDebugLogsEnabled(true);

      expect(c.debugLogsEnabled, isFalse);
    });
  });
}
