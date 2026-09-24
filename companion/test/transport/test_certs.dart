import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

// Throwaway self-signed EC P-256 certificates and a key made for these tests only -- not secrets.
// certA/keyA play the car's LAN/Pear TLS identity; certB is "some other certificate".
const certA = """-----BEGIN CERTIFICATE-----
MIIBjTCCATOgAwIBAgIUZ8bcp6Thp+iUuO4XIakd594q5rUwCgYIKoZIzj0EAwIw
HDEaMBgGA1UEAwwRYmxhZGV3YXRjaC10ZXN0LWEwHhcNMjYwOTI0MDMyMTU0WhcN
MzYwOTIxMDMyMTU0WjAcMRowGAYDVQQDDBFibGFkZXdhdGNoLXRlc3QtYTBZMBMG
ByqGSM49AgEGCCqGSM49AwEHA0IABCsjeT21UP5T3iXi6QRTVScrw1yTKqVlFr+J
YFHPDAG6tqXED1htdIsYEIJv3RfnXzWVN1rK7ldA0tG0UMmOfHmjUzBRMB0GA1Ud
DgQWBBTJmmQDO8S5awjGgJ3AN3UsLh1ElTAfBgNVHSMEGDAWgBTJmmQDO8S5awjG
gJ3AN3UsLh1ElTAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0gAMEUCIQCL
uf/R6FJckHfs3jW8fZeaeamsvGoLxu761nB3jwgJKgIgQ7X9sNmG8Pw92Tdu3aPx
JJ3ntFzD0ff8VXRkd4vDNkE=
-----END CERTIFICATE-----""";
const keyA = """-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgo3tVHV0sBVSZoIol
Cy4C5uQ7YeCOUQC4pbnR3GdGqA2hRANCAAQrI3k9tVD+U94l4ukEU1UnK8Nckyql
ZRa/iWBRzwwBuralxA9YbXSLGBCCb90X5181lTdayu5XQNLRtFDJjnx5
-----END PRIVATE KEY-----""";
const certB = """-----BEGIN CERTIFICATE-----
MIIBjTCCATOgAwIBAgIUEUk4eUO0degmi4bgwiAbBHSlHW8wCgYIKoZIzj0EAwIw
HDEaMBgGA1UEAwwRYmxhZGV3YXRjaC10ZXN0LWIwHhcNMjYwOTI0MDMyMTU1WhcN
MzYwOTIxMDMyMTU1WjAcMRowGAYDVQQDDBFibGFkZXdhdGNoLXRlc3QtYjBZMBMG
ByqGSM49AgEGCCqGSM49AwEHA0IABDWtTQ+y/kcd/XKLZuOLgKYevLVr4ZxTNLF/
y/O8IgTpactHaJN81tWoQMZz5RVcm8ShuTd2wrK5nhtlwxqMeNejUzBRMB0GA1Ud
DgQWBBSsaaSOFTlseCJ6horlLOOcMdPvczAfBgNVHSMEGDAWgBSsaaSOFTlseCJ6
horlLOOcMdPvczAPBgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0gAMEUCIQC8
lknGDihSEIO+idP7yujCiDb5UtrNd5zcGSpEyACAkQIgCrA8i/EGHUHV5jIONUlA
2mpSPaj4tCVZ1DhsLH+gSig=
-----END CERTIFICATE-----""";

/// The pin for a PEM certificate: lowercase hex SHA-256 of its DER, as pairing carries it.
String fingerprintOfPem(String pem) =>
    sha256.convert(base64.decode(pem.split('\n').where((l) => !l.startsWith('-----')).join())).toString();

/// A TLS server with certA that echoes whatever it is sent.
Future<SecureServerSocket> tlsEchoServer() async {
  final ctx = SecurityContext()
    ..useCertificateChainBytes(utf8.encode(certA))
    ..usePrivateKeyBytes(utf8.encode(keyA));
  final server = await SecureServerSocket.bind(InternetAddress.loopbackIPv4, 0, ctx);
  server.listen((s) => s.listen(s.add, onDone: s.close, onError: (Object _) => s.destroy()), onError: (Object _) {});
  return server;
}
