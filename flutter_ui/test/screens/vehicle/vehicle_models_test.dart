import 'package:bladewatch_ui/screens/vehicle/vehicle_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeatCapabilities.anyAvailable', () {
    test('false when nothing is available', () {
      expect(const SeatCapabilities().anyAvailable, isFalse);
    });

    test('true when any single capability is available', () {
      expect(const SeatCapabilities(driverHeat: true).anyAvailable, isTrue);
      expect(const SeatCapabilities(passengerHeat: true).anyAvailable, isTrue);
      expect(const SeatCapabilities(driverCool: true).anyAvailable, isTrue);
      expect(const SeatCapabilities(passengerCool: true).anyAvailable, isTrue);
      expect(const SeatCapabilities(driverMemoryRecall: true).anyAvailable, isTrue);
    });
  });

  group('presetFor', () {
    test('returns null for unknown (-1) or negative values', () {
      expect(presetFor(-1), isNull);
      expect(presetFor(-5), isNull);
    });

    test('snaps to the nearest preset within +/-10', () {
      expect(presetFor(0), 0);
      expect(presetFor(5), 0);
      expect(presetFor(10), 0);
      expect(presetFor(25), 25);
      expect(presetFor(50), 50);
      expect(presetFor(75), 75);
      expect(presetFor(90), 100);
      expect(presetFor(100), 100);
    });

    test('returns null when farther than 10 from every preset', () {
      expect(presetFor(12), isNull);
      expect(presetFor(38), isNull);
      expect(presetFor(62), isNull);
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
