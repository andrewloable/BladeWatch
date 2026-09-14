import 'package:bladewatch_ui/widgets/storage_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatStorageMb', () {
    test('shows whole megabytes below 1 GB', () {
      expect(formatStorageMb(100), '100 MB');
      expect(formatStorageMb(1023), '1023 MB');
    });

    test('switches to one decimal of GB at exactly 1024 MB, as native does', () {
      expect(formatStorageMb(1024), '1.0 GB');
      expect(formatStorageMb(1536), '1.5 GB');
      expect(formatStorageMb(16384), '16.0 GB');
    });

    test('rounds to one decimal rather than truncating', () {
      expect(formatStorageMb(1587), '1.5 GB');
      expect(formatStorageMb(1638), '1.6 GB');
    });
  });

  group('storageSliderDivisions', () {
    test('is one notch per 100 MB', () {
      expect(storageSliderDivisions(100, 1100), 10);
      expect(storageSliderDivisions(0, 6400), 64);
    });

    test('never returns zero, which would throw in Slider', () {
      // Native guards the same case with coerceAtLeast(1).
      expect(storageSliderDivisions(100, 100), 1);
      expect(storageSliderDivisions(100, 150), 1);
      expect(storageSliderDivisions(500, 100), 1);
    });
  });

  group('snapStorageMb', () {
    test('lands on whole 100 MB steps measured from the minimum', () {
      expect(snapStorageMb(3847, 100, 64000), 3800);
      expect(snapStorageMb(3860, 100, 64000), 3900);
    });

    test('steps are offset from min, not from zero', () {
      // min 150 means the reachable values are 150, 250, 350 … — matching
      // native's `minMb + progress * 100`.
      expect(snapStorageMb(200, 150, 5000), 250);
      expect(snapStorageMb(160, 150, 5000), 150);
    });

    test('clamps to the range', () {
      expect(snapStorageMb(0, 100, 5000), 100);
      expect(snapStorageMb(999999, 100, 5000), 5000);
    });

    test('a degenerate range collapses to the minimum instead of throwing', () {
      expect(snapStorageMb(500, 1000, 1000), 1000);
      expect(snapStorageMb(500, 1000, 200), 1000);
    });
  });
}
