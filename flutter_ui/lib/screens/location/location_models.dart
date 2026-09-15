/// Ground truth: `LocationModels.kt`. A raw GPS fix as read off the
/// platform's `LocationManager` (`platform/location_channel.dart`).
class LocationCarGps {
  final double latitude;
  final double longitude;
  final double? bearingDegrees;
  final double? speedMetersPerSecond;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final String provider;
  final int timestampMs;

  const LocationCarGps({
    required this.latitude,
    required this.longitude,
    this.bearingDegrees,
    this.speedMetersPerSecond,
    this.accuracyMeters,
    this.altitudeMeters,
    required this.provider,
    required this.timestampMs,
  });

  /// Mirrors `LocationCarGps.isUsable()` — rejects out-of-range coordinates
  /// and the (0, 0) "no fix yet" sentinel some providers report.
  bool get isUsable {
    if (latitude < -90.0 || latitude > 90.0) return false;
    if (longitude < -180.0 || longitude > 180.0) return false;
    return !(latitude == 0.0 && longitude == 0.0);
  }
}

/// Ground truth: `LocationModels.kt`'s `LocationUiState` sealed interface.
/// Unlike native, there is no shared `location` property on the base type —
/// this project's sealed-class convention (see `TripsLoadState`) keeps each
/// variant's own fields distinct; use [locationOf] where the reducers need
/// the native code's generic "whatever location the current state carries"
/// read.
sealed class LocationUiState {
  const LocationUiState();
}

class LocationLoading extends LocationUiState {
  const LocationLoading();
}

class LocationPermissionMissing extends LocationUiState {
  const LocationPermissionMissing();
}

class LocationPermissionDenied extends LocationUiState {
  const LocationPermissionDenied();
}

class LocationProviderDisabled extends LocationUiState {
  const LocationProviderDisabled();
}

class LocationWaitingForFix extends LocationUiState {
  const LocationWaitingForFix();
}

class LocationFresh extends LocationUiState {
  final LocationCarGps location;
  const LocationFresh(this.location);
}

class LocationStale extends LocationUiState {
  final LocationCarGps location;
  const LocationStale(this.location);
}

class LocationTileFailure extends LocationUiState {
  final LocationCarGps? location;
  final String? reason;
  const LocationTileFailure({this.location, this.reason});
}

class LocationError extends LocationUiState {
  final LocationCarGps? location;
  final String? reason;
  const LocationError({this.location, this.reason});
}

/// The location carried by [state], if any — mirrors native's generic
/// `LocationUiState.location` interface property (only [LocationFresh] /
/// [LocationStale] / [LocationTileFailure] / [LocationError] ever carry one).
LocationCarGps? locationOf(LocationUiState state) => switch (state) {
      LocationFresh(:final location) => location,
      LocationStale(:final location) => location,
      LocationTileFailure(:final location) => location,
      LocationError(:final location) => location,
      _ => null,
    };

/// Ground truth: `LocationModels.kt`'s `LocationMapViewportState`.
class LocationMapViewportState {
  final bool followCar;
  final bool firstLocationSeen;
  final LocationCarGps? lastLocation;

  const LocationMapViewportState({this.followCar = true, this.firstLocationSeen = false, this.lastLocation});

  LocationMapViewportState copyWith({bool? followCar, bool? firstLocationSeen, LocationCarGps? lastLocation}) =>
      LocationMapViewportState(
        followCar: followCar ?? this.followCar,
        firstLocationSeen: firstLocationSeen ?? this.firstLocationSeen,
        lastLocation: lastLocation ?? this.lastLocation,
      );
}

/// Ground truth: `LocationModels.kt`'s `LocationMapUpdate`.
class LocationMapUpdate {
  final LocationMapViewportState viewportState;
  final bool centerMap;
  final double? zoomLevel;

  const LocationMapUpdate({required this.viewportState, required this.centerMap, this.zoomLevel});
}

/// Ground truth: `LocationModels.kt`'s `LocationUiModePreference` — the map's
/// own night/day tile override, independent of the app-wide theme
/// (`LocationAppearanceResolver` below combines both). Persisted via
/// `PrefsChannel.getLocationUiMode`/`setLocationUiMode`, matching native's
/// `LocationSettingsStore`.
enum LocationUiModePreference {
  auto('auto'),
  light('light'),
  dark('dark');

  final String storedValue;
  const LocationUiModePreference(this.storedValue);

  static LocationUiModePreference fromStoredValue(String? value) => LocationUiModePreference.values.firstWhere(
        (e) => e.storedValue == value,
        orElse: () => LocationUiModePreference.auto,
      );
}

/// Ground truth: `LocationModels.kt`'s `object LocationStateReducer`.
abstract final class LocationStateReducer {
  static const staleThresholdMs = 30000;

  static LocationUiState permissionState(bool prompted) =>
      prompted ? const LocationPermissionDenied() : const LocationPermissionMissing();

  static LocationUiState providerUnavailable() => const LocationProviderDisabled();

  static LocationUiState waitingForFix(LocationUiState current, int nowMs) {
    final last = locationOf(current);
    if (last == null) return const LocationWaitingForFix();
    return refreshStaleness(LocationFresh(last), nowMs);
  }

  static LocationUiState onLocationSample(LocationUiState current, LocationCarGps sample) {
    if (!sample.isUsable) return current;
    return LocationFresh(sample);
  }

  static LocationUiState refreshStaleness(LocationUiState current, int nowMs) => switch (current) {
        LocationFresh(:final location) =>
          (nowMs - location.timestampMs >= staleThresholdMs) ? LocationStale(location) : current,
        LocationStale() => current,
        _ => current,
      };

  static LocationUiState tileFailure(LocationUiState current, String reason) => switch (current) {
        LocationFresh(:final location) => LocationTileFailure(location: location, reason: reason),
        LocationStale(:final location) => LocationTileFailure(location: location, reason: reason),
        LocationTileFailure(:final location) => LocationTileFailure(location: location, reason: reason),
        _ => current,
      };
}

/// Ground truth: `LocationModels.kt`'s `object LocationMapReducer` +
/// `object LocationMapBearingMapper`.
abstract final class LocationMapReducer {
  static LocationMapViewportState onUserPan(LocationMapViewportState state) => state.copyWith(followCar: false);

  static LocationMapUpdate onValidLocation(LocationMapViewportState state, LocationCarGps location) {
    final next = state.copyWith(firstLocationSeen: true, lastLocation: location);
    return LocationMapUpdate(
      viewportState: next,
      centerMap: state.followCar,
      zoomLevel: state.firstLocationSeen ? null : 17.5,
    );
  }

  static LocationMapViewportState onFollowRequested(LocationMapViewportState state) =>
      state.copyWith(followCar: true);

  /// Screen-space rotation for the car marker given a compass bearing
  /// (0 = north, clockwise).
  ///
  /// This is the bearing itself, NOT its inverse. It used to return
  /// `360 - bearing`, which pointed the marker the wrong way round the compass —
  /// a car heading east (90) drew as heading west. Reported from the car: "the
  /// car indicator seems to point to the back of the car".
  ///
  /// The inversion would be right for a maths-convention rotation, where positive
  /// angles go anticlockwise. Flutter's `Transform.rotate` is not that: it works in
  /// screen coordinates, where positive is CLOCKWISE — the same direction a compass
  /// bearing increases. So the marker art (`Icons.navigation`, which points up at
  /// rest) needs the raw bearing and nothing else.
  ///
  /// The web client had it right all along and is the ground truth here:
  /// `location.component.ts`'s `carIcon()` normalises the heading and applies it
  /// directly as `transform: rotate(<heading>deg)`, with the comment "points up at
  /// heading 0 and rotates clockwise with the GPS heading". CSS `rotate()` and
  /// `Transform.rotate` share the same sign convention, so the two clients must use
  /// the same value — and before this they did not.
  ///
  /// The old doc claimed to mirror a native `LocationMapBearingMapper.markerRotation`.
  /// That class was deleted with the rest of the native UI in the Flutter refactor,
  /// so nothing was checking the claim.
  static double markerRotation(double? bearingDegrees) {
    final bearing = bearingDegrees;
    if (bearing == null) return 0;
    return ((bearing % 360) + 360) % 360;
  }
}

/// Ground truth: `LocationModels.kt`'s `object LocationAppearanceResolver`.
/// [appThemeModePref] is the app-wide theme setting as
/// `PrefsChannel.getThemeMode()` returns it ('light'/'dark'/'system'/null);
/// native's equivalent (`PreferencesManager.getThemeMode()`) is the same
/// concept read through `PrefsChannel` instead, since the two APKs' prefs
/// are not directly shared (see `PrefsChannel`'s own doc comment).
/// [systemIsDark] is the OS platform brightness, read at the widget layer
/// (`MediaQuery`) since this file has no Flutter import.
abstract final class LocationAppearanceResolver {
  static bool useNightTiles({
    required LocationUiModePreference uiModePreference,
    required String? appThemeModePref,
    required bool systemIsDark,
  }) =>
      switch (uiModePreference) {
        LocationUiModePreference.dark => true,
        LocationUiModePreference.light => false,
        LocationUiModePreference.auto => switch (appThemeModePref) {
            'dark' => true,
            'light' => false,
            _ => systemIsDark,
          },
      };
}
