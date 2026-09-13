import 'package:flutter/foundation.dart';

import '../../platform/location_channel.dart';
import '../../platform/network_channel.dart';
import '../../platform/prefs_channel.dart';
import 'location_models.dart';

int _defaultNowMs() => DateTime.now().millisecondsSinceEpoch;

/// A diagnostic marker (not display text — see the class doc) for why a
/// [LocationTileFailure] was produced. This port only ever produces one
/// cause, matching native's single call site
/// (`LocationMapController.render()`'s `"Network unavailable"` literal).
const tileFailureReasonNetworkUnavailable = 'networkUnavailable';

/// Ground truth: `LocationGpsController.kt` + `LocationMapController.kt`'s
/// viewport/appearance bookkeeping + `LocationSettingsStore.kt`. Pure Dart —
/// all the state-machine and provider-precedence logic native splits across
/// `LocationGpsController`/`LocationFragment` lives here so it is fully
/// covered by controller tests; `platform/location_channel.dart` only
/// carries raw `LocationManager` primitives across the platform boundary.
///
/// Unlike native (push-based: `LocationListener` callbacks fire whenever the
/// OS has something new), this controller is polled by [LocationScreen] on a
/// ~1s timer — matching native's `requestLocationUpdates(provider, 1_000L,
/// 0f, ...)` minTime, and folding native's separate stale-check `Handler`
/// timer into the same tick (see [poll]).
///
/// [state] mirrors `LocationGpsController.currentState` — the raw GPS state
/// machine. [effectiveState] mirrors what `LocationMapController.render()`
/// actually displays: the same state, downgraded to [LocationTileFailure]
/// when offline while [LocationFresh]/[LocationStale] — a render-time
/// transform in native, never stored back into its controller's own state,
/// reproduced here as a separate getter for the same reason.
class LocationController extends ChangeNotifier {
  LocationController({
    required LocationChannel channel,
    required PrefsChannel prefs,
    required NetworkChannel networkChannel,
    int Function() nowMs = _defaultNowMs,
  })  : _channel = channel, // ignore: prefer_initializing_formals
        _prefs = prefs, // ignore: prefer_initializing_formals
        _networkChannel = networkChannel, // ignore: prefer_initializing_formals
        _nowMs = nowMs; // ignore: prefer_initializing_formals

  final LocationChannel _channel;
  final PrefsChannel _prefs;
  final NetworkChannel _networkChannel;
  final int Function() _nowMs;

  LocationUiState _state = const LocationLoading();
  LocationUiState get state => _state;

  LocationUiState get effectiveState {
    final s = _state;
    if (!_networkAvailable && (s is LocationFresh || s is LocationStale)) {
      return LocationStateReducer.tileFailure(s, tileFailureReasonNetworkUnavailable);
    }
    return s;
  }

  LocationMapViewportState _viewportState = const LocationMapViewportState();
  LocationMapViewportState get viewportState => _viewportState;

  LocationUiModePreference _uiModePreference = LocationUiModePreference.auto;
  LocationUiModePreference get uiModePreference => _uiModePreference;

  bool _permissionPrompted = false;
  bool _listening = false;
  String? _activeProvider;
  int? _lastAppliedTimestampMs;
  bool _networkAvailable = true;

  Future<void> loadUiModePreference() async {
    try {
      _uiModePreference = LocationUiModePreference.fromStoredValue(await _prefs.getLocationUiMode());
    } catch (_) {
      _uiModePreference = LocationUiModePreference.auto;
    }
    notifyListeners();
  }

  Future<void> setUiModePreference(LocationUiModePreference preference) async {
    _uiModePreference = preference;
    notifyListeners();
    await _prefs.setLocationUiMode(preference.storedValue);
  }

  /// Mirrors `LocationAppearanceResolver.resolve()`. [systemIsDark] is read
  /// at the widget layer (`MediaQuery`) and passed in since this controller
  /// has no Flutter import.
  Future<bool> useNightTiles({required bool systemIsDark}) async {
    String? appThemeModePref;
    try {
      appThemeModePref = await _prefs.getThemeMode();
    } catch (_) {
      appThemeModePref = null;
    }
    return LocationAppearanceResolver.useNightTiles(
      uiModePreference: _uiModePreference,
      appThemeModePref: appThemeModePref,
      systemIsDark: systemIsDark,
    );
  }

  /// Mirrors `LocationGpsController.start()`: checks permission, picks a
  /// provider (gps preferred, else network), and begins listening.
  Future<void> start() async {
    try {
      final granted = await _channel.hasPermission();
      if (!granted) {
        _listening = false;
        _state = LocationStateReducer.permissionState(_permissionPrompted);
        notifyListeners();
        return;
      }

      final availability = await _channel.providerEnabled();
      final provider = availability.gps ? 'gps' : (availability.network ? 'network' : null);
      if (provider == null) {
        _listening = false;
        _activeProvider = null;
        _state = LocationStateReducer.providerUnavailable();
        notifyListeners();
        return;
      }

      _activeProvider = provider;
      _state = LocationStateReducer.waitingForFix(_state, _nowMs());
      notifyListeners();

      final result = await _channel.startUpdates(provider);
      if (!result.ok) {
        _listening = false;
        _state = LocationError(location: locationOf(_state), reason: result.reason);
        notifyListeners();
        return;
      }
      _listening = true;
      _lastAppliedTimestampMs = null;
    } catch (e) {
      // Same defensive posture as every other channel-backed controller in
      // this port (e.g. DiagnosticsController's per-tile try/catch): the
      // platform channel can throw (no handler registered, IPC failure) in
      // ways native's in-process LocationManager calls never could.
      _listening = false;
      _state = LocationError(location: locationOf(_state), reason: e.toString());
      notifyListeners();
    }
  }

  /// Mirrors `LocationGpsController.stop()`.
  Future<void> stop() async {
    _listening = false;
    _activeProvider = null;
    await _channel.stopUpdates();
  }

  /// Mirrors `LocationFragment.requestLocationPermission()` +
  /// `LocationGpsController.onPermissionResult()`, collapsed into one async
  /// call since Dart's `await` already sequences "prompt, then react to the
  /// result" without needing a separate callback registration.
  Future<void> requestPermission() async {
    _permissionPrompted = true;
    final granted = await _channel.requestPermission();
    if (granted) {
      _permissionPrompted = false;
      await start();
    } else {
      _state = const LocationPermissionDenied();
      notifyListeners();
    }
  }

  /// The single banner action handler — mirrors `LocationFragment`'s one
  /// `setBannerActionHandler`: "Grant" when permission is missing, "Retry"
  /// (a full stop+start) for every other actionable state.
  Future<void> onBannerAction() async {
    if (_state is LocationPermissionMissing) {
      await requestPermission();
    } else {
      await stop();
      await start();
    }
  }

  /// Mirrors `LocationMapController.onUserPan()` (driven by the screen's map
  /// widget on a genuine user drag/zoom gesture, not a programmatic move).
  void onUserPan() {
    _viewportState = LocationMapReducer.onUserPan(_viewportState);
    notifyListeners();
  }

  /// Mirrors `LocationMapController.recenterOnCar()`'s viewport half — the
  /// screen does the actual map-camera animation.
  void onRecenterRequested() {
    _viewportState = LocationMapReducer.onFollowRequested(_viewportState);
    notifyListeners();
  }

  /// Called by [LocationScreen] on a ~1s timer. Folds together everything
  /// native drives from `LocationListener` callbacks
  /// (`onLocationChanged`/`onProviderEnabled`/`onProviderDisabled`) plus its
  /// periodic stale-check `Handler` — see the class doc for why polling
  /// stands in for native's push model here.
  Future<void> poll() async {
    try {
      final network = await _networkChannel.currentNetwork();
      _networkAvailable = network.type != NetworkType.offline;

      if (!_listening) {
        _state = LocationStateReducer.refreshStaleness(_state, _nowMs());
        notifyListeners();
        return;
      }

      final availability = await _channel.providerEnabled();
      final stillEnabled = _activeProvider == 'gps' ? availability.gps : availability.network;

      if (!stillEnabled) {
        _state = const LocationProviderDisabled();
        notifyListeners();
        return;
      }

      if (_state is LocationProviderDisabled) {
        // The provider came back -- mirrors onProviderEnabled()'s stop()+start().
        await stop();
        await start();
        return;
      }

      final raw = await _channel.currentSample();
      if (raw != null && raw.timestampMs != _lastAppliedTimestampMs) {
        _lastAppliedTimestampMs = raw.timestampMs;
        final sample = LocationCarGps(
          latitude: raw.latitude,
          longitude: raw.longitude,
          bearingDegrees: raw.bearingDegrees,
          speedMetersPerSecond: raw.speedMetersPerSecond,
          accuracyMeters: raw.accuracyMeters,
          altitudeMeters: raw.altitudeMeters,
          provider: raw.provider,
          timestampMs: raw.timestampMs,
        );
        _state = LocationStateReducer.onLocationSample(_state, sample);
        final current = _state;
        if (current is LocationFresh) {
          final update = LocationMapReducer.onValidLocation(_viewportState, current.location);
          _viewportState = update.viewportState;
        }
      }
      _state = LocationStateReducer.refreshStaleness(_state, _nowMs());
      notifyListeners();
    } catch (_) {
      // A single poll tick failing (channel hiccup, no handler registered)
      // is not worth flipping the whole screen to an error state over --
      // same reasoning as start()'s catch, but here it is safe to just
      // leave the current state as-is and let the next tick, one second
      // away, try again.
    }
  }
}
