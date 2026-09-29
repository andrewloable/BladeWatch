import 'package:bladewatch_rpc/trips/trip_costs.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../util/currency.dart';

/// What a cost block shows (BladeWatch-39d2, -mgi9, -c149): the figures as (value, label), or,
/// when there are none to show, the one line that says why. Each screen draws the figures in
/// its own stat style; what they say is decided here once.
///
/// Fuel is left out on a car that recorded no fuel (a BEV) rather than shown as 0.
({List<(String, String)> figures, String? message}) tripCostDisplay(TripCosts c, AppLocalizations l10n) {
  if (c.mixedCurrencies) return (figures: const [], message: l10n.trips_cost_mixed_currency);
  if (!c.costed) return (figures: const [], message: l10n.trips_cost_no_rate);
  return (
    figures: [
      if (c.hasFuel) (Currency.format(c.fuel, c.currency), l10n.trips_detail_fuel_cost),
      (Currency.format(c.electric, c.currency), l10n.trips_detail_electric_cost),
      (Currency.format(c.total, c.currency), l10n.trips_cost_total),
    ],
    message: null,
  );
}
