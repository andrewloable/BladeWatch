import 'package:bladewatch_rpc/trips/energy_left.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a known size adds the amount left', () {
    expect(energyLeft(77, 18.3, 'kWh', decimals: 1), '77% / 14.1 kWh');
    expect(energyLeft(30, 48, 'L'), '30% / 14 L');
  });

  test('a no-break space leaves the slash as the only place to wrap', () {
    expect(energyLeft(77, 18.3, 'kWh', decimals: 1, space: ' '), '77% / 14.1 kWh');
  });

  test('an unknown size shows the percentage alone, never a fabricated amount', () {
    expect(energyLeft(77, 0, 'kWh', decimals: 1), '77%');
  });
}
