/**
 * Whether the PHEV fuel settings belong on screen for this vehicle.
 *
 * A BEV has no tank, so a fuel price and a tank capacity are not merely unused there — a car
 * with no tank offering "Fuel Tank Capacity (litres)" reads as a bug in the app.
 *
 * Deliberately NOT a bare `isPhev`. Two reasons the flag alone is wrong:
 *
 *  - `isPhev` is a LIVE drivetrain read, and the probe returns false while the HAL is warming
 *    up. A PHEV owner must never open settings to find the fuel price gone.
 *  - A value that is already configured is still being APPLIED. Hiding the field that holds it
 *    leaves the owner unable to clear it from anywhere in the UI.
 *
 * So an already-configured figure keeps the fields visible regardless of the probe — the same
 * principle as keeping a legacy currency code in the picker so it can be changed.
 *
 * Extracted from `TripsComponent` so it can be unit-tested: as a `computed()` on the component
 * it was reachable only through Angular's DI, and vitest deliberately runs without the Angular
 * compiler (see vitest.config.ts).
 *
 * @param isPhev live drivetrain read from `TripConfig.isPhev`
 * @param fuelPricePerL configured fuel price; anything unparseable counts as not configured
 * @param fuelTankCapacityL configured tank size; same
 */
export function showFuelSettings(
  isPhev: boolean,
  fuelPricePerL: string | number | null | undefined,
  fuelTankCapacityL: string | number | null | undefined,
): boolean {
  return isPhev || isConfigured(fuelPricePerL) || isConfigured(fuelTankCapacityL);
}

/** A settings figure counts as configured only when it parses to a positive number. */
function isConfigured(value: string | number | null | undefined): boolean {
  const n = typeof value === 'number' ? value : Number.parseFloat(value ?? '');
  return Number.isFinite(n) && n > 0;
}
