import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every RPC the in-car UI calls must be one the daemon actually serves.
///
/// The two sides are separate projects that agree only by convention: the Dart
/// clients under `lib/rpc/services/` pass a service and method name as plain
/// STRINGS to `RpcTransport.call`, and the daemon registers handlers by string
/// in `server/connect/impl/`. Nothing in either build checks that they
/// match, so a mismatch is a runtime 404 that surfaces only when a driver opens
/// the screen that needs it.
///
/// That had already happened. Removing the BYD cloud path deleted seven
/// VehicleService handlers (Lock, Unlock, Flash, FindCar, SetBatteryHeat, and
/// both charging-schedule RPCs), and the Dart wrappers for all seven stayed
/// behind. No screen called them, so nothing broke — but they compiled, which
/// is the trap: wiring up a Lock button would have looked completely correct
/// and failed only on the car.
///
/// A source scan because there is no shared artifact to check against. The
/// generated protos do not help: they still carry the request/response messages
/// for RPCs the daemon no longer registers, which is exactly why the dead
/// wrappers kept compiling.
void main() {
  /// Both roots, resolved whether the test runs from `flutter_ui/` or the repo
  /// root — the same fallback `main_dispose_test.dart` uses.
  (Directory, Directory)? locate() {
    for (final (dart, java) in [
      ('lib/rpc/services', '../app/src/main/java/com/loabletech/bladewatch/server/connect'),
      ('flutter_ui/lib/rpc/services', 'app/src/main/java/com/loabletech/bladewatch/server/connect'),
    ]) {
      final d = Directory(dart);
      final j = Directory(java);
      if (d.existsSync() && j.existsSync()) return (d, j);
    }
    return null;
  }

  test('every RPC the UI calls is registered by the daemon', () {
    final roots = locate();
    expect(roots, isNotNull,
        reason: 'could not locate both the Dart clients and the daemon Connect impls');
    final (dartRoot, javaRoot) = roots!;

    final served = <String>{};
    for (final f in javaRoot.listSync(recursive: true).whereType<File>()) {
      // Both extensions: the Connect impls are migrating to Kotlin (BladeWatch-9rut),
      // and a .java-only filter would quietly scan nothing and pass vacuously.
      if (!f.path.endsWith('.java') && !f.path.endsWith('.kt')) continue;
      for (final m in RegExp(r'register\(\s*"bladewatch\.v1\.(\w+)"\s*,\s*"(\w+)"')
          .allMatches(f.readAsStringSync())) {
        served.add('${m.group(1)}/${m.group(2)}');
      }
    }
    expect(served, isNotEmpty, reason: 'found no registered handlers — has the impl layout moved?');

    final unserved = <String, String>{};
    for (final f in dartRoot.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in RegExp(r"_transport\.call\(\s*'(\w+)',\s*'(\w+)'")
          .allMatches(f.readAsStringSync())) {
        final rpc = '${m.group(1)}/${m.group(2)}';
        if (!served.contains(rpc)) unserved[rpc] = f.uri.pathSegments.last;
      }
    }

    expect(
      unserved,
      isEmpty,
      reason: 'These RPCs are called by the in-car UI but no longer registered by '
          'the daemon, so each is a 404 waiting for someone to wire it to a '
          'button. Either restore the handler in server/connect/impl/, or delete '
          'the Dart wrapper.',
    );
  });
}
