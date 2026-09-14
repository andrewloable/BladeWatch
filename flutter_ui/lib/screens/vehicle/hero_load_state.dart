import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';

/// What the 3D hero is currently doing. Ground truth: `TyreOverlay.kt`'s
/// three-layer stack — WebView, silhouette placeholder, spinner — driven by
/// `hero.onModelState = { loaded -> … }` (TyreOverlay.kt:86-90).
enum HeroPhase {
  /// The GLB is streaming in or decoding. Native shows an indeterminate
  /// ProgressBar here and keeps the WebView `INVISIBLE`.
  loading,

  /// A car is on screen.
  loaded,

  /// No 3D engine, or the model failed to load. Native falls back to the 2D
  /// silhouette and explicitly does NOT spin — a spinner that will never
  /// resolve is worse than none (TyreOverlay.kt:96-101).
  failed,
}

/// The hero's load lifecycle, extracted from [VehicleHero] so it can be tested.
///
/// It lives here and not in `vehicle_hero.dart` for a hard reason: that file is
/// excluded from the Dart coverage gate by name, because constructing a real
/// `WebViewController` throws `WebViewPlatform.instance != null` in any plain
/// `flutter test` run. Anything with branching logic that ends up in there is
/// untestable by construction, so the branching lives here and that file stays
/// the thin platform-bound shell.
class HeroLoadState extends ChangeNotifier {
  /// How long a load may sit in [HeroPhase.loading] before it is treated as
  /// failed.
  ///
  /// Native has no equivalent because its spinner is only ever cleared by
  /// `onModelState`, which means a GLB that never resolves spins forever. This
  /// port would inherit that: `hero.html` reports success and failure, but says
  /// nothing at all if its `<script>` never ran (a blocked fetch, a 404 on the
  /// vendor bundle), and the page-level `onPageFinished` cannot tell the
  /// difference. The timeout converts "we will never hear back" into the
  /// placeholder rather than a permanent spinner.
  static const Duration defaultTimeout = Duration(seconds: 20);

  HeroLoadState({Duration timeout = defaultTimeout})
      : _timeout = timeout; // ignore: prefer_initializing_formals

  final Duration _timeout;
  Timer? _timer;

  HeroPhase _phase = HeroPhase.loading;
  HeroPhase get phase => _phase;

  /// The model file currently ON SCREEN, recorded only once its load has been
  /// confirmed — never merely requested.
  String? _loadedFile;
  String? get loadedFile => _loadedFile;

  /// True when [file] is not what is already showing, i.e. a real swap.
  ///
  /// Re-selecting the car already displayed must not flash the spinner, which
  /// is exactly what native's `willChangeModel` guard buys
  /// (TyreOverlay.heroLoadModel).
  bool shouldLoad(String file) => file != _loadedFile;

  /// A real model swap has begun.
  void beginLoad() => _enterLoading();

  /// The page said the model is up ([loaded] true) or failed ([loaded] false) —
  /// `hero.html`'s `AndroidHero.onModelState(…)`.
  void onModelState(bool loaded, {String? file}) {
    if (loaded && file != null) _loadedFile = file;
    if (!loaded) _loadedFile = null;
    _set(loaded ? HeroPhase.loaded : HeroPhase.failed);
  }

  /// The hero could not be brought up at all — the asset server never started,
  /// or the page never loaded. Native's "no 3D engine available" branch.
  void markFailed() {
    _loadedFile = null;
    _set(HeroPhase.failed);
  }

  /// The document was replaced, so nothing known about the old one still holds.
  void onPageRestarted() {
    _loadedFile = null;
    _enterLoading();
  }

  void _enterLoading() {
    _set(HeroPhase.loading);
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      if (_phase == HeroPhase.loading) markFailed();
    });
  }

  void _set(HeroPhase next) {
    if (next != HeroPhase.loading) _timer?.cancel();
    if (_phase == next) return;
    _phase = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// What sits on top of the hero's WebView while it is not showing a car.
///
/// Mirrors native's layering: the spinner and the placeholder are drawn OVER
/// the WebView rather than replacing it, so the page keeps rendering
/// underneath and there is no teardown/rebuild on every model swap.
class HeroOverlay extends StatelessWidget {
  final HeroPhase phase;

  const HeroOverlay({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (phase) {
      case HeroPhase.loaded:
        return const SizedBox.shrink();
      case HeroPhase.loading:
        return Center(
          key: const ValueKey('hero.loading'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 3),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.webview_loading,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      case HeroPhase.failed:
        // Native shows a 2D car silhouette drawable here. That asset is
        // app/src/main/res/drawable/vehicle_hero_placeholder, which belongs to
        // the OTHER APK and must not be modified or copied, so this is the
        // icon equivalent — same intent: something car-shaped, and no spinner.
        return Center(
          key: const ValueKey('hero.placeholder'),
          child: Icon(
            Icons.directions_car_outlined,
            size: 96,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
          ),
        );
    }
  }
}
