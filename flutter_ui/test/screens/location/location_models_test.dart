import 'package:bladewatch_ui/screens/location/location_models.dart';
import 'package:flutter_test/flutter_test.dart';

LocationCarGps _sample({
  double lat = 37.7749,
  double lng = -122.4194,
  int timestampMs = 1000,
  double? bearingDegrees,
}) =>
    LocationCarGps(
      latitude: lat,
      longitude: lng,
      bearingDegrees: bearingDegrees,
      provider: 'gps',
      timestampMs: timestampMs,
    );

void main() {
  group('LocationCarGps.isUsable', () {
    test('true for a normal fix', () {
      expect(_sample().isUsable, isTrue);
    });

    test('false when latitude is out of range', () {
      expect(_sample(lat: 90.1).isUsable, isFalse);
      expect(_sample(lat: -90.1).isUsable, isFalse);
    });

    test('false when longitude is out of range', () {
      expect(_sample(lng: 180.1).isUsable, isFalse);
      expect(_sample(lng: -180.1).isUsable, isFalse);
    });

    test('false at exactly (0, 0) — the classic "no fix yet" sentinel', () {
      expect(_sample(lat: 0, lng: 0).isUsable, isFalse);
    });

    test('true at the boundary values', () {
      expect(_sample(lat: 90, lng: 180).isUsable, isTrue);
      expect(_sample(lat: -90, lng: -180).isUsable, isTrue);
    });
  });

  group('LocationUiModePreference.fromStoredValue', () {
    test('maps each stored value back to its enum', () {
      expect(LocationUiModePreference.fromStoredValue('auto'), LocationUiModePreference.auto);
      expect(LocationUiModePreference.fromStoredValue('light'), LocationUiModePreference.light);
      expect(LocationUiModePreference.fromStoredValue('dark'), LocationUiModePreference.dark);
    });

    test('defaults to auto for null or an unrecognized value', () {
      expect(LocationUiModePreference.fromStoredValue(null), LocationUiModePreference.auto);
      expect(LocationUiModePreference.fromStoredValue('bogus'), LocationUiModePreference.auto);
    });
  });

  group('locationOf', () {
    test('returns the carried location for Fresh/Stale/TileFailure/Error', () {
      final sample = _sample();
      expect(locationOf(LocationFresh(sample)), sample);
      expect(locationOf(LocationStale(sample)), sample);
      expect(locationOf(LocationTileFailure(location: sample)), sample);
      expect(locationOf(LocationError(location: sample)), sample);
    });

    test('returns null for TileFailure/Error with no location and every locationless state', () {
      expect(locationOf(const LocationTileFailure()), isNull);
      expect(locationOf(const LocationError()), isNull);
      expect(locationOf(const LocationLoading()), isNull);
      expect(locationOf(const LocationPermissionMissing()), isNull);
      expect(locationOf(const LocationPermissionDenied()), isNull);
      expect(locationOf(const LocationProviderDisabled()), isNull);
      expect(locationOf(const LocationWaitingForFix()), isNull);
    });
  });

  group('LocationStateReducer.permissionState', () {
    test('prompted -> PermissionDenied, not-yet-prompted -> PermissionMissing', () {
      expect(LocationStateReducer.permissionState(true), isA<LocationPermissionDenied>());
      expect(LocationStateReducer.permissionState(false), isA<LocationPermissionMissing>());
    });
  });

  test('LocationStateReducer.providerUnavailable returns ProviderDisabled', () {
    expect(LocationStateReducer.providerUnavailable(), isA<LocationProviderDisabled>());
  });

  group('LocationStateReducer.waitingForFix', () {
    test('no prior location -> WaitingForFix', () {
      expect(LocationStateReducer.waitingForFix(const LocationLoading(), 1000), isA<LocationWaitingForFix>());
    });

    test('carries a prior fresh-enough location forward as Fresh', () {
      final sample = _sample(timestampMs: 1000);
      final result = LocationStateReducer.waitingForFix(LocationStale(sample), 1500);
      expect(result, isA<LocationFresh>());
      expect((result as LocationFresh).location, sample);
    });

    test('carries a prior stale location forward as Stale', () {
      final sample = _sample(timestampMs: 0);
      final result = LocationStateReducer.waitingForFix(LocationFresh(sample), 40000);
      expect(result, isA<LocationStale>());
    });
  });

  group('LocationStateReducer.onLocationSample', () {
    test('an unusable sample leaves the current state unchanged', () {
      const current = LocationWaitingForFix();
      final unusable = _sample(lat: 0, lng: 0);
      expect(LocationStateReducer.onLocationSample(current, unusable), same(current));
    });

    test('a usable sample becomes Fresh', () {
      final sample = _sample();
      final result = LocationStateReducer.onLocationSample(const LocationWaitingForFix(), sample);
      expect(result, isA<LocationFresh>());
      expect((result as LocationFresh).location, sample);
    });
  });

  group('LocationStateReducer.refreshStaleness', () {
    test('Fresh under the threshold stays Fresh (same instance)', () {
      final fresh = LocationFresh(_sample(timestampMs: 1000));
      expect(LocationStateReducer.refreshStaleness(fresh, 1000 + LocationStateReducer.staleThresholdMs - 1), same(fresh));
    });

    test('Fresh at/over the threshold becomes Stale', () {
      final sample = _sample(timestampMs: 1000);
      final result = LocationStateReducer.refreshStaleness(LocationFresh(sample), 1000 + LocationStateReducer.staleThresholdMs);
      expect(result, isA<LocationStale>());
      expect((result as LocationStale).location, sample);
    });

    test('Stale stays Stale (same instance)', () {
      final stale = LocationStale(_sample());
      expect(LocationStateReducer.refreshStaleness(stale, 999999), same(stale));
    });

    test('every other state passes through unchanged', () {
      const current = LocationProviderDisabled();
      expect(LocationStateReducer.refreshStaleness(current, 0), same(current));
    });
  });

  group('LocationStateReducer.tileFailure', () {
    test('Fresh becomes TileFailure carrying its location and the reason', () {
      final sample = _sample();
      final result = LocationStateReducer.tileFailure(LocationFresh(sample), 'no network');
      expect(result, isA<LocationTileFailure>());
      expect((result as LocationTileFailure).location, sample);
      expect(result.reason, 'no network');
    });

    test('Stale becomes TileFailure carrying its location and the reason', () {
      final sample = _sample();
      final result = LocationStateReducer.tileFailure(LocationStale(sample), 'no network');
      expect((result as LocationTileFailure).location, sample);
    });

    test('an existing TileFailure just gets its reason updated', () {
      final sample = _sample();
      final result = LocationStateReducer.tileFailure(LocationTileFailure(location: sample, reason: 'old'), 'new');
      expect((result as LocationTileFailure).location, sample);
      expect(result.reason, 'new');
    });

    test('every other state passes through unchanged', () {
      const current = LocationWaitingForFix();
      expect(LocationStateReducer.tileFailure(current, 'x'), same(current));
    });
  });

  group('LocationMapReducer.onUserPan', () {
    test('clears followCar', () {
      const state = LocationMapViewportState(followCar: true);
      expect(LocationMapReducer.onUserPan(state).followCar, isFalse);
    });
  });

  group('LocationMapReducer.onValidLocation', () {
    test('the first location sets an explicit zoom level and marks firstLocationSeen', () {
      final sample = _sample();
      const state = LocationMapViewportState();
      final update = LocationMapReducer.onValidLocation(state, sample);
      expect(update.zoomLevel, 17.5);
      expect(update.viewportState.firstLocationSeen, isTrue);
      expect(update.viewportState.lastLocation, sample);
    });

    test('subsequent locations do not force a zoom level', () {
      final sample = _sample();
      const state = LocationMapViewportState(firstLocationSeen: true);
      final update = LocationMapReducer.onValidLocation(state, sample);
      expect(update.zoomLevel, isNull);
    });

    test('centerMap mirrors the current followCar flag', () {
      final sample = _sample();
      expect(LocationMapReducer.onValidLocation(const LocationMapViewportState(followCar: true), sample).centerMap, isTrue);
      expect(LocationMapReducer.onValidLocation(const LocationMapViewportState(followCar: false), sample).centerMap, isFalse);
    });
  });

  test('LocationMapReducer.onFollowRequested sets followCar', () {
    const state = LocationMapViewportState(followCar: false);
    expect(LocationMapReducer.onFollowRequested(state).followCar, isTrue);
  });

  group('LocationMapReducer.markerRotation', () {
    test('null bearing renders as 0', () {
      expect(LocationMapReducer.markerRotation(null), 0);
    });

    test('0 degrees stays 0', () {
      expect(LocationMapReducer.markerRotation(0), 0);
    });

    // Was previously asserted as an INVERSION (90 -> 270), which is what made the
    // marker point backwards on the car. Transform.rotate is clockwise-positive,
    // exactly like a compass bearing, so the rotation IS the bearing. The web
    // client's carIcon() has always applied it this way.
    test('applies the bearing directly (compass degrees == screen rotation)', () {
      expect(LocationMapReducer.markerRotation(90), 90);
      expect(LocationMapReducer.markerRotation(270), 270);
    });

    test('matches the web client for the cardinal directions', () {
      expect(LocationMapReducer.markerRotation(180), 180);
      expect(LocationMapReducer.markerRotation(45), 45);
    });

    test('wraps values outside 0-360', () {
      expect(LocationMapReducer.markerRotation(450), 90);
      expect(LocationMapReducer.markerRotation(360), 0);
      expect(LocationMapReducer.markerRotation(-90), 270);
    });
  });

  group('LocationAppearanceResolver.useNightTiles', () {
    test('an explicit dark screen preference always wins', () {
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.dark,
          appThemeModePref: 'light',
          systemIsDark: false,
        ),
        isTrue,
      );
    });

    test('an explicit light screen preference always wins', () {
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.light,
          appThemeModePref: 'dark',
          systemIsDark: true,
        ),
        isFalse,
      );
    });

    test('auto defers to the app-wide theme preference when it is explicit', () {
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.auto,
          appThemeModePref: 'dark',
          systemIsDark: false,
        ),
        isTrue,
      );
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.auto,
          appThemeModePref: 'light',
          systemIsDark: true,
        ),
        isFalse,
      );
    });

    test('auto falls back to system brightness when the app-wide pref is system/unset', () {
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.auto,
          appThemeModePref: 'system',
          systemIsDark: true,
        ),
        isTrue,
      );
      expect(
        LocationAppearanceResolver.useNightTiles(
          uiModePreference: LocationUiModePreference.auto,
          appThemeModePref: null,
          systemIsDark: false,
        ),
        isFalse,
      );
    });
  });
}
