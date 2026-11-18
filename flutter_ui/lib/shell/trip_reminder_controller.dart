import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart'
    show AcknowledgeTripReminderRequest, ActiveTripStatus, GetActiveTripRequest, StopManualTripRequest;
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

import 'disposed_safe_notifier.dart';

/// Watches the open manual trip for a "you forgot to stop it" reminder (BladeWatch-gklt.6).
///
/// The daemon raises the reminder (car turned off, or parked 30 minutes) and counts them in
/// `reminderSeq`. The car is usually OFF when it happens, so the head unit's screen is off too:
/// nobody can see a dialog then. So this does not wait for a push. It POLLS, and the dialog
/// appears the next time the app is on screen, whichever page that is.
///
/// A reminder is pending while `reminderSeq > reminderAckedSeq`. Showing it and then calling
/// [acknowledge] moves the daemon's acked sequence, so it is shown once per reminder, even across
/// an app restart. If that call fails, [_locallyAcked] still keeps it from coming straight back
/// on the next poll.
class TripReminderController extends ChangeNotifier with DisposedSafeNotifier {
  TripReminderController({
    required TripsServiceClient tripsService,
    this.pollInterval = const Duration(seconds: 15),
  }) : _tripsService = tripsService; // ignore: prefer_initializing_formals

  final TripsServiceClient _tripsService;

  /// How often the daemon is asked. 15 s: the dialog is for a trip left open for minutes or hours.
  final Duration pollInterval;

  ActiveTripStatus _status = ActiveTripStatus();
  Timer? _timer;
  int _locallyAcked = 0;

  /// The open trip's status as last read.
  ActiveTripStatus get status => _status;

  /// The reminder to show now, or null.
  ActiveTripStatus? get pending {
    if (!_status.manual) return null;
    final seq = _status.reminderSeq.toInt();
    final acked = _status.reminderAckedSeq.toInt();
    return seq > acked && seq > _locallyAcked ? _status : null;
  }

  /// Start polling (and read once now). Safe to call twice.
  void start() {
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
    refresh();
  }

  /// Read the open trip's status. A failed read keeps what is known.
  Future<void> refresh() async {
    try {
      final s = (await _tripsService.getActiveTrip(GetActiveTripRequest())).status;
      if (s == _status) return;
      _status = s;
      notifyListeners();
    } catch (_) {
      // The daemon may be restarting; the next poll tries again.
    }
  }

  /// The driver has seen reminder [seq]: never show it again. Does not stop the trip.
  ///
  /// Sends [seq] itself, NOT the latest sequence in [status]: a newer reminder can arrive while the
  /// dialog for an older one is open, and acknowledging that newer one would swallow it unseen.
  Future<void> acknowledge(int seq) async {
    if (seq > _locallyAcked) _locallyAcked = seq;
    notifyListeners();
    try {
      final r = await _tripsService.acknowledgeTripReminder(
        AcknowledgeTripReminderRequest(reminderSeq: Int64(seq)),
      );
      _status = r.status;
    } catch (_) {
      // Kept by _locallyAcked for this session.
    }
    notifyListeners();
  }

  /// Stop the manual trip. True when the daemon confirmed it.
  Future<bool> stopTrip() async {
    try {
      await _tripsService.stopManualTrip(StopManualTripRequest());
    } catch (_) {
      return false;
    }
    await refresh();
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
