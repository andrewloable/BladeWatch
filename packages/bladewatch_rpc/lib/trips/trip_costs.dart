import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';

/// What a set of trips cost: fuel, electric and the total (BladeWatch-39d2, -mgi9, -c149). One
/// definition, so the dashboard, the Trips Stats tab and the Period Summary can never disagree.
///
/// Per trip, `tripCost` is the total and `fuelCost` the fuel half. The electric half is the
/// difference rather than `electricCost`, because trips recorded before the fuel leg existed
/// carry only `tripCost` (their `electricCost` is 0). Amounts in different currencies are never
/// added together.
class TripCosts {
  const TripCosts({
    this.fuel = 0,
    this.electric = 0,
    this.total = 0,
    this.currency = '',
    this.hasFuel = false,
    this.mixedCurrencies = false,
  });

  factory TripCosts.of(Iterable<TripSummary> trips) {
    var fuel = 0.0, electric = 0.0, total = 0.0, hasFuel = false;
    final currencies = <String>{};
    for (final t in trips) {
      hasFuel = hasFuel || t.hasFuelData;
      if (t.tripCost <= 0) continue; // no rate configured: nothing was costed
      currencies.add(t.currency);
      fuel += t.fuelCost;
      total += t.tripCost;
      electric += t.tripCost > t.fuelCost ? t.tripCost - t.fuelCost : 0;
    }
    if (currencies.length > 1) return TripCosts(hasFuel: hasFuel, mixedCurrencies: true);
    return TripCosts(
      fuel: fuel,
      electric: electric,
      total: total,
      currency: currencies.isEmpty ? '' : currencies.single,
      hasFuel: hasFuel,
    );
  }

  final double fuel;
  final double electric;
  final double total;

  /// The trips' currency; empty when no trip was costed.
  final String currency;

  /// A trip recorded fuel (a PHEV): the fuel figure means something, even at 0.
  final bool hasFuel;

  /// Costed trips disagree on currency, so no sum is given.
  final bool mixedCurrencies;

  /// There is a sum to show.
  bool get costed => currency.isNotEmpty && !mixedCurrencies;
}

/// Every trip of the last [days], paging past ListTrips' per-call [page] size so a busy period
/// is summed in full rather than cut at the first page. [fetch] is `TripsServiceClient.listTrips`.
/// A short page ends it, as the daemon documents; [maxPages] bounds a misbehaving server.
Future<List<TripSummary>> listTripsInPeriod(
  Future<ListTripsResponse> Function(ListTripsRequest request) fetch,
  int days, {
  int page = 100,
  int maxPages = 50,
}) async {
  final all = <TripSummary>[];
  for (var i = 0; i < maxPages; i++) {
    final trips = (await fetch(ListTripsRequest(days: days, limit: page, offset: i * page))).trips;
    all.addAll(trips);
    if (trips.length < page) break;
  }
  return all;
}
