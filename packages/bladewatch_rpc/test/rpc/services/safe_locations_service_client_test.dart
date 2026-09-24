import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('SafeLocationsServiceClient', () {
    late FakeRpcClient fake;
    late SafeLocationsServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = SafeLocationsServiceClient(fake);
    });

    test('listZones sends SafeLocationsService/ListZones and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListZonesResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SafeLocationsService', 'ListZones', <String, dynamic>{});

      final result = await client.listZones(ListZonesRequest());

      expect(result, isA<ListZonesResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SafeLocationsService');
      expect(fake.calls.single.method, 'ListZones');
      expect(fake.calls.single.request, isA<ListZonesRequest>());
    });

    test('addZone sends SafeLocationsService/AddZone and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => AddZoneResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SafeLocationsService', 'AddZone', <String, dynamic>{});

      final result = await client.addZone(AddZoneRequest());

      expect(result, isA<AddZoneResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SafeLocationsService');
      expect(fake.calls.single.method, 'AddZone');
      expect(fake.calls.single.request, isA<AddZoneRequest>());
    });

    test('updateZone sends SafeLocationsService/UpdateZone and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => UpdateZoneResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SafeLocationsService', 'UpdateZone', <String, dynamic>{});

      final result = await client.updateZone(UpdateZoneRequest());

      expect(result, isA<UpdateZoneResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SafeLocationsService');
      expect(fake.calls.single.method, 'UpdateZone');
      expect(fake.calls.single.request, isA<UpdateZoneRequest>());
    });

    test('deleteZone sends SafeLocationsService/DeleteZone and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DeleteZoneResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SafeLocationsService', 'DeleteZone', <String, dynamic>{});

      final result = await client.deleteZone(DeleteZoneRequest());

      expect(result, isA<DeleteZoneResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SafeLocationsService');
      expect(fake.calls.single.method, 'DeleteZone');
      expect(fake.calls.single.request, isA<DeleteZoneRequest>());
    });

    test('toggle sends SafeLocationsService/Toggle and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ToggleSafeLocationsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SafeLocationsService', 'Toggle', <String, dynamic>{});

      final result = await client.toggle(ToggleSafeLocationsRequest());

      expect(result, isA<ToggleSafeLocationsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SafeLocationsService');
      expect(fake.calls.single.method, 'Toggle');
      expect(fake.calls.single.request, isA<ToggleSafeLocationsRequest>());
    });

  });
}
