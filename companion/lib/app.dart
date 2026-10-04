import 'dart:async';

import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import 'car/car_page.dart';
import 'car/car_session.dart';
import 'car/car_store.dart';
import 'i18n.dart';
import 'screens/common/stats.dart' show fitScaler;
import 'screens/alerts/alerts_controller.dart';
import 'screens/common/loader.dart' show ContentWidth;
import 'screens/common/shell_nav.dart';
import 'screens/destinations.dart';
import 'screens/pairing/pairing_controller.dart';
import 'screens/pairing/pairing_screen.dart';
import 'tv.dart';

/// The companion app: pairing until a car is paired, then the car's screens.
class CompanionApp extends StatefulWidget {
  const CompanionApp({
    super.key,
    required this.store,
    required this.loadTr,
    this.openSession = CarSession.open,
    this.scan,
    this.pairing,
    this.wifiPairing = false,
    this.tv = false,
  });

  final CarStore store;
  final Future<Tr> Function(String lang) loadTr;
  final Future<CarSession> Function(PairedCar car) openSession;
  final Future<String?> Function(BuildContext context)? scan;

  /// Test seam; by default pairing opens sessions with [openSession].
  final PairingController? pairing;

  /// Pairing by number over the car's Wi-Fi, for a device without a camera: TVs and desktops.
  final bool wifiPairing;

  /// An Android TV: the remote's up and down leave text fields ([DpadFieldExit]).
  final bool tv;

  @override
  State<CompanionApp> createState() => CompanionAppState();
}

class CompanionAppState extends State<CompanionApp> {
  Tr? _tr;
  CarSession? _session;
  AlertsController? _alerts;
  late final AppLifecycleListener _lifecycle;
  late final _pairing = widget.pairing ?? PairingController(openSession: widget.openSession);

  CarStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    // A phone that slept may have lost its Pear connection: check it the moment the app is back,
    // and look again only if it is gone (CarSession.resumed, BladeWatch-rdtj.36).
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_session?.resumed()), onPause: () => _session?.paused());
    unawaited(_start());
  }

  Future<void> _start() async {
    await setLanguage(store.language);
    final car = store.car;
    if (car != null) await _open(car);
  }

  /// [lang] null follows the device.
  Future<void> setLanguage(String? lang) async {
    final tr = await widget.loadTr(lang ?? Tr.pick(WidgetsBinding.instance.platformDispatcher.locale));
    if (lang != store.language) {
      store.language = lang;
      await store.save();
    }
    if (mounted) setState(() => _tr = tr);
  }

  Future<void> _open(PairedCar car) async {
    final session = await widget.openSession(car);
    // BladeWatch-rdtj.38: remember where the car sits on its Wi-Fi, for the next search.
    session.addListener(() {
      final ip = session.carLanAddress;
      final paired = store.car;
      if (ip == null || paired == null || ip == paired.lanHint) return;
      store.car = paired.withLanHint(ip);
      unawaited(store.save());
    });
    final alerts = AlertsController(session: session, store: store);
    if (!mounted) {
      session.dispose();
      return;
    }
    setState(() {
      _session = session;
      _alerts = alerts;
    });
  }

  Future<void> _paired(PairedCar car) async {
    store.car = car;
    await store.save();
    await _open(car);
  }

  /// Forgets the car on this device. The car keeps listing it until it is removed there too.
  Future<void> unpair() async {
    _alerts?.dispose();
    _session?.dispose();
    store.car = null;
    await store.save();
    setState(() {
      _session = null;
      _alerts = null;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _alerts?.dispose();
    _session?.dispose();
    _pairing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = _tr;
    final session = _session;
    final Widget home;
    if (tr == null) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (session == null) {
      home = store.car != null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : PairingScreen(controller: _pairing, onPaired: _paired, scan: widget.scan, wifi: widget.wifiPairing);
    } else {
      home = SessionScope(
        session: session,
        child: HomeShell(alerts: _alerts!, store: store, onLanguage: setLanguage, onUnpair: unpair),
      );
    }
    return MaterialApp(
      title: 'BladeWatch',
      debugShowCheckedModeBanner: false,
      theme: BwHud.themeData(Brightness.light),
      darkTheme: BwHud.themeData(Brightness.dark),
      builder: (context, child) {
        final page = widget.tv ? DpadFieldExit(child: TvFocusRing(child: child!)) : child!;
        return tr == null ? page : TrScope(tr: tr, child: page);
      },
      home: home,
    );
  }
}

/// The car's screens: a bottom bar with "More" on a phone, a permanent side panel when wide. There is no app bar:
/// the screen's name is a [HudTitleBar] over it, and the navigation is the in-car rail's item ([HudNavItem]).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.alerts, required this.store, required this.onLanguage, required this.onUnpair});

  final AlertsController alerts;
  final CarStore store;
  final Future<void> Function(String? lang) onLanguage;
  final Future<void> Function() onUnpair;

  /// The design language's wide-layout minimum (docs/ui-ux-design-language.md).
  static const wideMinWidth = 700.0;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final hud = BwHud.of(context);
    final all = destinations(
      alerts: widget.alerts,
      store: widget.store,
      onLanguage: widget.onLanguage,
      onUnpair: widget.onUnpair,
    );
    final current = all[_index];
    final page = ShellNav(
      go: (id) {
        final i = all.indexWhere((d) => d.id == id);
        if (i >= 0) _go(i);
      },
      child: CarPage(onPairAgain: widget.onUnpair, child: current.build(context)),
    );
    final wide = MediaQuery.sizeOf(context).width >= HomeShell.wideMinWidth;
    // The title bar lines up with the page below it (same padding, same width cap).
    // Live and Location fill the stage (a picture and a map are better wide), so their title bar does too; every
    // other page is capped at the content width and its title bar with it.
    final fillsStage = current.id == 'live' || current.id == 'location';
    final title = HudTitleBar(title: tr(current.label).toUpperCase());
    final stage = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BwDimens.pagePaddingHorizontal,
            BwDimens.pagePaddingTop,
            BwDimens.pagePaddingHorizontal,
            0,
          ),
          child: fillsStage ? title : ContentWidth(child: title),
        ),
        Expanded(child: page),
      ],
    );

    if (wide) {
      return Scaffold(
        backgroundColor: hud.pageBackground,
        body: Row(
          children: [
            TvPane(child: _SidePanel(all: all, index: _index, onSelect: _go, alerts: widget.alerts)),
            Expanded(child: TvPane(child: SafeArea(left: false, child: stage))),
          ],
        ),
      );
    }

    // Phone: the first four are the bar; everything else is one tap into "More".
    final primary = all.take(4).toList();
    final inMore = _index >= primary.length;
    return Scaffold(
      backgroundColor: hud.pageBackground,
      body: SafeArea(bottom: false, child: stage),
      bottomNavigationBar: _BottomBar(
        key: const ValueKey('nav.bar'),
        items: [
          for (var i = 0; i < primary.length; i++)
            (id: primary[i].id, icon: primary[i].icon, label: tr(primary[i].label), selected: i == _index),
          (id: 'more', icon: Icons.more_horiz, label: tr('nav.more'), selected: inMore),
        ],
        alerts: widget.alerts,
        onSelect: (i) => i < primary.length ? _go(i) : _more(context, all, primary.length),
      ),
    );
  }

  Future<void> _more(BuildContext context, List<Destination> all, int from) async {
    final tr = context.tr;
    final picked = await showHudSheet<int>(
      context: context,
      // Sized to its nine rows (BladeWatch-rdtj.51). The default caps a sheet at 9/16 of the
      // screen, which hid two places on a real phone with nothing to say the list scrolls. It
      // still scrolls where even the whole screen is too short, and stays under the status bar.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            for (var i = from; i < all.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HudListRow(
                  key: ValueKey('more.${all[i].id}'),
                  icon: all[i].icon,
                  title: tr(all[i].label),
                  selected: i == _index,
                  onTap: () => Navigator.pop(context, i),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _go(picked);
  }
}

/// The wide layout's permanent side panel: the name on top (it never scrolls), then every place.
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.all, required this.index, required this.onSelect, required this.alerts});

  final List<Destination> all;
  final int index;
  final ValueChanged<int> onSelect;
  final AlertsController alerts;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final tr = context.tr;
    return Container(
      key: const ValueKey('nav.panel'),
      width: 240,
      decoration: BoxDecoration(
        color: hud.railBackground,
        border: Border(right: BorderSide(color: hud.railBorder)),
        boxShadow: hud.railShadow,
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // The name is the panel's HEADER, not its first list row (BladeWatch-rdtj.52): as a row it
            // scrolled with the places and was cut off at the top on the Android tablet, whose 800 dp
            // height is short of the thirteen rows. It sits below the SafeArea and never scrolls.
            Padding(
              key: const ValueKey('drawer.header'),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'BladeWatch',
                  style: hudText(
                    14,
                    hud.accent,
                    lineHeight: 20,
                    weight: FontWeight.w700,
                    em: 0.1,
                    shadows: hudGlow(hud.glowCyan),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: alerts,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (var i = 0; i < all.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: HudNavItem(
                          key: ValueKey('nav.${all[i].id}'),
                          icon: all[i].icon,
                          label: tr(all[i].label),
                          selected: i == index,
                          horizontal: true,
                          badge: all[i].id == 'events' ? alerts.unseen : 0,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The phone's bottom bar: the four first places and "More", each an in-car rail item. Every label shows, scaled down
/// to fit its fifth of the width (the old Material bar hard-wrapped a long one mid-word, found on a real phone).
class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key, required this.items, required this.alerts, required this.onSelect});

  final List<({String id, IconData icon, String label, bool selected})> items;
  final AlertsController alerts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Container(
      decoration: BoxDecoration(
        color: hud.railBackground,
        border: Border(top: BorderSide(color: hud.railBorder)),
        boxShadow: hud.railShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListenableBuilder(
            listenable: alerts,
            builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
              // Every label one size, the largest at which the longest fits: on its own, RECORDINGS
              // shrank below its neighbours (the owner, 2026-10-04). An item's label has its width
              // less 4 + 2 dp of padding a side and the 1 dp border; bold is the wider weight.
              final width = constraints.maxWidth / items.length - 2 * (4 + 2 + 1);
              final labels = fitScaler(
                context,
                navLabelStyle(color: hud.navInactive, selected: true),
                [for (final item in items) (item.label.toUpperCase(), width)],
                base: navLabelBaseScaler(context),
              );
              return Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: HudNavItem(
                        key: ValueKey('nav.${items[i].id}'),
                        icon: items[i].icon,
                        label: items[i].label,
                        selected: items[i].selected,
                        badge: items[i].id == 'events' ? alerts.unseen : 0,
                        labelScaler: labels,
                        onTap: () => onSelect(i),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
