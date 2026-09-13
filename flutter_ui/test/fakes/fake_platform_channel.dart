/// Fake privileged-operations platform channel shared across screen/
/// controller tests so they run with no native Android code and no device
/// attached. Covers the 7 method groups the real channel (BladeWatch-ncbb.2)
/// is organized into: auth, daemon, update, storage, config, logs, device.
/// `group`/`method` are plain strings so this does not need the real
/// MethodChannel implementation to exist yet.
///
/// Usage: in a test, create one `FakePlatformChannel`, call [stub] (or
/// [stubError] / [stubTimeout]) for every channel call the code under test
/// will make, inject the fake wherever the real channel would go, exercise
/// the code, then assert against [calls]. [stubError] takes a
/// [PlatformChannelErrorReason] so tests can simulate the three failure modes
/// that actually occur on this hardware — a dead shell call, the daemon not
/// being up yet, or a denied permission — without inventing ad-hoc strings.
///
/// Implements [PlatformChannel] (BladeWatch-ncbb.2) so it drops in wherever
/// the real `MethodChannelBridge` goes — the typed channel wrappers under
/// lib/platform/ don't need to know which one they're talking to.
/// [PlatformChannelError]/[PlatformChannelErrorReason]/[ChannelTimeoutException]
/// live in lib/platform/platform_channel_error.dart (not here) because the
/// real bridge throws them too — a production type can't live in a test file.
library;

import 'package:bladewatch_ui/platform/platform_channel.dart';
import 'package:bladewatch_ui/platform/platform_channel_error.dart';

export 'package:bladewatch_ui/platform/platform_channel_error.dart';

class ChannelCall {
  final String group;
  final String method;
  final Object? args;

  const ChannelCall(this.group, this.method, this.args);

  @override
  String toString() => '$group/$method($args)';
}

class FakePlatformChannel implements PlatformChannel {
  final List<ChannelCall> calls = [];
  final Map<String, Object?> _responses = {};
  final Map<String, PlatformChannelError> _errors = {};
  final Set<String> _timeouts = {};

  static String _key(String group, String method) => '$group/$method';

  /// Registers a canned success response for [group]/[method].
  void stub(String group, String method, Object? response) {
    final key = _key(group, method);
    _responses[key] = response;
    _errors.remove(key);
    _timeouts.remove(key);
  }

  /// Registers a failure for [group]/[method] with a specific [reason].
  void stubError(String group, String method, PlatformChannelError error) {
    final key = _key(group, method);
    _errors[key] = error;
    _responses.remove(key);
    _timeouts.remove(key);
  }

  /// Registers [group]/[method] to simulate a timeout.
  void stubTimeout(String group, String method) {
    final key = _key(group, method);
    _timeouts.add(key);
    _responses.remove(key);
    _errors.remove(key);
  }

  /// Invokes [group]/[method] with [args]. Records the call, then
  /// returns/throws whatever was stubbed. Throws [StateError] if nothing was
  /// stubbed.
  @override
  Future<T> invoke<T>(String group, String method, [Object? args]) async {
    final key = _key(group, method);
    calls.add(ChannelCall(group, method, args));

    if (_timeouts.contains(key)) {
      throw ChannelTimeoutException(group, method);
    }
    final error = _errors[key];
    if (error != null) {
      throw error;
    }
    if (!_responses.containsKey(key)) {
      throw StateError(
        'FakePlatformChannel: no stub registered for $key — call stub()/stubError()/stubTimeout() first',
      );
    }
    return _responses[key] as T;
  }
}
