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

  /// The Diagnostics Camera tile's two fields, typed (BladeWatch-i2wv).
  ///
  /// [getSection] coerces every value to bool, and `probedCameraId` is an int, so
  /// this is the typed method the class comment above asks for rather than a
  /// dynamic-valued read.
  ///
  /// Null means the READ FAILED. That is not the same as a probedCameraId of -1,
  /// which means "the daemon is up and has not probed a camera yet" — the tile
  /// renders those two differently.
  ///
  /// Read only: `camera` is readable over IPC but deliberately NOT writable, so
  /// there is no setter here by design.
  Future<CameraProbeRead?> getCameraProbe() async {
    final result = await _channel
        .invoke<Map<Object?, Object?>?>('publicConfig', 'getCameraProbe', const {});
    if (result == null) return null;
    return CameraProbeRead(
      probedCameraId: (result['probedCameraId'] as num?)?.toInt() ?? -1,
      manualOverride: result['manualOverride'] as bool? ?? false,
    );
  }

  Future<bool> putBoolean(String section, String key, bool value) =>
      _channel.invoke<bool>('publicConfig', 'putBoolean', {'section': section, 'key': key, 'value': value});
}

/// One read of the daemon's `camera` config section — see
/// [PublicConfigChannel.getCameraProbe].
class CameraProbeRead {
  final int probedCameraId;
  final bool manualOverride;

  const CameraProbeRead({required this.probedCameraId, required this.manualOverride});
}
