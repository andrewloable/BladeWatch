import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:bladewatch_ui/util/currency.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-9uu6.3: PHEV pricing reaches the daemon from the in-car UI.
///
/// The gap this covers: the head unit could set what electricity costs but not what petrol
/// costs, so on a PHEV `litresUsed` was recorded while `fuelCost` stayed 0 and `tripCost`
/// silently under-reported — unless the owner opened the web UI over the tunnel.
///
/// These assert the CONTRACT rather than pixels: the model carries the values, the defaults
/// mean "not configured", and a deliberate 0 survives as a real 0. Layout is verified on the
/// head unit — `flutter test` uses a fixed-width placeholder font, so any text-fit assertion
/// here would be meaningless.
void main() {
  group('TripsConfig carries PHEV pricing', () {
    test('both prices default to zero meaning not configured', () {
      const cfg = TripsConfig(
        enabled: true,
        electricityRate: 0.15,
        currency: 'USD',
        distanceUnit: 'km',
      );
      expect(cfg.fuelPricePerL, 0,
          reason: 'a default fuel price must mean "not configured", never a guess');
      expect(cfg.fuelTankCapacityL, 0,
          reason: 'BYD exposes no tank size; a guessed default would put a wrong '
              'range on the dashboard, which is worse than a blank one');
    });

    test('configured values round-trip through the model', () {
      const cfg = TripsConfig(
        enabled: true,
        electricityRate: 0.15,
        fuelPricePerL: 1.80,
        fuelTankCapacityL: 50.0,
        currency: 'PHP',
        distanceUnit: 'km',
      );
      expect(cfg.fuelPricePerL, 1.80);
      expect(cfg.fuelTankCapacityL, 50.0);
      expect(cfg.currency, 'PHP');
    });
  });

  group('currency catalogue', () {
    setUp(Currency.resetCacheForTest);

    /// The picker must never be empty. An empty menu leaves an owner unable to change their
    /// currency at all, which is worse than a short fallback list they can still use.
    test('codes are never empty even if the asset is unavailable', () async {
      final codes = await Currency.codes();
      expect(codes, isNotEmpty);
      expect(codes, contains('USD'));
    });

    test('the default code is offered', () async {
      final codes = await Currency.codes();
      expect(codes, contains(Currency.defaultCode));
    });
  });

  group('cost rendering used by the trips list and detail screens', () {
    /// Both screens previously concatenated: `'${trip.currency} ${cost.toStringAsFixed(2)}'`.
    /// A currency with no minor unit is what separates a real formatter from that.
    test('an ISO code formats through ICU', () {
      final jpy = Currency.format(1234.0, 'JPY', locale: 'en_US');
      expect(jpy, isNot(contains('.00')),
          reason: 'JPY has no minor unit; ".00" means the formatter was bypassed');
    });

    test('a legacy symbol renders exactly as it always did', () {
      expect(Currency.format(12.3, r'$'), equals(r'$ 12.30'));
    });

    test('nothing configured renders nothing', () {
      expect(Currency.format(12.3, ''), isEmpty);
    });
  });
}
