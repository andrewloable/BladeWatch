import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:flutter_test/flutter_test.dart';

TripSummary trip({double cost = 0, double fuel = 0, double electric = 0, String currency = 'PHP', bool hasFuel = false}) =>
    TripSummary(tripCost: cost, fuelCost: fuel, electricCost: electric, currency: currency, hasFuelData: hasFuel);

void main() {
  group('TripCosts.of', () {
    test('sums fuel, electric and total for one currency', () {
      final c = TripCosts.of([
        trip(cost: 150, fuel: 100, electric: 50, hasFuel: true),
        trip(cost: 30, electric: 30),
      ]);
      expect((c.fuel, c.electric, c.total, c.currency, c.hasFuel, c.costed), (100.0, 80.0, 180.0, 'PHP', true, true));
    });

    test('a trip from before the fuel leg counts its whole cost as electric', () {
      final c = TripCosts.of([trip(cost: 42)]); // electricCost was never recorded
      expect((c.electric, c.total), (42.0, 42.0));
    });

    test('never adds different currencies', () {
      final c = TripCosts.of([trip(cost: 10), trip(cost: 10, currency: 'USD')]);
      expect((c.mixedCurrencies, c.costed, c.total), (true, false, 0.0));
    });

    test('nothing costed: no currency, and still knows about fuel', () {
      final c = TripCosts.of([trip(hasFuel: true), trip()]);
      expect((c.costed, c.currency, c.hasFuel), (false, '', true));
      expect(TripCosts.of(const []).costed, isFalse);
    });

    test('a fuel cost above the total does not go negative on the electric side', () {
      expect(TripCosts.of([trip(cost: 5, fuel: 6)]).electric, 0);
    });
  });

  group('listTripsInPeriod', () {
    test('pages until a short page, asking with offsets', () async {
      final asked = <ListTripsRequest>[];
      Future<ListTripsResponse> fetch(ListTripsRequest r) async {
        asked.add(r);
        final n = r.offset < 4 ? 2 : 1;
        return ListTripsResponse(trips: List.generate(n, (_) => trip()));
      }

      final trips = await listTripsInPeriod(fetch, 30, page: 2);
      expect(trips, hasLength(5));
      expect(asked.map((r) => (r.days, r.limit, r.offset)), [(30, 2, 0), (30, 2, 2), (30, 2, 4)]);
    });

    test('stops at maxPages against a server that never returns a short page', () async {
      var calls = 0;
      Future<ListTripsResponse> fetch(ListTripsRequest r) async {
        calls++;
        return ListTripsResponse(trips: [trip(), trip()]);
      }

      expect(await listTripsInPeriod(fetch, 7, page: 2, maxPages: 3), hasLength(6));
      expect(calls, 3);
    });
  });
}
