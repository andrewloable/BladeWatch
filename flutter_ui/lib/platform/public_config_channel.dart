import 'platform_channel.dart';

/// Dart side of the `publicConfig.*` channel group (BladeWatch-hygs) — the
/// daemon's PUBLIC config store (`UnifiedConfigManager`), which backs the
/// Status-overlay and Privacy settings screens.
///
/// Separate from [ConfigChannel] on purpose: that one wraps the *secret*
/// store, and the two must not be reachable through one class where a typo'd
/// section name silently crosses between them. The daemon also refuses any
/// section outside its own allowlist (`statusOverlay`, `developerOptions`),
/// so nothing here can widen what is writable.
///
/// Booleans only — both screens are switch-only. Add a typed method if a
/// non-boolean setting ever moves here rather than a dynamic-valued put.
class PublicConfigChannel {
  final PlatformChannel _channel;

  const PublicConfigChannel(this._channel);

  /// Every flag in the section. The daemon substitutes native's own defaults
  /// for absent keys, so an **empty map means the read failed** — not "all
  /// off". Callers keep their own fallbacks for that case.
  Future<Map<String, bool>> getSection(String section) async {
    final result = await _channel.invoke<Map<Object?, Object?>>('publicConfig', 'getSection', {'section': section});
    return result.map((key, value) => MapEntry(key as String, value as bool));
  }

  Future<bool> putBoolean(String section, String key, bool value) =>
      _channel.invoke<bool>('publicConfig', 'putBoolean', {'section': section, 'key': key, 'value': value});
}
