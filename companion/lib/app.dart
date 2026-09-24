import 'dart:async';

import 'package:bladewatch_theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';

import 'car/car_page.dart';
import 'car/car_session.dart';
import 'car/car_store.dart';
import 'i18n.dart';
import 'screens/alerts/alerts_controller.dart';
import 'screens/destinations.dart';
import 'screens/pairing/pairing_controller.dart';
import 'screens/pairing/pairing_screen.dart';

/// The companion app: pairing until a car is paired, then the car's screens.
class CompanionApp extends StatefulWidget {
  const CompanionApp({
    super.key,
    required this.store,
    required this.loadTr,
    this.openSession = CarSession.open,
    this.scan,
    this.pairing,
  });

  final CarStore store;
  final Future<Tr> Function(String lang) loadTr;
  final Future<CarSession> Function(PairedCar car) openSession;
  final Future<String?> Function(BuildContext context)? scan;

  /// Test seam; by default pairing opens sessions with [openSession].
  final PairingController? pairing;

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
    // A phone that slept dropped its Pear connection; look again the moment it is back.
    _lifecycle = AppLifecycleListener(onResume: () => _session?.retry());
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
          : PairingScreen(controller: _pairing, onPaired: _paired, scan: widget.scan);
    } else {
      home = SessionScope(
        session: session,
        child: HomeShell(alerts: _alerts!, store: store, onLanguage: setLanguage, onUnpair: unpair),
      );
    }
    return MaterialApp(
      title: 'BladeWatch',
      debugShowCheckedModeBanner: false,
      theme: BladeWatchTheme.light(),
      darkTheme: BladeWatchTheme.dark(),
      builder: (context, child) => tr == null ? child! : TrScope(tr: tr, child: child!),
      home: home,
    );
  }
}

/// The car's screens: a bottom bar with "More" on a phone, a permanent drawer when wide.
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
    final all = destinations(alerts: widget.alerts, store: widget.store, onLanguage: widget.onLanguage, onUnpair: widget.onUnpair);
    final current = all[_index];
    final page = CarPage(onPairAgain: widget.onUnpair, child: current.build(context));
    final badge = ListenableBuilder(
      listenable: widget.alerts,
      builder: (context, _) => widget.alerts.unseen == 0
          ? const Icon(Icons.notifications_outlined)
          : Badge(label: Text('${widget.alerts.unseen}'), child: const Icon(Icons.notifications_outlined)),
    );
    Widget icon(Destination d) => d.id == 'events' ? badge : Icon(d.icon);

    if (MediaQuery.sizeOf(context).width >= HomeShell.wideMinWidth) {
      return Scaffold(
        body: Row(children: [
          NavigationDrawer(
            selectedIndex: _index,
            onDestinationSelected: _go,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text('BladeWatch', style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final d in all) NavigationDrawerDestination(icon: icon(d), label: Text(tr(d.label))),
            ],
          ),
          Expanded(child: Scaffold(appBar: AppBar(title: Text(tr(current.label))), body: page)),
        ]),
      );
    }

    // Phone: the first four are the bar; everything else is one tap into "More".
    final primary = all.take(4).toList();
    final inMore = _index >= primary.length;
    return Scaffold(
      appBar: AppBar(title: Text(tr(current.label))),
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: inMore ? primary.length : _index,
        onDestinationSelected: (i) => i < primary.length ? _go(i) : _more(context, all, primary.length),
        destinations: [
          for (final d in primary) NavigationDestination(icon: icon(d), label: tr(d.label)),
          NavigationDestination(icon: const Icon(Icons.more_horiz), label: tr('nav.more')),
        ],
      ),
    );
  }

  Future<void> _more(BuildContext context, List<Destination> all, int from) async {
    final tr = context.tr;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (var i = from; i < all.length; i++)
            ListTile(
              key: ValueKey('more.${all[i].id}'),
              leading: Icon(all[i].icon),
              title: Text(tr(all[i].label)),
              selected: i == _index,
              onTap: () => Navigator.pop(context, i),
            ),
        ]),
      ),
    );
    if (picked != null) _go(picked);
  }
}
