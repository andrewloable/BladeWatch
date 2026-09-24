import 'package:flutter_pear/flutter_pear.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// BladeWatch-rdtj.10: the real flutter_pear stack boots and shuts down cleanly in this app.
///
/// An integration test, not a unit test, on purpose: Pear.start() boots the genuine Bare worklet
/// through the platform host (a bare subprocess on desktop, Bare Kit on mobile), which a plain
/// `flutter test` has no engine to run. Run on a real target:
///
///     flutter test integration_test -d macos
///
/// Pear.start() itself round-trips attach.info with the worklet before returning, so reaching
/// dispose() means pear-end loaded and answered over IPC.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pear boots the real worklet and disposes cleanly', (
    tester,
  ) async {
    final pear = await Pear.start();
    await pear.dispose();
  });
}
