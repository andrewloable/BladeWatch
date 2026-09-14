import 'package:flutter/foundation.dart';

/// Makes [notifyListeners] a no-op once the notifier has been disposed.
///
/// Every controller here loads by firing an un-awaited `load()` from a
/// `initState`, then awaiting an RPC (5 s connect / 10 s read) before calling
/// `notifyListeners()`. Three places dispose a controller while exactly that is
/// in flight:
///
///  * `dashboard_screen._openVehicleDialog` — `showDialog` is barrier
///    dismissible, and the controller is disposed the instant the barrier is
///    tapped;
///  * `recordings_screen._selectForPane` — selecting a second clip disposes the
///    previous pane's controller. Its `identical(item, current)` staleness guard
///    does not help: the OLD controller's `current` is unchanged, so the guard
///    passes and it notifies anyway;
///  * `settings_screen._select` — disposes the outgoing section's controller on
///    every tab switch. The most reachable of the three, since the settings rail
///    is a row of taps.
///
/// `ChangeNotifier.notifyListeners()` guards this with
/// `assert(debugAssertNotDisposed(this))`, so the throw is DEBUG-ONLY — in
/// release `_count` is 0 after dispose and the call returns early. That makes it
/// a development-build defect, not a shipping crash, but debug is what runs on
/// the head unit during every iteration, and relying on an assert being
/// compiled out is not the same as being correct.
///
/// Deliberately not an `isDisposed` getter for callers to branch on: the point
/// is that no caller should have to. Anything that needs to ABORT work (cancel a
/// tick loop, release a codec) still needs its own flag —
/// `live_view_controller` keeps one for exactly that reason and does not use
/// this mixin.
mixin DisposedSafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
