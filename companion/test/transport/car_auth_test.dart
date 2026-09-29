import 'dart:convert';

import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-rdtj.7/.8: the companion's side of pairing and login, against the car's wire shape.
void main() {
  final base = Uri.parse('http://127.0.0.1:40000');
  late List<(Uri, Map<String, dynamic>)> sent;
  late RawHttpResponse Function(Uri) reply;

  CarAuth auth() => CarAuth(base, send: (uri, headers, body) async {
        expect(headers['Content-Type'], 'application/json');
        sent.add((uri, jsonDecode(body) as Map<String, dynamic>));
        return reply(uri);
      });

  setUp(() => sent = []);

  test('redeem posts the code and name, and returns the credential', () async {
    reply = (_) => const RawHttpResponse(200, '{"success":true,"companionId":"c1","token":"t1"}');
    final credential = await auth().redeem('CODE', name: 'Pixel');
    expect((credential.companionId, credential.token), ('c1', 't1'));
    expect(sent.single.$1, Uri.parse('http://127.0.0.1:40000/auth/pair'));
    expect(sent.single.$2, {'code': 'CODE', 'name': 'Pixel'});
  });

  test('a refused code surfaces the car\'s error code', () async {
    reply = (_) => const RawHttpResponse(200, '{"success":false,"error":"pairing_code_refused"}');
    await expectLater(auth().redeem('USED'), throwsA(isA<CarAuthRefused>().having((e) => e.code, 'code', 'pairing_code_refused')));
    expect('${const CarAuthRefused('pairing_code_refused')}', 'CarAuthRefused(pairing_code_refused)');
  });

  test('a body that is not JSON is a refusal with the HTTP status, not a crash', () async {
    reply = (_) => const RawHttpResponse(502, '<html>bad gateway</html>');
    await expectLater(auth().redeem('X'), throwsA(isA<CarAuthRefused>().having((e) => e.code, 'code', 'http_502')));
    reply = (_) => const RawHttpResponse(500, '[]');
    await expectLater(auth().redeem('X'), throwsA(isA<CarAuthRefused>().having((e) => e.code, 'code', 'http_500')));
  });

  test('login sends the credential in the body and returns the JWT', () async {
    reply = (_) => const RawHttpResponse(200, '{"success":true,"jwt":"j.w.t","expiresIn":3600}');
    expect(await auth().login(const CompanionCredential('c1', 't1')), 'j.w.t');
    expect(sent.single.$1.path, '/auth/companion');
    expect(sent.single.$1.query, isEmpty, reason: 'the token never goes in a URL');
    expect(sent.single.$2, {'companionId': 'c1', 'token': 't1'});
  });

  test('the JWT source mints through login, and is null when the car refuses or is unreachable', () async {
    reply = (_) => const RawHttpResponse(200, '{"success":true,"jwt":"j.w.t"}');
    final source = CompanionJwtSource(auth(), const CompanionCredential('c1', 't1'));
    expect(await source.mintJwt(), 'j.w.t');
    expect(await source.stateVersion(), 0);

    reply = (_) => const RawHttpResponse(200, '{"success":false,"error":"companion_refused"}');
    expect(await source.mintJwt(), isNull);

    final offline = CompanionJwtSource(
      CarAuth(base, send: (_, _, _) async => throw const FormatException('connection refused')),
      const CompanionCredential('c1', 't1'),
    );
    expect(await offline.mintJwt(), isNull);
  });
}
