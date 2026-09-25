import 'package:bladewatch_ui/screens/vehicle/vehicle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('presetFor', () {
    test('returns null for unknown (-1) or negative values', () {
      expect(presetFor(-1), isNull);
      expect(presetFor(-5), isNull);
    });

    test('closed (0-2%) lights 0%', () {
      expect(presetFor(0), 0);
      expect(presetFor(2), 0);
    });

    // BladeWatch-rm6p: Vent 12% left the windows at 16/15/15/14 and only the first three lit.
    test('a vented window always lights 25%, never nothing and never 0%', () {
      for (final v in [3, 12, 14, 15, 16, 25]) {
        expect(presetFor(v), 25, reason: '$v%');
      }
    });

    test('an open window lights the nearest opening preset, ties to the higher', () {
      expect(presetFor(37), 25);
      expect(presetFor(38), 50);
      expect(presetFor(62), 50);
      expect(presetFor(63), 75);
      expect(presetFor(88), 100);
      expect(presetFor(100), 100);
    });

    // BladeWatch-b3n7: the sunroof and sunshade only have close / half / open.
    test('sun panels offer and light only 0 / 50 / 100', () {
      expect(presetsForArea(4), kWindowPresets);
      expect(presetsForArea(5), [0, 50, 100]);
      expect(presetsForArea(6), [0, 50, 100]);
      expect(presetFor(0, kSunPanelPresets), 0);
      expect(presetFor(20, kSunPanelPresets), 50);
      expect(presetFor(75, kSunPanelPresets), 100);
    });
  });

  group('tyreTier', () {
    test('muted when signalState is nonzero, regardless of psi', () {
      expect(tyreTier(const TyreInfo(psi: 36, signalState: 1)), TyreTier.muted);
    });

    test('muted when psi is null', () {
      expect(tyreTier(const TyreInfo(psi: null)), TyreTier.muted);
    });

    test('alert when airLeakState is at least 1', () {
      expect(tyreTier(const TyreInfo(psi: 36, airLeakState: 1)), TyreTier.alert);
    });

    test('alert when psi is below 22 (flat) even with no leak flag', () {
      expect(tyreTier(const TyreInfo(psi: 21.9)), TyreTier.alert);
    });

    test('warn when pressureState is at least 1 and not alert', () {
      expect(tyreTier(const TyreInfo(psi: 36, pressureState: 1)), TyreTier.warn);
    });

    test('caution when psi is out of the normal range with no hardware flag', () {
      expect(tyreTier(const TyreInfo(psi: 33.9)), TyreTier.caution);
      expect(tyreTier(const TyreInfo(psi: 45.1)), TyreTier.caution);
    });

    test('normal when psi is 34-45 and all sensors are clear', () {
      expect(tyreTier(const TyreInfo(psi: 34)), TyreTier.normal);
      expect(tyreTier(const TyreInfo(psi: 45)), TyreTier.normal);
      expect(tyreTier(const TyreInfo(psi: 36.3)), TyreTier.normal);
    });
  });
}
