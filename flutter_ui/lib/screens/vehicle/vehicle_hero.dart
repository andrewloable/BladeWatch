import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'vehicle_controller.dart';

/// The 3D vehicle hero. Ground truth: `VehicleHeroView.kt`. Loads the SAME
/// `hero.html` (copied byte-identical into `assets/web/hero/`, see
/// pubspec.yaml) via `webview_flutter`'s `loadFlutterAsset`, which serves it
/// and its `../shared/...`-relative vendor/model files from Flutter's own
/// asset bundle at matching relative paths — no server, no native asset
/// sharing (Flutter is a separate APK/process).
///
/// `hero.html`'s own JS calls `AndroidHero.onReady()` /
/// `AndroidHero.onModelState(loaded)` directly as method calls (Android's
/// `@JavascriptInterface` convention) — NOT the `postMessage(string)` shape
/// `webview_flutter`'s `JavaScriptChannel` provides. Rather than modify
/// `hero.html` (kept byte-identical to native's on purpose, so it is
/// trivially re-diffable against the source of truth), a small JS shim is
/// injected on `onPageStarted` — well before the page's own script tags run
/// — that defines a compatible `window.AndroidHero` object forwarding to the
/// `FlutterHero` channel. `hero.html` itself guards every call with
/// `if (window.AndroidHero && AndroidHero.onReady)`, so even a missed/late
/// shim degrades gracefully (the 3D scene still renders; only the
/// ready/loaded callbacks are skipped) rather than throwing.
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
  String? _loadedModelFile;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterHero', onMessageReceived: _onHeroMessage)
      ..setNavigationDelegate(NavigationDelegate(onPageStarted: (_) => _injectBridgeShim()))
      ..loadFlutterAsset('assets/web/hero/hero.html');
    widget.controller.addListener(_onControllerChanged);
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
    final file = widget.controller.selectedModelFile;
    if (file != _loadedModelFile) {
      _loadedModelFile = file;
      _webViewController.runJavaScript("Hero.loadModel('${file.replaceAll("'", '')}')");
    }
    _webViewController.runJavaScript("Hero.setColor('${widget.controller.selectedColor.replaceAll("'", '')}')");
  }

  void _injectBridgeShim() {
    _webViewController.runJavaScript('''
      window.AndroidHero = {
        onReady: function() { FlutterHero.postMessage('ready'); },
        onModelState: function(loaded) { FlutterHero.postMessage('modelState:' + loaded); }
      };
    ''');
  }

  void _onHeroMessage(JavaScriptMessage message) {
    if (message.message == 'ready') {
      _onControllerChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _webViewController);
}
