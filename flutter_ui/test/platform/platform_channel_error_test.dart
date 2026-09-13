import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/platform_channel_error.dart';

void main() {
  group('PlatformChannelError', () {
    test('toString includes the reason and the message', () {
      const error = PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'not up yet');

      expect(error.toString(), contains('daemonNotUp'));
      expect(error.toString(), contains('not up yet'));
    });
  });

  group('ChannelTimeoutException', () {
    test('toString includes the group and method', () {
      const exception = ChannelTimeoutException('daemon', 'status');

      expect(exception.toString(), contains('daemon'));
      expect(exception.toString(), contains('status'));
      expect(exception.toString(), contains('timed out'));
    });
  });
}
