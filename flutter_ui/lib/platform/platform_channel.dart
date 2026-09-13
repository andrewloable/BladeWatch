/// Shared shape between the real [MethodChannelBridge] and the shared test
/// double `FakePlatformChannel`
/// (flutter_ui/test/fakes/fake_platform_channel.dart, from
/// BladeWatch-ncbb.5) — every typed channel wrapper under lib/platform/ is
/// written against this interface so a controller test can inject the fake
/// with no other change.
abstract class PlatformChannel {
  /// Invokes `group.method` (e.g. "auth.mintJwt") with [args], returning the
  /// native side's result already deserialized to [T].
  Future<T> invoke<T>(String group, String method, [Object? args]);
}
