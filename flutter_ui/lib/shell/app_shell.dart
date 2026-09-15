import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gen/l10n/app_localizations.dart';
import 'nav_rail.dart';
import 'rail_destination.dart';
import 'route_stubs.dart';
import 'shell_controller.dart';

/// The Flutter counterpart of `activity_main_new.xml` /
/// `layout-land/activity_main_new.xml`: navigation rail + toolbar (with the
/// accent stripe and status pill) + content stage. Ported from BOTH Android
/// layout variants rather than just the portrait default — they differ in
/// more than orientation: landscape puts the language picker at the top of
/// the rail (`layout-land/rail_header.xml`) and uses a compact 48dp toolbar
/// with `TitleMedium`; portrait puts the language picker in the toolbar
/// end-cluster and uses the default `?attr/actionBarSize` toolbar with
/// `TitleLarge`. This widget picks between them by `MediaQuery` orientation,
/// same signal Android's `-land` resource qualifier reacts to.
class AppShell extends StatelessWidget {
  final ShellController controller;
  final VoidCallback onLanguageTap;

  /// The real Dashboard screen (BladeWatch-yz1e.2), shown in place of the
  /// [StubScreen] when [ShellController.selectedRoute] is [BwRoutes.dashboard].
  /// Optional and defaulting to null so every existing caller/test that
  /// doesn't care about Dashboard content keeps getting the stub unchanged —
  /// each of Epic 2's other screen tasks adds its own such slot the same way
  /// as it lands, rather than this shell taking on an 11-route registry
  /// up front for screens that don't exist yet.
  final Widget? dashboardScreen;

  /// The real Settings hub (BladeWatch-yz1e.3), shown for [BwRoutes.settings].
  /// Same optional/defaulting-to-null shape as [dashboardScreen] — see its
  /// doc comment for why.
  final Widget? settingsScreen;

  /// The real Settings → About screen (BladeWatch-yz1e.3), shown for
  /// [BwRoutes.settingsAbout] — its own top-level rail destination, separate
  /// from the Settings sub-rail (see `BwRoutes`' own doc comment).
  final Widget? settingsAboutScreen;

  /// The real Diagnostics hub (BladeWatch-yz1e.4), shown for
  /// [BwRoutes.diagnostics]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? diagnosticsScreen;

  /// The real Trips screen (BladeWatch-yz1e.5), shown for [BwRoutes.trips].
  /// Same optional/defaulting-to-null shape as [dashboardScreen] — see its
  /// doc comment for why.
  final Widget? tripsScreen;

  /// The real Location screen (BladeWatch-yz1e.6), shown for
  /// [BwRoutes.location]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? locationScreen;

  /// The real Recordings screen (BladeWatch-yz1e.7), shown for
  /// [BwRoutes.recordings]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? recordingsScreen;

  /// The real Surveillance settings screen (BladeWatch-yz1e.8), shown for
  /// [BwRoutes.surveillance] — this screen's standalone entry point (native:
  /// `SurveillanceSettingsFragment`/`surveillanceSettingsWebFragment`), kept
  /// alongside its Settings sub-rail mount (see `SettingsScreen`'s
  /// `_Section.surveillance`) since native reaches it from both. Same
  /// optional/defaulting-to-null shape as [dashboardScreen] — see its doc
  /// comment for why.
  final Widget? surveillanceScreen;

  /// The real Vehicle screen (BladeWatch-yz1e.9), shown for
  /// [BwRoutes.vehicle]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? vehicleScreen;

  /// The real Live View screen (BladeWatch-yz1e.10), shown for
  /// [BwRoutes.liveView]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? liveViewScreen;

  /// Live tunnel URL for the toolbar status pill (BladeWatch-0kru). Null
  /// source, or a source that answers null, means NO pill at all — native's
  /// `MainActivity.updateUrlDisplay()` sets `urlBar` to `View.GONE` when there is
  /// no tunnel, because the Dashboard connect card already says "No tunnel
  /// running". Showing a placeholder instead is what this replaced.
  final Future<String?> Function()? tunnelUrlSource;

  const AppShell({
    super.key,
    required this.controller,
    required this.onLanguageTap,
    this.tunnelUrlSource,
    this.dashboardScreen,
    this.settingsScreen,
    this.settingsAboutScreen,
    this.diagnosticsScreen,
    this.tripsScreen,
    this.locationScreen,
    this.recordingsScreen,
    this.surveillanceScreen,
    this.vehicleScreen,
    this.liveViewScreen,
  });

  Widget? _screenFor(String route) => switch (route) {
        BwRoutes.dashboard => dashboardScreen,
        BwRoutes.settings => settingsScreen,
        BwRoutes.settingsAbout => settingsAboutScreen,
        BwRoutes.diagnostics => diagnosticsScreen,
        BwRoutes.trips => tripsScreen,
        BwRoutes.location => locationScreen,
        BwRoutes.recordings => recordingsScreen,
        BwRoutes.surveillance => surveillanceScreen,
        BwRoutes.vehicle => vehicleScreen,
        BwRoutes.liveView => liveViewScreen,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
        final l10n = AppLocalizations.of(context)!;

        final rail = NavRail(
          selectedRoute: controller.selectedRoute,
          onSelect: controller.selectRoute,
          showLanguageHeader: isLandscape,
          onLanguageTap: isLandscape ? onLanguageTap : null,
          compact: isLandscape,
        );

        final stage = Column(
          children: [
            _Toolbar(
              tunnelUrlSource: tunnelUrlSource,
              compact: isLandscape,
              title: _currentTitle(l10n),
              showLanguageButton: !isLandscape,
              onLanguageTap: onLanguageTap,
            ),
            Container(
              key: const ValueKey('accentStripe'),
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                ),
              ),
            ),
            Expanded(
              // A Navigator scoped to the STAGE, not the whole window. Native
              // keeps the nav rail visible when you open a sub-screen (ADB
              // Console, Performance) and shows a back arrow in the toolbar;
              // pushing on the root navigator covered the rail and left the
              // user with no sense of place (BladeWatch-mrsc).
              //
              // Dialogs are unaffected: showDialog defaults to
              // useRootNavigator: true, so they still cover the whole window
              // rather than being trapped inside the stage.
              child: Navigator(
                // Keyed by route so switching rail destination rebuilds the
                // stage navigator, discarding any sub-screen that was open.
                // Without this, leaving Diagnostics while the ADB Console was
                // pushed would keep showing the console under the new title.
                key: ValueKey('stageNav.${controller.selectedRoute}'),
                onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) =>
                      _screenFor(controller.selectedRoute) ?? StubScreen(routeName: controller.selectedRoute),
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: controller.railOnRight
                  ? [Expanded(child: stage), rail]
                  : [rail, Expanded(child: stage)],
            ),
          ),
        );
      },
    );
  }

  String _currentTitle(AppLocalizations l10n) {
    for (final destination in railDestinations) {
      if (destination.routeName == controller.selectedRoute) {
        return destination.label(l10n);
      }
    }
    return controller.selectedRoute;
  }
}

/// `MaterialToolbar` + its end-cluster status pill, ported from both
/// `activity_main_new.xml` variants (see class doc above for what differs).
class _Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final Future<String?> Function()? tunnelUrlSource;
  final bool compact;
  final String title;
  final bool showLanguageButton;
  final VoidCallback onLanguageTap;

  const _Toolbar({
    this.tunnelUrlSource,
    required this.compact,
    required this.title,
    required this.showLanguageButton,
    required this.onLanguageTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(compact ? 48 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      toolbarHeight: preferredSize.height,
      title: Text(title, style: compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge),
      actions: [
        _StatusPill(source: tunnelUrlSource),
        if (showLanguageButton)
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.settings_language_label,
            onPressed: onLanguageTap,
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Tunnel-connection status pill — `statusPill`/`urlStatusDot`/`tvCurrentUrl`/
/// `btnCopyUrl` in `activity_main_new.xml`.
///
/// BladeWatch-0kru: this used to be a hardcoded placeholder that said
/// "Connecting…" forever, with a grey dot and a dead copy button, on every
/// screen. That was not merely unfinished, it was WRONG — with no tunnel
/// configured nothing is connecting and nothing ever will, so it read as an app
/// stuck mid-connect.
///
/// It now mirrors `MainActivity.updateUrlDisplay()` exactly: **no URL means no
/// pill.** The Dashboard connect card is the one place that explains the
/// "No tunnel running" state, and native deliberately does not duplicate it here.
class _StatusPill extends StatefulWidget {
  final Future<String?> Function()? source;

  const _StatusPill({this.source});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  /// Matches the cadence the Dashboard already refreshes tunnel state at. A
  /// tunnel comes up or drops on a human timescale, so polling faster buys
  /// nothing and costs an IPC round-trip each time.
  static const _pollInterval = Duration(seconds: 10);

  String? _url;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.source == null) return;
    unawaited(_refresh());
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    String? url;
    try {
      url = await widget.source!();
    } catch (_) {
      // An IPC failure is indistinguishable from "no tunnel" as far as this
      // pill is concerned, and native hides the bar in both cases.
      url = null;
    }
    if (!mounted || url == _url) return;
    setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    // The whole point of BladeWatch-0kru: render NOTHING rather than a placeholder.
    if (url == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: const ValueKey('shell.statusPill.dot'),
                width: 8,
                height: 8,
                // Online, matching native's status_dot_online — a URL only
                // reaches here when the tunnel process is alive.
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                url,
                key: const ValueKey('shell.statusPill.url'),
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: colors.primary, fontFamily: 'monospace'),
              ),
              IconButton(
                key: const ValueKey('shell.statusPill.copy'),
                icon: const Icon(Icons.copy, size: 18),
                tooltip: l10n.cd_copy_url,
                color: colors.onSurfaceVariant,
                onPressed: () => Clipboard.setData(ClipboardData(text: url)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
