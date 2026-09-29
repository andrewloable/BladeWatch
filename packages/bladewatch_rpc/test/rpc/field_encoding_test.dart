// Deep, real-field-type tests for the request/response round trip, going
// through the REAL ConnectClient (not FakeRpcClient) with only its network
// boundary (RawHttpSender) faked. The per-service wrapper tests under
// test/rpc/services/ prove every RPC is wired to the right
// service/method name and that its decode closure runs; this file proves the
// actual protobuf-JSON *content* is correct for a representative spread of
// field types: string, bool, int32, int64, double, repeated, nested message,
// and a proto-level custom `json_name` override.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/rpc/connect_client.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';

class _NullJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => null;
  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  group('real field-type encoding end to end', () {
    late String? capturedBody;
    late RawHttpResponse Function(Uri uri, String body) respond;
    late ConnectClient connectClient;

    setUp(() {
      capturedBody = null;
      respond = (uri, body) => const RawHttpResponse(200, '{}');
      connectClient = ConnectClient(
        jwtSource: _NullJwtSource(),
        send: (uri, headers, body) async {
          capturedBody = body;
          return respond(uri, body);
        },
      );
    });

    test('a plain string field (SendTestRequest.category)', () async {
      final client = NotificationsServiceClient(connectClient);

      await client.sendTest(SendTestRequest(category: 'surveillance.motion.alert'));

      expect(jsonDecode(capturedBody!), {'category': 'surveillance.motion.alert'});
    });

    test('string + int64 fields on the response side (ListInboxResponse)', () async {
      respond = (uri, body) => const RawHttpResponse(
            200,
            '{"entries":[{"id":"7","category":"surveillance.motion","title":"Person at front"}],"latestId":"7","oldestId":"3"}',
          );
      final client = NotificationsServiceClient(connectClient);

      final response = await client.listInbox(ListInboxRequest());

      expect(response.entries.single.category, 'surveillance.motion');
      expect(response.entries.single.title, 'Person at front');
      expect(response.entries.single.id.toInt(), 7);
      expect(response.latestId.toInt(), 7);
      expect(response.oldestId.toInt(), 3);
    });

    test('a repeated string field (BatchDeleteRequest.filenames)', () async {
      final client = RecordingsServiceClient(connectClient);

      await client.batchDelete(
        BatchDeleteRequest(filenames: ['a.mp4', 'b.mp4', 'c.mp4']),
      );

      expect(jsonDecode(capturedBody!), {
        'filenames': ['a.mp4', 'b.mp4', 'c.mp4'],
      });
    });

    test('int32 and repeated-string response fields (BatchDeleteResponse)', () async {
      respond = (uri, body) => const RawHttpResponse(
            200,
            '{"success":false,"deleted":2,"failed":1,"errors":["c.mp4: locked"]}',
          );
      final client = RecordingsServiceClient(connectClient);

      final response = await client.batchDelete(BatchDeleteRequest());

      expect(response.success, isFalse);
      expect(response.deleted, 2);
      expect(response.failed, 1);
      expect(response.errors, ['c.mp4: locked']);
    });

    test('double and int32 fields (AddZoneRequest: lat/lng/radiusM)', () async {
      final client = SafeLocationsServiceClient(connectClient);

      await client.addZone(
        AddZoneRequest(name: 'Home', lat: 14.5995, lng: 120.9842, radiusM: 50),
      );

      expect(jsonDecode(capturedBody!), {
        'name': 'Home',
        'lat': 14.5995,
        'lng': 120.9842,
        'radiusM': 50,
      });
    });

    test(
      'a nested message with a proto-level custom json_name override and an int64 field '
      '(AddZoneResponse.zone: SafeZone.active -> "enabled", createdAtMs -> "createdAt")',
      () async {
        respond = (uri, body) => const RawHttpResponse(
              200,
              '{"success":true,"zone":{'
              '"id":"z1","name":"Home","lat":14.5995,"lng":120.9842,'
              '"radiusM":50,"enabled":true,"createdAt":"1737936000000"'
              '}}',
            );
        final client = SafeLocationsServiceClient(connectClient);

        final response = await client.addZone(AddZoneRequest());

        expect(response.success, isTrue);
        final zone = response.zone;
        expect(zone.id, 'z1');
        expect(zone.name, 'Home');
        expect(zone.lat, 14.5995);
        expect(zone.radiusM, 50);
        // Proves the custom `json_name = "enabled"` mapping from the .proto
        // (not the default camelCase of the field name `active`) round-trips.
        expect(zone.active, isTrue);
        // int64 fields serialize as JSON strings in proto3Json (avoids JS
        // number precision loss) — confirm it decodes back to the right value.
        expect(zone.createdAtMs.toInt(), 1737936000000);
      },
    );
  });
}
