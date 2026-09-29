import 'dart:io';

import 'package:crypto/crypto.dart';

/// TLS to the car's LAN listener, trusting exactly one certificate: the one whose SHA-256
/// fingerprint (lowercase hex over the DER) was pinned at pairing (BladeWatch-rdtj.4/.8).
///
/// The car's certificate is self-signed, so no CA vouches for it and the platform calls
/// `onBadCertificate` -- which answers yes ONLY for the pinned fingerprint. It is checked again
/// on the certificate the connection actually presented, so a certificate some CA does happen to
/// trust cannot slip past the pin either. An unconditional "accept" here would be a
/// man-in-the-middle hole on exactly the shared Wi-Fi this path exists for.
class PinnedTls {
  static String fingerprintOf(X509Certificate cert) => sha256.convert(cert.der).toString();

  /// Straight to the car's LAN listener.
  static Future<SecureSocket> connect(InternetAddress host, int port, String pinnedFingerprint, {Duration timeout = const Duration(seconds: 5)}) async =>
      _checked(await SecureSocket.connect(
        host,
        port,
        timeout: timeout,
        onBadCertificate: (cert) => fingerprintOf(cert) == pinnedFingerprint,
      ), pinnedFingerprint);

  /// Over an existing socket -- the Pear path, where [raw] leads into a mux stream and the car's
  /// pump carries the records to its Pear TLS listener. A peer that never answers (another
  /// companion on the same topic) is given up on after [timeout].
  static Future<SecureSocket> secure(Socket raw, String pinnedFingerprint, {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      return _checked(
        await SecureSocket.secure(raw, onBadCertificate: (cert) => fingerprintOf(cert) == pinnedFingerprint).timeout(timeout),
        pinnedFingerprint,
      );
    } catch (_) {
      raw.destroy();
      rethrow;
    }
  }

  static SecureSocket _checked(SecureSocket socket, String pinnedFingerprint) {
    final presented = socket.peerCertificate;
    if (presented == null || fingerprintOf(presented) != pinnedFingerprint) {
      socket.destroy();
      throw const TlsException('the car presented a certificate that does not match the pairing pin');
    }
    return socket;
  }
}
