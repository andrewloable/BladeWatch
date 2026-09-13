import 'platform_channel.dart';

/// Which of Android's two location providers are currently enabled — mirrors
/// what `LocationGpsController.selectedProvider()` checks natively, except
/// the precedence decision itself (prefer gps, else network) is left to
/// `LocationController` so it is covered by this port's Dart controller
/// tests rather than living untested in Kotlin.
class LocationProviderAvailability {
  final bool gps;
  final bool network;
  const LocationProviderAvailability({required this.gps, required this.network});
}

/// Result of a `location.startUpdates` call — mirrors the `runCatching`
/// around `LocationManager.requestLocationUpdates` in
/// `LocationGpsController.start()`.
class LocationStartResult {
  final bool ok;
  final String? reason;
  const LocationStartResult({required this.ok, this.reason});
}

/// A raw GPS fix as the native `location.currentSample` channel call reports
/// it. Deliberately a separate type from `screens/location/location_models.dart`'s
/// `LocationCarGps` — `platform/` does not depend on `screens/`; the
/// controller maps this into its own model.
class RawLocationSample {
  final double latitude;
  final double longitude;
  final double? bearingDegrees;
  final double? speedMetersPerSecond;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final String provider;
  final int timestampMs;

  const RawLocationSample({
    required this.latitude,
    required this.longitude,
    this.bearingDegrees,
    this.speedMetersPerSecond,
    this.accuracyMeters,
    this.altitudeMeters,
    required this.provider,
    required this.timestampMs,
  });
}

/// Dart side of the `location.*` channel group (BladeWatch-yz1e.6) — thin
/// wrapper over the Kotlin `LocationServiceChannel`
/// (`flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/location/LocationServiceChannel.kt`),
/// which owns the actual `LocationManager` registration. Ground truth:
/// `LocationGpsController.kt`. All state-machine behaviour (permission/
/// provider/staleness transitions, provider precedence) lives in
/// `LocationController`, not here — this class only carries raw OS
/// primitives across the platform boundary.
class LocationChannel {
  final PlatformChannel _channel;

  const LocationChannel(this._channel);

  Future<bool> hasPermission() => _channel.invoke<bool>('location', 'hasPermission');

  /// Triggers the system permission dialog and resolves once the user
  /// responds (granted/denied) — mirrors `LocationFragment`'s
  /// `ActivityResultContracts.RequestPermission()` launcher.
  Future<bool> requestPermission() => _channel.invoke<bool>('location', 'requestPermission');

  Future<LocationProviderAvailability> providerEnabled() async {
    final result = await _channel.invoke<Map<Object?, Object?>>('location', 'providerEnabled');
    return LocationProviderAvailability(
      gps: result['gps'] as bool? ?? false,
      network: result['network'] as bool? ?? false,
    );
  }

  /// Begins listening on [provider] ("gps" or "network"), caching the latest
  /// sample for [currentSample] to read.
  Future<LocationStartResult> startUpdates(String provider) async {
    final result = await _channel.invoke<Map<Object?, Object?>>('location', 'startUpdates', {'provider': provider});
    return LocationStartResult(ok: result['ok'] as bool? ?? false, reason: result['reason'] as String?);
  }

  Future<void> stopUpdates() => _channel.invoke<void>('location', 'stopUpdates');

  /// The most recent cached sample since the last [startUpdates], or null if
  /// none has arrived yet.
  Future<RawLocationSample?> currentSample() async {
    final result = await _channel.invoke<Map<Object?, Object?>?>('location', 'currentSample');
    if (result == null) return null;
    return RawLocationSample(
      latitude: (result['latitude'] as num).toDouble(),
      longitude: (result['longitude'] as num).toDouble(),
      bearingDegrees: (result['bearingDegrees'] as num?)?.toDouble(),
      speedMetersPerSecond: (result['speedMetersPerSecond'] as num?)?.toDouble(),
      accuracyMeters: (result['accuracyMeters'] as num?)?.toDouble(),
      altitudeMeters: (result['altitudeMeters'] as num?)?.toDouble(),
      provider: result['provider'] as String,
      timestampMs: result['timestampMs'] as int,
    );
  }
}
