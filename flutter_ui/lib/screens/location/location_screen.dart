import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../widgets/osm_tile_layer.dart';
import 'package:latlong2/latlong.dart';

import '../../gen/l10n/app_localizations.dart';
import 'location_controller.dart';
import 'location_models.dart';

/// Ground truth: `LocationFragment.kt` + `LocationMapController.kt`. Owns the
/// ~1s poll timer (matching `LocationGpsController`'s
/// `requestLocationUpdates(provider, 1_000L, ...)` minTime — see
/// [LocationController]'s class doc for why polling stands in for native's
/// push model) and the `flutter_map` `MapController`, since neither belongs
/// in the pure-Dart controller.
///
/// The map itself always stays mounted (`Visibility(maintainState: true)`)
/// even while a banner is covering it, so pan/zoom survive a
/// hide-then-reshow cycle — matching native's `mapView.visibility =
/// View.GONE` (the `MapView` instance is hidden, never destroyed).
class LocationScreen extends StatefulWidget {
  final LocationController controller;

  const LocationScreen({super.key, required this.controller});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Timer? _timer;
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _useNightTiles = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    unawaited(_start());
  }

  Future<void> _start() async {
    await widget.controller.loadUiModePreference();
    await _refreshAppearance();
    await widget.controller.start();
    await widget.controller.poll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => widget.controller.poll());
  }

  Future<void> _refreshAppearance() async {
    final systemIsDark = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final value = await widget.controller.useNightTiles(systemIsDark: systemIsDark);
    if (mounted) setState(() => _useNightTiles = value);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeCenterMap();
  }

  void _maybeCenterMap() {
    if (!_mapReady) return;
    final loc = locationOf(widget.controller.effectiveState);
    if (loc != null && widget.controller.viewportState.followCar) {
      _mapController.move(LatLng(loc.latitude, loc.longitude), _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChanged);
    unawaited(widget.controller.stop());
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;
    final state = c.effectiveState;
    final loc = locationOf(state);
    final banner = _bannerFor(l10n, state);

    return Stack(
      children: [
        Visibility(
          visible: banner.showMap,
          maintainState: true,
          child: _buildMap(loc),
        ),
        if (!banner.showMap) ColoredBox(color: theme.colorScheme.surface),
        _buildBanner(theme, banner),
        if (banner.showMap)
          Positioned(right: 24, top: 24, child: _buildModeSelector(l10n, c)),
        if (banner.showMap && !c.viewportState.followCar && c.viewportState.lastLocation != null)
          Positioned(right: 24, bottom: 24, child: _buildRecenterButton(l10n)),
      ],
    );
  }

  Widget _buildMap(LocationCarGps? loc) {
    return FlutterMap(
      key: const ValueKey('location.map'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: loc != null ? LatLng(loc.latitude, loc.longitude) : const LatLng(0, 0),
        initialZoom: 17.5,
        onMapReady: () => _mapReady = true,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) widget.controller.onUserPan();
        },
      ),
      children: [
        bwTileLayerFor(night: _useNightTiles),
        if (loc != null)
          MarkerLayer(markers: [
            Marker(
              point: LatLng(loc.latitude, loc.longitude),
              width: 44,
              height: 44,
              child: Transform.rotate(
                angle: LocationMapReducer.markerRotation(loc.bearingDegrees) * math.pi / 180,
                child: const _CarMarker(),
              ),
            ),
          ]),
        // SimpleAttributionWidget prepends its own "©", so the source text must NOT
        // repeat it — on device this rendered as "© © OpenStreetMap contributors"
        // (BladeWatch-imh6.2).
        const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }

  Widget _buildBanner(ThemeData theme, _BannerInfo banner) {
    return Align(
      key: const ValueKey('location.banner'),
      alignment: banner.showMap ? Alignment.topLeft : Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(banner.compact ? 18.0 : 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFD0D0D0)),
                  ),
                ],
                if (banner.actionLabel != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('location.bannerAction'),
                    onPressed: () => widget.controller.onBannerAction(),
                    child: Text(banner.actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(AppLocalizations l10n, LocationController c) {
    return SegmentedButton<LocationUiModePreference>(
            showSelectedIcon: false,
      key: const ValueKey('location.modeSelector'),
      segments: [
        ButtonSegment(value: LocationUiModePreference.auto, label: Text(l10n.location_mode_auto)),
        ButtonSegment(value: LocationUiModePreference.light, label: Text(l10n.location_mode_light)),
        ButtonSegment(value: LocationUiModePreference.dark, label: Text(l10n.location_mode_dark)),
      ],
      selected: {c.uiModePreference},
      onSelectionChanged: (selection) async {
        await c.setUiModePreference(selection.first);
        await _refreshAppearance();
      },
    );
  }

  Widget _buildRecenterButton(AppLocalizations l10n) {
    return FloatingActionButton.small(
      key: const ValueKey('location.recenter'),
      heroTag: 'location_recenter',
      tooltip: l10n.cd_recenter_on_car,
      onPressed: () {
        widget.controller.onRecenterRequested();
        _maybeCenterMap();
      },
      child: const Icon(Icons.my_location),
    );
  }
}

class _BannerInfo {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final bool showMap;
  final bool compact;

  const _BannerInfo({
    required this.title,
    this.subtitle,
    this.actionLabel,
    required this.showMap,
    required this.compact,
  });
}

/// Mirrors `LocationUiStateMapper.panelModel()` — kept at the screen layer
/// (not `location_models.dart`) since it resolves ARB text, and this port's
/// pure-Dart models must not import localized strings.
_BannerInfo _bannerFor(AppLocalizations l10n, LocationUiState state) => switch (state) {
      LocationLoading() => _BannerInfo(title: l10n.location_loading_title, showMap: false, compact: false),
      LocationPermissionMissing() => _BannerInfo(
          title: l10n.location_permission_missing_title,
          actionLabel: l10n.location_action_grant,
          showMap: false,
          compact: false,
        ),
      LocationPermissionDenied() => _BannerInfo(
          title: l10n.location_permission_denied_title,
          actionLabel: l10n.location_action_retry,
          showMap: false,
          compact: false,
        ),
      LocationProviderDisabled() => _BannerInfo(
          title: l10n.location_provider_disabled_title,
          actionLabel: l10n.location_action_retry,
          showMap: false,
          compact: false,
        ),
      LocationWaitingForFix() =>
        _BannerInfo(title: l10n.location_waiting_for_fix_title, showMap: false, compact: false),
      LocationFresh(:final location) => _BannerInfo(
          title: l10n.location_car_location_title,
          subtitle: _formatLatLng(location),
          showMap: true,
          compact: true,
        ),
      LocationStale(:final location) => _BannerInfo(
          title: l10n.location_stale_title,
          subtitle: _formatLatLng(location),
          showMap: true,
          compact: true,
        ),
      LocationTileFailure(:final location) => _BannerInfo(
          title: l10n.location_tile_failure_title,
          subtitle: l10n.location_tile_failure_subtitle,
          actionLabel: l10n.location_action_retry,
          showMap: location != null,
          compact: location != null,
        ),
      // reason is shown verbatim, not wrapped in an ARB template -- same
      // reasoning as TripsController's SyncOutcome.error: it is raw
      // diagnostic text from the platform channel (an exception message),
      // not English prose this port composed, so passing it through as-is
      // (with no fallback, matching native's `subtitle = state.reason`)
      // does not violate the no-hardcoded-strings rule.
      LocationError(:final location, :final reason) => _BannerInfo(
          title: l10n.location_error_title,
          subtitle: reason,
          actionLabel: l10n.location_action_retry,
          showMap: location != null,
          compact: location != null,
        ),
    };

String _formatLatLng(LocationCarGps location) =>
    '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';

class _CarMarker extends StatelessWidget {
  const _CarMarker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 22),
    );
  }
}
