import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

import '../../car/car_session.dart';
import '../../car/car_store.dart';
import '../../inbox_sync.dart';

/// The alerts the car kept for this companion (BladeWatch-rdtj.14, store and forward). Fetched
/// whenever the car becomes reachable and every [every] while it stays so. The car holds at most
/// 200, so the whole list is fetched each time and the stored cursor only marks what the owner
/// has already seen.
class AlertsController extends ChangeNotifier {
  AlertsController({required this.session, required this.store, this.every = const Duration(minutes: 1)}) {
    session.addListener(_onSession);
    _onSession();
  }

  final CarSession session;
  final CarStore store;
  final Duration every;

  Timer? _poll;
  bool _wasConnected = false;
  Future<void>? _inFlight;

  List<InboxEntry> _all = const [];

  /// Newest first, muted categories left out -- filtered on read, so a mute applies at once.
  List<InboxEntry> get entries => _all.where((e) => !store.mutedCategories.contains(e.category)).toList();

  /// The owner changed which categories are muted.
  void refilter() => notifyListeners();

  NotificationsServiceClient get _client => NotificationsServiceClient(session.rpc);

  Int64 get _cursor => store.car?.inboxCursor ?? Int64.ZERO;

  int get unseen => entries.where((e) => e.id > _cursor).length;

  bool isNew(InboxEntry e) => e.id > _cursor;

  void _onSession() {
    final connected = session.connected;
    if (connected && !_wasConnected) {
      unawaited(refresh());
      _poll = Timer.periodic(every, (_) => unawaited(refresh()));
    } else if (!connected) {
      _poll?.cancel();
    }
    _wasConnected = connected;
  }

  /// A call while a fetch is running joins it rather than starting a second one.
  Future<void> refresh() => _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    try {
      final batch = await collectInbox(_client, Int64.ZERO);
      _all = batch.entries.reversed.toList();
      notifyListeners();
    } catch (_) {
      // Unreachable mid-fetch: keep what is shown; the next connection fetches again.
    }
  }

  /// Everything shown so far counts as seen.
  Future<void> markSeen() async {
    final car = store.car;
    final shown = entries;
    if (car == null || shown.isEmpty || shown.first.id <= car.inboxCursor) return;
    store.car = car.withCursor(shown.first.id);
    await store.save();
    notifyListeners();
  }

  /// A real alert through the whole path, raised by the car itself.
  Future<void> sendTest() async {
    await _client.sendTest(SendTestRequest(category: 'surveillance.motion', severity: 'info'));
    await Future<void>.delayed(const Duration(milliseconds: 500)); // the car's bus is async
    await refresh();
  }

  @override
  void dispose() {
    _poll?.cancel();
    session.removeListener(_onSession);
    super.dispose();
  }
}
