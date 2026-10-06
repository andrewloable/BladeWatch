import 'package:flutter_pear/flutter_pear.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// BladeWatch-a7mu: the owner relay key, on the REAL worklet.
///
/// The unit tests check the derivation under Node; this checks it where it actually runs: the Bare
/// runtime, with the platform's own libsodium build -- on an arm64 Android target, the same
/// libsodium-native and Bare Kit the car's pear_daemon loads. The relay's public key it returns must
/// equal the reference relay's (relay/test/relay.test.js), or a phone would dial a relay that does
/// not exist. Run on a real target:
///
///     flutter test integration_test/relay_key_test.dart -d <arm64 emulator or device>
///     flutter test integration_test/relay_key_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A plain test, not testWidgets: no widgets are involved, and on a Mac with accessibility features on,
  // testWidgets' end-of-test check fails on a semantics handle the system holds.
  test('the real worklet derives the reference relay key and turns it off again', () async {
    final pear = await Pear.start();
    try {
      final started = DateTime.now();
      final relay = await pear.setRelayKey('4821-0937-5562');
      final took = DateTime.now().difference(started);
      expect(relay, '7d040c713b507b86738ce0968f56e879d1d40407976148ae1877fd2f16cfedd5');
      // Argon2id at 64 MiB: printed so a slow target shows up in the log.
      // ignore: avoid_print
      print('relay.set took ${took.inMilliseconds} ms');

      expect(await pear.setRelayKey(null), isNull);
      expect(() => pear.setRelayKey('4821-0937'), throwsArgumentError);
      // Still on, and still the same relay, after a refused key.
      expect(await pear.setRelayKey('482109375562'), relay);
    } finally {
      await pear.dispose();
    }
  });
}
