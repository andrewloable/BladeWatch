import 'dart:io';

import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/vehicle_dialog_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

/// Controllers get disposed while their `load()` is still awaiting an RPC.
///
/// Every screen fires an un-awaited `load()` from `initState` and then awaits a
/// call with a 5 s connect / 10 s read timeout before notifying. Three places
/// dispose a controller inside that window:
///
///  * `dashboard_screen._openVehicleDialog` — `showDialog` is barrier
///    dismissible; the controller is disposed the moment the barrier is tapped.
///  * `recordings_screen._selectForPane` — picking a second clip disposes the
///    previous pane's controller. Its `identical(item, current)` staleness guard
///    does NOT cover this: the old controller's own `current` never changed, so
///    the guard passes and it notifies anyway.
///  * `settings_screen._select` — disposes the outgoing section's controller on
///    every tab switch. The most reachable of the three; the settings rail is a
///    row of taps.
///
/// `notifyListeners()` guards disposal with
/// `assert(ChangeNotifier.debugAssertNotDisposed(this))`, so this throws in
/// DEBUG and is a silent no-op in release. Debug is what runs on the head unit
/// through every iteration, and "correct only because an assert was compiled
/// out" is not correct.
void main() {
  test('disposing mid-load does not throw when the response lands', () async {
    final rpc = FakeRpcClient();
    rpc.stubJson('SystemService', 'GetModelsManifest', {
      'manifestJson': '{"models":[{"id":"seal","name":"BYD Seal","nominalKwh":82.5}]}',
    });
    rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'seal'});

    final c = VehicleDialogController(systemService: SystemServiceClient(rpc));
    c.addListener(() {});

    // load() runs until its first `await`, then suspends -- the window in which
    // the user taps the dialog's barrier.
    final pending = c.load();
    c.dispose();

    // Resuming must not assert. Before DisposedSafeNotifier this threw
    // "A VehicleDialogController was used after being disposed".
    await expectLater(pending, completes);
  });

  /// A source scan, not a behavioural test, because the failure mode is
  /// "somebody adds a twenty-second controller and forgets" -- and a controller
  /// that is never disposed mid-flight in today's screens still notifies fine,
  /// so no behavioural test would notice until a screen is reparented.
  ///
  /// Same shape as `main_dispose_test.dart`, which guards the sibling omission.
  test('every awaiting ChangeNotifier uses DisposedSafeNotifier', () {
    var root = Directory('lib');
    if (!root.existsSync()) root = Directory('flutter_ui/lib');
    expect(root.existsSync(), isTrue, reason: 'could not locate lib/');

    // live_view_controller keeps its own `_disposed` because it must ABORT work
    // (stop the tick loop, release the codec), not merely skip a notify. The
    // mixin deliberately exposes no isDisposed getter, so it cannot serve that.
    const exempt = {'live_view_controller.dart'};

    final offenders = <String>[];
    for (final f in root.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (exempt.contains(f.uri.pathSegments.last)) continue;
      final src = f.readAsStringSync();
      if (!src.contains('extends ChangeNotifier')) continue;
      // No await means it cannot be disposed across a suspension point.
      if (!src.contains('await')) continue;
      if (!src.contains('DisposedSafeNotifier')) offenders.add(f.path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These controllers await and then notify, but are not protected '
          'against being disposed mid-await. Add `with DisposedSafeNotifier` '
          '(lib/shell/disposed_safe_notifier.dart) to each.',
    );
  });

  /// The mixin only runs if each controller's own `dispose()` chains to `super`.
  ///
  /// `DisposedSafeNotifier.dispose()` sits between the controller and
  /// `ChangeNotifier` in the mixin linearisation, so a controller that overrides
  /// `dispose()` and forgets `super.dispose()` silently skips BOTH: `_disposed`
  /// is never set (this guard becomes inert) and `ChangeNotifier.dispose()` never
  /// runs (the listener list is never released). Neither failure is visible at
  /// runtime -- the app keeps working and just leaks.
  ///
  /// Today only `adb_console_controller.dart` overrides `dispose()`, and it does
  /// chain. This pins that any future override does too.
  test('every controller that overrides dispose() calls super.dispose()', () {
    var root = Directory('lib');
    if (!root.existsSync()) root = Directory('flutter_ui/lib');
    expect(root.existsSync(), isTrue, reason: 'could not locate lib/');

    final offenders = <String>[];
    for (final f in root.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      if (!src.contains('extends ChangeNotifier')) continue;

      // Take each `void dispose() {` body up to its closing brace at the same
      // indent, and require a super.dispose() inside it.
      for (final m in RegExp(r'\n(\s*)(?:@override\s*\n\s*)?void dispose\(\) \{(.*?)\n\1\}', dotAll: true)
          .allMatches(src)) {
        if (!m.group(2)!.contains('super.dispose()')) {
          offenders.add(f.uri.pathSegments.last);
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These controllers override dispose() without calling '
          'super.dispose(). That skips DisposedSafeNotifier (so the '
          'notify-after-dispose guard stops working) AND '
          'ChangeNotifier.dispose() (so listeners are never released).',
    );
  });
}
