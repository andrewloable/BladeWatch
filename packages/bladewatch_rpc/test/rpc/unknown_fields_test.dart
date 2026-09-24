/// The daemon emits MORE JSON fields than the protos declare, and every client
/// is expected to tolerate that rather than fail.
///
/// This is not theoretical. Several Connect handlers are thin adapters over the
/// older REST handlers, and those emit hand-rolled JSON:
/// `TripsServiceImpl.handleListTrips` forwards `GET /api/trips`, whose bodies
/// come from `TripRecord.toJson()`
/// (app/src/main/java/com/loabletech/bladewatch/trips/TripRecord.java:87) —
/// which writes `kwhStart`/`kwhEnd`, fields that appear in NO .proto file.
/// `GetStatus` does the same with `battery.voltage`/`soc`/`lastUpdate`, as the
/// generated `BatteryInfo` doc comment in lib/gen/bladewatch/v1/system.pb.dart
/// already records: "which clients tolerate via jsonOptions.ignoreUnknownFields".
///
/// The Angular SPA sets exactly that on its transport
/// (web/src/app/core/connect/connect.provider.ts:36). This port initially
/// omitted the Dart equivalent, so `mergeFromProto3Json` defaulted to
/// `ignoreUnknownFields: false` and threw on the FIRST unknown field —
/// failing the whole response, not just the field. On device that surfaced as
/// the Trips screen rendering only:
///   "Error: FormatException: Protobuf JSON decoding failed at:
///    root["trips"]["0"]["kwhStart"]. Unknown field name 'kwhStart'"
///
/// These tests pin the tolerance at the decode-closure level, where the bug
/// was, using `stubJson` so the wrapper's real closure runs.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  late FakeRpcClient fake;

  setUp(() => fake = FakeRpcClient());

  group('unknown daemon fields are tolerated, known fields still parse', () {
    test('ListTrips decodes despite kwhStart/kwhEnd, which are in no proto', () async {
      // The exact shape that failed on the head unit: TripRecord.toJson() keys
      // the proto does not declare, alongside ones it does.
      fake.stubJson('TripsService', 'ListTrips', <String, dynamic>{
        'trips': [
          <String, dynamic>{
            'id': '42',
            'distanceKm': 12.5,
            'kwhStart': 41.2, // not in trips.proto
            'kwhEnd': 38.9, // not in trips.proto
          },
        ],
      });

      final result = await TripsServiceClient(fake).listTrips(ListTripsRequest());

      expect(result.trips, hasLength(1));
      // The declared fields must survive — tolerating unknowns must not mean
      // silently dropping the message.
      expect(result.trips.single.id.toInt(), 42);
      expect(result.trips.single.distanceKm, closeTo(12.5, 1e-9));
    });

    test('GetStatus decodes despite the extra battery fields the daemon emits', () async {
      fake.stubJson('SystemService', 'GetStatus', <String, dynamic>{
        'battery': <String, dynamic>{
          'level': 'NORMAL',
          'voltage': 12.6, // not in system.proto
          'soc': 87, // not in system.proto
          'lastUpdate': '2026-09-13T12:48:00Z', // not in system.proto
        },
      });

      final result = await SystemServiceClient(fake).getStatus(GetStatusRequest());

      expect(result.battery.level, 'NORMAL');
    });

    test('an unknown field nested in a repeated message does not fail the batch', () async {
      // Regression on the specific failure mode: the device error pointed at
      // trips[0], and a throw there discarded trips[1..n] too.
      fake.stubJson('TripsService', 'ListTrips', <String, dynamic>{
        'trips': [
          <String, dynamic>{'id': '1', 'kwhStart': 1.0},
          <String, dynamic>{'id': '2', 'kwhStart': 2.0},
          <String, dynamic>{'id': '3', 'kwhStart': 3.0},
        ],
      });

      final result = await TripsServiceClient(fake).listTrips(ListTripsRequest());

      expect(result.trips.map((t) => t.id.toInt()), [1, 2, 3]);
    });
  });
}
