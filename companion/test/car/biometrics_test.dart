import 'package:bladewatch_companion/car/biometrics.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-hr6r.6: LocalAuthBiometrics must never let a platform-channel exception -- no
/// implementation registered, exactly the situation in every one of these tests, and on a real
/// Linux device, which local_auth does not implement at all -- escape as an error. It means "no
/// biometrics", nothing else. A plain `test()` (not `testWidgets()`) is deliberate here: the real
/// plugin call crosses a platform channel that never resolves under `pump()`'s fake-async clock
/// (it needs `tester.runAsync`), but resolves immediately in a bare Dart test's real event loop --
/// which is exactly the "no plugin registered" case this proves.
void main() {
  test('available() is false, not an exception, with no platform implementation registered', () async {
    expect(await LocalAuthBiometrics().available(), isFalse);
  });

  test('authenticate() is false, not an exception, with no platform implementation registered', () async {
    expect(await LocalAuthBiometrics().authenticate('test'), isFalse);
  });
}
