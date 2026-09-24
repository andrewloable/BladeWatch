import 'dart:convert';

import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';

/// What redeeming a pairing QR's code once earns (BladeWatch-rdtj.7). [token] is a secret: it
/// logs this companion in for as long as the car keeps it paired.
class CompanionCredential {
  const CompanionCredential(this.companionId, this.token);

  final String companionId;
  final String token;
}

/// The car said no. [code] is the car's stable error code (`pairing_code_refused`,
/// `companion_refused`, a rate-limit message), never localized text.
class CarAuthRefused implements Exception {
  const CarAuthRefused(this.code);

  final String code;

  @override
  String toString() => 'CarAuthRefused($code)';
}

/// The companion's two public calls on the car (`AuthApiHandler`), made through the local
/// gateway -- so over pinned TLS whichever route it is using. Secrets travel in the body only.
class CarAuth {
  CarAuth(this.baseUrl, {RawHttpSender? send}) : _send = send ?? createIoHttpSender();

  final Uri baseUrl;
  final RawHttpSender _send;

  /// Trades the QR's single-use code for this companion's credential. [name] is what the car's
  /// "Pair a device" list shows.
  Future<CompanionCredential> redeem(String code, {String name = ''}) async {
    final json = await _post('/auth/pair', {'code': code, 'name': name});
    return CompanionCredential(json['companionId'] as String, json['token'] as String);
  }

  /// A session JWT for [credential].
  Future<String> login(CompanionCredential credential) async =>
      (await _post('/auth/companion', {'companionId': credential.companionId, 'token': credential.token}))['jwt'] as String;

  Future<Map<String, dynamic>> _post(String path, Map<String, String> body) async {
    final response = await _send(baseUrl.replace(path: path), const {'Content-Type': 'application/json'}, jsonEncode(body));
    final Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw CarAuthRefused('http_${response.statusCode}');
    }
    if (json is Map<String, dynamic> && json['success'] == true) return json;
    throw CarAuthRefused(json is Map ? '${json['error']}' : 'http_${response.statusCode}');
  }
}

/// Feeds [ConnectClient] a JWT from the companion login. Null when the car refuses or cannot be
/// reached, which ConnectClient treats as "no token yet" rather than an error.
class CompanionJwtSource implements JwtSource {
  CompanionJwtSource(this._auth, this._credential);

  final CarAuth _auth;
  final CompanionCredential _credential;

  @override
  Future<String?> mintJwt() async {
    try {
      return await _auth.login(_credential);
    } catch (_) {
      return null;
    }
  }

  // ponytail: constant -- a companion's credential only changes by re-pairing, which builds a
  // new source. A revoked credential shows up as a refused login, not a version bump.
  @override
  Future<int> stateVersion() async => 0;
}
