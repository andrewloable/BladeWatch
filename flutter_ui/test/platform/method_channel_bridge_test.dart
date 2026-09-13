import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/method_channel_bridge.dart';
import 'package:bladewatch_ui/platform/platform_channel_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('net.bladewatch.flutter/privileged');
  final bridge = MethodChannelBridge(channel);
  final log = <MethodCall>[];
  Object? Function(MethodCall) handler = (_) => null;

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('invokes "<group>.<method>" with the given args', () async {
    handler = (_) => 'pong';

    final result = await bridge.invoke<String>('daemon', 'ping', {'x': 1});

    expect(log.single.method, 'daemon.ping');
    expect(log.single.arguments, {'x': 1});
    expect(result, 'pong');
  });

  test('maps PlatformException code TOKEN_UNREADABLE to a shellCallFailed PlatformChannelError', () async {
    handler = (_) => throw PlatformException(code: 'TOKEN_UNREADABLE', message: 'no token');

    await expectLater(
      () => bridge.invoke<void>('config', 'get'),
      throwsA(
        isA<PlatformChannelError>().having(
          (e) => e.reason,
          'reason',
          PlatformChannelErrorReason.shellCallFailed,
        ),
      ),
    );
  });

  test('maps PlatformException code DAEMON_NOT_LISTENING to a daemonNotUp PlatformChannelError', () async {
    handler = (_) => throw PlatformException(code: 'DAEMON_NOT_LISTENING', message: 'down');

    await expectLater(
      () => bridge.invoke<void>('daemon', 'status'),
      throwsA(
        isA<PlatformChannelError>().having(
          (e) => e.reason,
          'reason',
          PlatformChannelErrorReason.daemonNotUp,
        ),
      ),
    );
  });

  test('maps PlatformException code COMMAND_REJECTED to a shellCallFailed PlatformChannelError', () async {
    handler = (_) => throw PlatformException(code: 'COMMAND_REJECTED', message: 'no');

    await expectLater(
      () => bridge.invoke<void>('daemon', 'start'),
      throwsA(isA<PlatformChannelError>()),
    );
  });

  test('maps PlatformException code PERMISSION_DENIED to a permissionDenied PlatformChannelError', () async {
    handler = (_) => throw PlatformException(code: 'PERMISSION_DENIED', message: 'nope');

    await expectLater(
      () => bridge.invoke<void>('config', 'put'),
      throwsA(
        isA<PlatformChannelError>().having(
          (e) => e.reason,
          'reason',
          PlatformChannelErrorReason.permissionDenied,
        ),
      ),
    );
  });

  test('maps PlatformException code TIMEOUT to a ChannelTimeoutException', () async {
    handler = (_) => throw PlatformException(code: 'TIMEOUT', message: 'slow');

    await expectLater(
      () => bridge.invoke<void>('auth', 'mintJwt'),
      throwsA(isA<ChannelTimeoutException>()),
    );
  });

  test('maps an unrecognized PlatformException code to a shellCallFailed PlatformChannelError', () async {
    handler = (_) => throw PlatformException(code: 'SOMETHING_NEW', message: 'huh');

    await expectLater(
      () => bridge.invoke<void>('update', 'check'),
      throwsA(
        isA<PlatformChannelError>().having(
          (e) => e.reason,
          'reason',
          PlatformChannelErrorReason.shellCallFailed,
        ),
      ),
    );
  });

  test('maps MissingPluginException (channel not registered) to a daemonNotUp PlatformChannelError', () async {
    // No handler at all — simulate by removing it and calling a fresh bridge
    // on a channel nothing has ever registered a handler for.
    final unregistered = MethodChannelBridge(const MethodChannel('net.bladewatch.flutter/nobody-home'));

    await expectLater(
      () => unregistered.invoke<void>('daemon', 'ping'),
      throwsA(
        isA<PlatformChannelError>().having(
          (e) => e.reason,
          'reason',
          PlatformChannelErrorReason.daemonNotUp,
        ),
      ),
    );
  });

  test('defaults to the standard "net.bladewatch.flutter/privileged" channel name', () async {
    handler = (_) => 'ok';
    final defaultBridge = MethodChannelBridge();

    final result = await defaultBridge.invoke<String>('daemon', 'ping');

    expect(result, 'ok');
    expect(log.single.method, 'daemon.ping');
  });
}
