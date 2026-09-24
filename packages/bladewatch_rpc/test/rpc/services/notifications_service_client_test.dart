import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('NotificationsServiceClient', () {
    late FakeRpcClient fake;
    late NotificationsServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = NotificationsServiceClient(fake);
    });

    test('getCategories sends NotificationsService/GetCategories and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetCategoriesResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'GetCategories', <String, dynamic>{});

      final result = await client.getCategories(GetCategoriesRequest());

      expect(result, isA<GetCategoriesResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'GetCategories');
      expect(fake.calls.single.request, isA<GetCategoriesRequest>());
    });

    test('subscribe sends NotificationsService/Subscribe and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SubscribeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'Subscribe', <String, dynamic>{});

      final result = await client.subscribe(SubscribeRequest());

      expect(result, isA<SubscribeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'Subscribe');
      expect(fake.calls.single.request, isA<SubscribeRequest>());
    });

    test('unsubscribe sends NotificationsService/Unsubscribe and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => UnsubscribeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'Unsubscribe', <String, dynamic>{});

      final result = await client.unsubscribe(UnsubscribeRequest());

      expect(result, isA<UnsubscribeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'Unsubscribe');
      expect(fake.calls.single.request, isA<UnsubscribeRequest>());
    });

    test('listSubscriptions sends NotificationsService/ListSubscriptions and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListSubscriptionsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'ListSubscriptions', <String, dynamic>{});

      final result = await client.listSubscriptions(ListSubscriptionsRequest());

      expect(result, isA<ListSubscriptionsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'ListSubscriptions');
      expect(fake.calls.single.request, isA<ListSubscriptionsRequest>());
    });

    test('updatePreferences sends NotificationsService/UpdatePreferences and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => UpdatePreferencesResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'UpdatePreferences', <String, dynamic>{});

      final result = await client.updatePreferences(UpdatePreferencesRequest());

      expect(result, isA<UpdatePreferencesResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'UpdatePreferences');
      expect(fake.calls.single.request, isA<UpdatePreferencesRequest>());
    });

    test('sendTest sends NotificationsService/SendTest and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SendTestResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('NotificationsService', 'SendTest', <String, dynamic>{});

      final result = await client.sendTest(SendTestRequest());

      expect(result, isA<SendTestResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'NotificationsService');
      expect(fake.calls.single.method, 'SendTest');
      expect(fake.calls.single.request, isA<SendTestRequest>());
    });

    test('listInbox sends NotificationsService/ListInbox and decodes the car\'s JSON entries', () async {
      // The car writes int64 as JSON numbers and severity as the enum name.
      fake.stubJson('NotificationsService', 'ListInbox', <String, dynamic>{
        'entries': [
          {'id': 7, 'timestampMs': 1700000000000, 'category': 'surveillance.motion', 'severity': 'NOTIFICATION_SEVERITY_ALERT', 'title': 't', 'body': 'b', 'clickUrl': '', 'tag': 'x'},
        ],
        'latestId': 9,
        'oldestId': 3,
      });

      final result = await client.listInbox(ListInboxRequest(afterId: Int64(6)));

      expect(fake.calls.single.method, 'ListInbox');
      expect((fake.calls.single.request as ListInboxRequest).afterId, Int64(6));
      expect(result.entries.single.id, Int64(7));
      expect(result.entries.single.severity, NotificationSeverity.NOTIFICATION_SEVERITY_ALERT);
      expect(result.entries.single.tag, 'x');
      expect(result.latestId, Int64(9));
      expect(result.oldestId, Int64(3));
    });


  });
}
