/// What is left in the pack or the tank: "77% / 14.1 kWh", or just "77%" while its [size] is unknown
/// (0). One function, so the in-car dashboard and the companion read the same.
///
/// [size] is the pack's nominal kWh (`GetSohNominal`) or the tank's litres (the trip config's
/// `fuelTankCapacityL`, which the owner sets: BYD exposes no tank size).
///
/// [space] goes inside "78% /" and "14.3 kWh". The companion passes a no-break space, so a narrow
/// row wraps only after the slash, never leaving "kWh" alone on a line; the in-car stat cell keeps
/// the plain space, because it finds the unit by the last one.
// ponytail: percent x nominal size, so the amount ignores battery health and BYD's reserve.
String energyLeft(double percent, double size, String unit, {int decimals = 0, String space = ' '}) => size > 0
    ? '${percent.round()}%$space/ ${(percent / 100 * size).toStringAsFixed(decimals)}$space$unit'
    : '${percent.round()}%';
