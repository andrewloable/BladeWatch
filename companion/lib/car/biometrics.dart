import 'package:local_auth/local_auth.dart';

/// Whether this device can authenticate locally -- fingerprint, face -- and whether it just did
/// (BladeWatch-hr6r.6). A seam so no test ever touches the real plugin; [LocalAuthBiometrics] is
/// the default used outside tests.
abstract class Biometrics {
  /// True only when the device supports biometrics AND has at least one enrolled. Any plugin
  /// exception -- including the MissingPluginException every plain `flutter test` throws (no
  /// platform channel is registered) and the one a real device throws on Linux, which local_auth
  /// does not implement at all -- means false, never an error the caller has to handle.
  Future<bool> available();

  /// Prompts with [reason]; true only on a successful match. Always biometricOnly: the device's
  /// own passcode is never an accepted substitute here -- the owner asked for a fingerprint/face
  /// or the BladeWatch PIN, not whatever else unlocks the phone.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}
