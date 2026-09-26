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

  group('VehicleDialogState', () {
    test('loading() sentinel', () {
      // Deliberately NOT `const`: a const invocation is folded at compile time
      // and the constructor body never runs, so it would look covered without
      // ever executing.
      final s = VehicleDialogState.loading();
      expect(s.loading, isTrue);
      expect(s.models, isEmpty);
      expect(s.selectedModelId, isNull);
    });

    test('copyWith replaces only what it is given', () {
      final base = VehicleDialogState(
        loading: false,
        models: const [VehicleModelEntry(id: 'seal', title: 'BYD Seal', nominalKwh: 82.5)],
        selectedModelId: null,
      );

      final picked = base.copyWith(selectedModelId: 'seal');

      expect(picked.selectedModelId, 'seal');
      expect(picked.loading, isFalse);
      expect(picked.models, base.models);
    });

    test('copyWith keeps the existing selection when not given one', () {
      final base = VehicleDialogState(loading: false, models: const [], selectedModelId: 'seal');

      final reloaded = base.copyWith(loading: true);

      expect(reloaded.loading, isTrue);
      expect(reloaded.selectedModelId, 'seal');
    });
  });

  group('VehicleTileState', () {
    test('loading() sentinel', () {
      const s = VehicleTileState.loading();
      expect(s.loading, isTrue);
      expect(s.hasModel, isFalse);
    });

    // BladeWatch-p7vi: the tile tracks the selected MODEL now. It used to track
    // nominal capacity, which the daemon can no longer supply at all.
    test('hasModel is true only when a model id is actually set', () {
      const withModel = VehicleTileState(loading: false, modelId: 'seal');
      const noModel = VehicleTileState(loading: false);
      const emptyModel = VehicleTileState(loading: false, modelId: '');
      expect(withModel.hasModel, isTrue);
      expect(noModel.hasModel, isFalse);
      expect(emptyModel.hasModel, isFalse, reason: 'an empty id is not a selection');
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
