import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The km→mi conversion was inlined at five call sites and MISSED at a sixth:
/// the Trips → Stats range card rendered `'$km km'` unconditionally, so a user on
/// miles saw their trip rows in `mi` and the range estimate in `km` on the same
/// screen. `trips_range_byd_estimate` made it worse by baking the unit into all
/// 19 translations — `'BYD estimate: {km} km'`, `'Оценка BYD: {km} км'`,
/// `'BYD 估算：{km} 公里'` — so that line could only ever say kilometres.
///
/// These pin the shared formatter that replaced the five copies.
void main() {
  group('formatDistance', () {
    test('kilometres pass through unconverted', () {
      expect(formatDistance(21.0, 'km'), '21.0 km');
      expect(formatDistance(0, 'km'), '0.0 km');
    });

    test('miles are converted, not just relabelled', () {
      // 100 km is ~62.1 mi. A relabel bug would render "100.0 mi".
      expect(formatDistance(100, 'mi'), '62.1 mi');
      expect(formatDistance(21.0, 'mi'), '13.0 mi');
    });

    test('decimals are configurable for the range card', () {
      // The range card shows whole numbers; trip rows show one decimal.
      expect(formatDistance(85.4, 'km', decimals: 0), '85 km');
      expect(formatDistance(100, 'mi', decimals: 0), '62 mi');
    });

    /// The daemon defaults distanceUnit to "km" when its probe fails
    /// (HttpServer). Anything unrecognised must land on kilometres rather than
    /// silently converting.
    test('an unknown unit falls back to kilometres', () {
      for (final u in ['', 'KM', 'imperial', 'nautical']) {
        expect(formatDistance(10, u), '10.0 km', reason: 'unit=$u');
      }
    });
  });

  group('formatSpeed', () {
    test('kilometres per hour pass through', () {
      expect(formatSpeed(88, 'km'), '88 km/h');
    });

    test('miles per hour are converted', () {
      expect(formatSpeed(100, 'mi'), '62 mph');
    });

    test('an unknown unit falls back to km/h', () {
      expect(formatSpeed(50, 'nope'), '50 km/h');
    });
  });

  /// The unit must come from the value, not the sentence. If a translation ever
  /// re-bakes "km" into trips_range_byd_estimate, the miles path silently breaks
  /// again and nothing else would catch it.
  test('kMilesPerKm is the real conversion factor', () {
    expect(kMilesPerKm, closeTo(0.621371, 1e-6));
  });
}
