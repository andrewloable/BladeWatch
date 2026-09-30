import 'package:flutter_test/flutter_test.dart';

/// Call at the top of `main()` of a WIDGET test file whose screens are on the HUD skin.
///
/// The HUD's pulse (`HudPulse`) loops forever and every HUD screen carries one in its title bar, which
/// `pumpAndSettle` would wait on until it times out. It stands still when the platform asks for no
/// animations, so a file that pumps a HUD screen requests that for each of its tests.
///
/// Not a global `flutter_test_config.dart`: that would put the widget test binding under the suite's plain
/// `test()`s too, and the ones that use real sockets (the hero asset server, the health check) fail under it.
void hudTestEnvironment() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() => binding.platformDispatcher.clearAccessibilityFeaturesTestValue());
}
