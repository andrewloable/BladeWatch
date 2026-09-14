import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'hero_asset_server.dart';
import 'hero_load_state.dart';
import 'vehicle_controller.dart';

/// The 3D vehicle hero. Ground truth: `VehicleHeroView.kt`. Loads the SAME
/// `hero.html` (copied byte-identical into `assets/web/hero/`, see
/// pubspec.yaml), served — with its `../shared/...`-relative vendor and model
/// files — over a loopback HTTP origin by [HeroAssetServer].
///
/// It deliberately does NOT use `loadFlutterAsset`. That yields a `file://`
/// origin, and WebView blocks the Fetch API on `file://`, so three.js could
/// never pull the `.glb`: the page rendered but the car never appeared. Native
/// hit the same wall and answered it with a synthetic https origin via
/// `shouldInterceptRequest`; `webview_flutter` has no such hook, hence the
/// loopback server. See hero_asset_server.dart.
///
/// `hero.html`'s own JS calls `AndroidHero.onReady()` /
/// `AndroidHero.onModelState(loaded)` directly as method calls (Android's
/// `@JavascriptInterface` convention) — NOT the `postMessage(string)` shape
/// `webview_flutter`'s `JavaScriptChannel` provides. Rather than modify
/// `hero.html` (kept byte-identical to native's on purpose, so it is
/// trivially re-diffable against the source of truth), a small JS shim is
/// injected on `onPageStarted` that defines a compatible `window.AndroidHero`
/// object forwarding to the `FlutterHero` channel. `hero.html` guards every
/// call with `if (window.AndroidHero && AndroidHero.onReady)`, so a late shim
/// does not throw — but it does mean the `ready` message may never arrive,
/// which is why readiness is driven by `onPageFinished` and the shim is only
/// an optimisation. (Measured on device: the shim does NOT reliably land
/// before the page's own scripts run, contrary to what this comment used to
/// claim.)
///
/// The load lifecycle it drives — spinner while the GLB streams in,
/// placeholder when it cannot — lives in [HeroLoadState] / [HeroOverlay]
/// (hero_load_state.dart) precisely BECAUSE of the exclusion described next:
/// branching logic left in this file could never be tested.
///
/// Kept in its own file, excluded from the Dart coverage gate
/// (`tools/check_flutter_coverage.sh`) by name — mirrors exactly how the
/// Kotlin Kover gate excludes `LocationServiceChannel*`/`HttpConnectionsKt`
/// (Android-framework-bound / a real I/O boundary with no branching logic of
/// its own). Constructing a real `WebViewController` throws
/// `WebViewPlatform.instance != null` in any plain `flutter test` run — no
/// platform implementation is registered outside a real app/device
/// (confirmed empirically) — so this class cannot be meaningfully unit- or
/// widget-tested at all, let alone to 100%. `VehicleScreen.heroBuilder`
/// exists so every OTHER widget in the Vehicle screen stays fully testable
/// despite this. Verified on-device in BladeWatch-imh6.
class VehicleHero extends StatefulWidget {
  final VehicleController controller;

  const VehicleHero({super.key, required this.controller});

  @override
  State<VehicleHero> createState() => _VehicleHeroState();
}

class _VehicleHeroState extends State<VehicleHero> {
  late final WebViewController _webViewController;

  /// BladeWatch-8xxr: the load lifecycle, so the hero shows a progress
  /// indicator while the GLB streams in and a placeholder when it cannot —
  /// as native does. It lives in its own file because THIS file is excluded
  /// from the coverage gate (a real WebViewController cannot be constructed in
  /// `flutter test`), so any branching left here would be untestable.
  late final HeroLoadState _loadState = HeroLoadState()..addListener(_onLoadStateChanged);

  void _onLoadStateChanged() {
    if (mounted) setState(() {});
  }

  /// False until `hero.html` has actually defined `window.Hero`.
  ///
  /// Nothing may be evaluated in the page before this. The controller pushes a
  /// telemetry update within ~400 ms of the screen mounting — far sooner than a
  /// 600 KB three.js bundle parses — so calling straight through produced
  /// "Uncaught ReferenceError: Hero is not defined" on device, and, worse, the
  /// model then never loaded at all: `_loadedModelFile` was assigned BEFORE the
  /// failing call, so the `file != _loadedModelFile` guard suppressed every
  /// later attempt. The hero stayed blank while `setColor` appeared to work.
  bool _pageReady = false;

  /// Set before the WebView is blanked in [dispose]. The blank navigation fires
  /// `onPageStarted` one more time, and by then `_loadState` has been disposed —
  /// notifying a disposed ChangeNotifier throws. See BladeWatch-w9vi.
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterHero', onMessageReceived: _onHeroMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (_disposed) return; // the about:blank teardown navigation
          // A reload invalidates whatever was in the old document.
          _pageReady = false;
          _loadState.onPageRestarted();
          _injectBridgeShim();
        },
        // The shim is injected on onPageStarted, but the page's own init() may
        // already have run by then, in which case its
        // `if (window.AndroidHero) AndroidHero.onReady()` guard silently skips
        // and the 'ready' message never arrives. onPageFinished is the
        // race-free signal that the document (and so `window.Hero`) exists, so
        // readiness never depends on the shim winning.
        onPageFinished: (_) => _disposed ? null : _markReady(),
      ));
    // NOT loadFlutterAsset: that serves a file:// origin, and WebView's Fetch
    // API refuses file:// URLs, so GLTFLoader could never pull the .glb (see
    // hero_asset_server.dart).
    unawaited(_loadHero());
    widget.controller.addListener(_onControllerChanged);
  }

  Future<void> _loadHero() async {
    try {
      final base = await HeroAssetServer.instance.start();
      if (!mounted) return;
      await _webViewController.loadRequest(base.replace(path: '/web/hero/hero.html'));
    } catch (_) {
      // The rest of the Vehicle screen is unaffected. Native's equivalent
      // branch ("no 3D engine available") shows the silhouette and explicitly
      // does NOT spin, because that spinner could never resolve.
      _loadState.markFailed();
    }
  }

  void _markReady() {
    if (_pageReady) return;
    _pageReady = true;
    unawaited(_applyHeroState());
  }

  @override
  void didUpdateWidget(covariant VehicleHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    // Before the page is ready there is nothing to call. The current selection
    // is not lost: _markReady() applies whatever the controller holds at that
    // point, which is the same state this call would have pushed.
    if (!_pageReady) return;
    unawaited(_applyHeroState());
  }

  Future<void> _applyHeroState() async {
    final file = widget.controller.selectedModelFile;
    if (_loadState.shouldLoad(file)) {
      // Only a REAL swap re-enters loading; re-applying the model already on
      // screen must not flash the indicator (native's willChangeModel guard).
      _loadState.beginLoad();
      _pendingModelFile = file;
      try {
        await _webViewController.runJavaScript("Hero.loadModel('${file.replaceAll("'", '')}')");
      } catch (_) {
        // The call never reached the page, so no onModelState will ever come.
        // Fail now rather than leaving the indicator to time out.
        _pendingModelFile = null;
        _loadState.markFailed();
      }
    }
    try {
      await _webViewController
          .runJavaScript("Hero.setColor('${widget.controller.selectedColor.replaceAll("'", '')}')");
    } catch (_) {
      // A dropped colour push is cosmetic and self-corrects on the next update.
    }
  }

  void _injectBridgeShim() {
    _webViewController.runJavaScript('''
      window.AndroidHero = {
        onReady: function() { FlutterHero.postMessage('ready'); },
        onModelState: function(loaded) { FlutterHero.postMessage('modelState:' + loaded); }
      };
    ''');
  }

  /// The model file whose `Hero.loadModel` call is in flight. Recorded as
  /// loaded only when the page confirms it, so a failure leaves it eligible for
  /// retry rather than latched as "already showing".
  String? _pendingModelFile;

  void _onHeroMessage(JavaScriptMessage message) {
    // Whichever of this and onPageFinished lands first wins; _markReady is
    // idempotent.
    if (message.message == 'ready') {
      _markReady();
      return;
    }
    // hero.html reports the GLB's fate through AndroidHero.onModelState, which
    // the injected shim forwards as 'modelState:<bool>'. This used to be
    // dropped on the floor, which is why there was no indicator at all.
    if (message.message.startsWith('modelState:')) {
      final loaded = message.message.endsWith('true');
      _loadState.onModelState(loaded, file: loaded ? _pendingModelFile : null);
      _pendingModelFile = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _loadState.removeListener(_onLoadStateChanged);
    // Order matters: flag first, so the blank navigation's own onPageStarted
    // cannot touch _loadState after it is disposed.
    _disposed = true;
    // BladeWatch-w9vi: measured on the head unit, leaving the Vehicle screen left
    // roughly 24 MB of graphics memory allocated — `Graphics` in
    // `dumpsys meminfo net.bladewatch.flutter` stayed at ~40 MB instead of falling
    // back to Live View's ~16 MB, and stayed there for minutes. Removing the widget
    // is supposed to tear the platform WebView down, but on this Adreno 610 driver
    // the three.js WebGL context outlived it after repeated navigation.
    //
    // Loading about:blank destroys the document, which releases that context
    // deterministically instead of depending on platform-view teardown timing.
    // Fire-and-forget: dispose cannot await, and this is best-effort cleanup.
    unawaited(_releaseWebView());
    _loadState.dispose();
    super.dispose();
  }

  /// Best-effort teardown of the hero page's GPU resources — see [dispose].
  Future<void> _releaseWebView() async {
    try {
      await _webViewController.loadRequest(Uri.parse('about:blank'));
    } catch (_) {
      // The platform view may already be gone; nothing left to release.
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // The overlay is drawn OVER the WebView, never instead of it, so the
          // page is not torn down and rebuilt on every model swap.
          WebViewWidget(controller: _webViewController),
          HeroOverlay(phase: _loadState.phase),
        ],
      );
}
