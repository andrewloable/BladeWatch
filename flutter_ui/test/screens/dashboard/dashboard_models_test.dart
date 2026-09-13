import 'package:bladewatch_ui/screens/dashboard/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripStatsState.distanceLabel', () {
    test('one decimal place below 1000km', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 1, totalDistanceKm: 9.0, totalDurationSeconds: 0);
      expect(s.distanceLabel, '9.0 km');
    });

    test('no decimal place at or above 1000km', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 1, totalDistanceKm: 1000.4, totalDurationSeconds: 0);
      expect(s.distanceLabel, '1000 km');
    });

    test('boundary: exactly 1000km uses no decimal', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 1, totalDistanceKm: 1000, totalDurationSeconds: 0);
      expect(s.distanceLabel, '1000 km');
    });
  });

  group('TripStatsState.driveTimeLabel', () {
    test('minutes only when under an hour', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 1, totalDistanceKm: 0, totalDurationSeconds: 47 * 60);
      expect(s.driveTimeLabel, '47m');
    });

    test('hours and minutes when an hour or more', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 1, totalDistanceKm: 0, totalDurationSeconds: 3661);
      expect(s.driveTimeLabel, '1h 1m');
    });

    test('zero seconds', () {
      const s = TripStatsState(loading: false, available: true, tripCount: 0, totalDistanceKm: 0, totalDurationSeconds: 0);
      expect(s.driveTimeLabel, '0m');
    });
  });

  test('TripStatsState.loading() is the loading sentinel', () {
    const s = TripStatsState.loading();
    expect(s.loading, isTrue);
    expect(s.available, isFalse);
  });

  test('TripStatsState.unavailable() is the unavailable sentinel', () {
    const s = TripStatsState.unavailable();
    expect(s.loading, isFalse);
    expect(s.available, isFalse);
  });

  test('RecordingsMetricState.loading() sentinel', () {
    const s = RecordingsMetricState.loading();
    expect(s.loading, isTrue);
    expect(s.todayCount, 0);
    expect(s.isRecording, isFalse);
  });

  test('DaemonsSummaryState.loading() sentinel', () {
    const s = DaemonsSummaryState.loading();
    expect(s.loading, isTrue);
    expect(s.running, 0);
    expect(s.total, 0);
  });

  test('TunnelState.loading() sentinel', () {
    const s = TunnelState.loading();
    expect(s.phase, TunnelPhase.offline);
    expect(s.url, isNull);
  });

  group('VehicleTileState', () {
    test('loading() sentinel', () {
      const s = VehicleTileState.loading();
      expect(s.loading, isTrue);
      expect(s.hasCapacity, isFalse);
    });

    test('hasCapacity is true only when nominalKwh is positive', () {
      const withCapacity = VehicleTileState(loading: false, nominalKwh: 82.5);
      const withoutCapacity = VehicleTileState(loading: false, nominalKwh: 0);
      expect(withCapacity.hasCapacity, isTrue);
      expect(withoutCapacity.hasCapacity, isFalse);
    });
  });

  group('AccessCodeState', () {
    test('loading() sentinel', () {
      const s = AccessCodeState.loading();
      expect(s.loading, isTrue);
      expect(s.displayValue, isNull);
    });

    test('displayValue is null when not visible, even with a secret', () {
      const s = AccessCodeState(loading: false, secret: 'shh-fake-secret', visible: false);
      expect(s.displayValue, isNull);
    });

    test('displayValue is the secret when visible', () {
      const s = AccessCodeState(loading: false, secret: 'shh-fake-secret', visible: true);
      expect(s.displayValue, 'shh-fake-secret');
    });
  });

  group('modelDisplayName', () {
    test('null id renders an em dash', () {
      expect(modelDisplayName(null), '—');
    });

    test('known ids map to their brand name', () {
      expect(modelDisplayName('seal'), 'BYD Seal');
      expect(modelDisplayName('seal5-dmi-premium'), 'BYD Seal 5 DM-i Premium');
    });

    test('lookup is case-insensitive', () {
      expect(modelDisplayName('SEAL'), 'BYD Seal');
    });

    test('the two spellings of Atto 3 both resolve', () {
      expect(modelDisplayName('atto3'), 'BYD Atto 3');
      expect(modelDisplayName('atto-3'), 'BYD Atto 3');
    });

    test('unrecognized id falls back to title case', () {
      expect(modelDisplayName('mystery-car'), 'Mystery-car');
    });

    test('empty string falls back to itself unchanged', () {
      expect(modelDisplayName(''), '');
    });
  });
}
