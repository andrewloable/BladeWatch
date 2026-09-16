package net.bladewatch.app.byd

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Tests for [BydSignalRules] — the decision rules extracted from `BydDataCollector`.
 *
 * These rules were previously inlined among reflection calls and could not be tested at all:
 * exercising one range check meant standing up a BYD HAL device. They encode specific firmware
 * facts (dual scales, CAN sentinels, physical envelopes) where a transposed digit silently
 * corrupts vehicle telemetry, so the emphasis throughout is on BOUNDARIES and on the cases
 * where two plausible readings must be told apart.
 */
class BydSignalRulesTest {

    private companion object { const val EPS = 1e-9 }

    // ── fuel sentinels ───────────────────────────────────────────────────────────

    /**
     * The sentinel set is CAN all-ones at several widths. Testing the whole set matters
     * because missing one makes a BEV look like a PHEV with a real fuel reading.
     */
    @Test
    fun `every can all-ones width is a sentinel`() {
        for (v in listOf(255, 254, 511, 1023, 2046, 2047, 4095, 65534, 65535)) {
            assertTrue("$v must be a sentinel", BydSignalRules.isBevFuelSentinel(v))
        }
    }

    @Test
    fun `real fuel readings are not sentinels`() {
        for (v in listOf(0, 1, 50, 100, 253, 256, 512, 1024, 2045, 4094)) {
            assertFalse("$v must not be a sentinel", BydSignalRules.isBevFuelSentinel(v))
        }
    }

    // ── 12V ──────────────────────────────────────────────────────────────────────

    /**
     * The getter is dual-scale. A reading above 100 can only be decivolts, because no 12V
     * system reads 100V — that is the entire discriminator.
     */
    @Test
    fun `12V reading is descaled only above the decivolt threshold`() {
        assertEquals("126 decivolts is 12.6V", 12.6, BydSignalRules.scale12vVoltage(126.0)!!, EPS)
        assertEquals("12.6 is already volts", 12.6, BydSignalRules.scale12vVoltage(12.6)!!, EPS)
    }

    /**
     * The 8-16V window is the physical envelope of a lead-acid bus. This reading gates
     * ACC-off sentry shutdown, so accepting garbage strands the car.
     */
    @Test
    fun `12V window is inclusive at both ends and rejects outside`() {
        assertEquals(8.0, BydSignalRules.scale12vVoltage(8.0)!!, EPS)
        assertEquals(16.0, BydSignalRules.scale12vVoltage(16.0)!!, EPS)
        assertNull("below cranking voltage", BydSignalRules.scale12vVoltage(7.9))
        assertNull("above alternator ceiling", BydSignalRules.scale12vVoltage(16.1))
        assertNull("zero is not a reading", BydSignalRules.scale12vVoltage(0.0))
        assertNull(BydSignalRules.scale12vVoltage(Double.NaN))
    }

    /** 255 is the top of the decivolt scale: 25.5V, which is still out of range. */
    @Test
    fun `a full-scale decivolt reading still fails the plausibility window`() {
        assertNull(BydSignalRules.scale12vVoltage(255.0))
    }

    // ── cell temperature ─────────────────────────────────────────────────────────

    /** BYD encodes cell temperature with a +40 offset so the wire value stays unsigned. */
    @Test
    fun `cell temperature applies the forty degree offset`() {
        assertEquals("raw 0 is -40C", -40.0, BydSignalRules.cellTempC(0)!!, EPS)
        assertEquals("raw 40 is 0C", 0.0, BydSignalRules.cellTempC(40)!!, EPS)
        assertEquals("raw 65 is 25C", 25.0, BydSignalRules.cellTempC(65)!!, EPS)
        assertEquals("raw 120 is 80C", 80.0, BydSignalRules.cellTempC(120)!!, EPS)
    }

    @Test
    fun `cell temperature rejects outside the representable range`() {
        assertNull(BydSignalRules.cellTempC(-1))
        assertNull(BydSignalRules.cellTempC(121))
        assertNull(BydSignalRules.cellTempC(BydSignalRules.NO_VALUE))
    }

    /**
     * A sentinel must not be offset into a plausible-looking temperature. This is the failure
     * that would put a fictional reading on the dashboard rather than showing nothing.
     */
    @Test
    fun `cell temperature rejects sentinels rather than offsetting them`() {
        assertNull(BydSignalRules.cellTempC(BydFeatureIds.BMS_UNAVAILABLE))
        assertNull(BydSignalRules.cellTempC(BydFeatureIds.INVALID_VALUE))
        assertNull(BydSignalRules.cellTempC(BydFeatureIds.INVALID_VALUE_2))
    }

    // ── cell voltage ─────────────────────────────────────────────────────────────

    /** Millivolts to volts, bracketed by the chemistries BYD actually ships. */
    @Test
    fun `cell voltage converts millivolts and brackets real chemistries`() {
        assertEquals("LFP resting", 3.2, BydSignalRules.cellVoltage(3200)!!, EPS)
        assertEquals("LFP full", 3.65, BydSignalRules.cellVoltage(3650)!!, EPS)
        assertEquals("NMC full", 4.2, BydSignalRules.cellVoltage(4200)!!, EPS)
    }

    @Test
    fun `cell voltage window is inclusive at both ends`() {
        assertEquals(1.0, BydSignalRules.cellVoltage(1000)!!, EPS)
        assertEquals(5.0, BydSignalRules.cellVoltage(5000)!!, EPS)
        assertNull(BydSignalRules.cellVoltage(999))
        assertNull(BydSignalRules.cellVoltage(5001))
    }

    /** A pack-level voltage must not be mistaken for a cell reading. */
    @Test
    fun `cell voltage rejects pack voltages zero and sentinels`() {
        assertNull("a 400V pack reading is not a cell", BydSignalRules.cellVoltage(400_000))
        assertNull(BydSignalRules.cellVoltage(0))
        assertNull(BydSignalRules.cellVoltage(-100))
        assertNull(BydSignalRules.cellVoltage(BydFeatureIds.BMS_UNAVAILABLE))
    }

    // ── engine power ─────────────────────────────────────────────────────────────

    /**
     * The SIGN is load-bearing: negative means current into the pack, which is what
     * ChargingDetector relies on for PHEVs whose BMS reports a stuck IDLE.
     */
    @Test
    fun `engine power preserves the sign convention`() {
        assertTrue("motor draw is positive", BydSignalRules.enginePowerKw(45.0)!! > 0)
        assertTrue("charging is negative", BydSignalRules.enginePowerKw(-3.5)!! < 0)
        assertEquals(-3.5, BydSignalRules.enginePowerKw(-3.5)!!, EPS)
    }

    @Test
    fun `engine power descales only above the deciwatt threshold`() {
        assertEquals("150 deciwatts is 15 kW", 15.0, BydSignalRules.enginePowerKw(150.0)!!, EPS)
        assertEquals("100 is at the boundary, not descaled", 100.0, BydSignalRules.enginePowerKw(100.0)!!, EPS)
        assertEquals("negative descales too", -15.0, BydSignalRules.enginePowerKw(-150.0)!!, EPS)
    }

    /**
     * The plausibility window is applied to the RAW value, BEFORE descaling — so a reading of
     * 1500 is rejected outright rather than becoming a perfectly plausible 150 kW.
     *
     * That ordering produces a genuine discontinuity: raw 100 yields 100 kW, raw 101 yields
     * 10.1 kW. It is carried over from the Java original unchanged and is pinned here because
     * it is exactly the kind of thing a later "tidy-up" would silently reorder, changing what
     * every engine-power reading means. If it is ever revisited, it should be a deliberate
     * decision with the car in front of you, not a refactor.
     */
    @Test
    fun `the plausibility window applies to the raw value before descaling`() {
        assertNull("1500 raw is rejected, not descaled to 150 kW",
            BydSignalRules.enginePowerKw(1500.0))
        assertEquals("raw 100 stays 100", 100.0, BydSignalRules.enginePowerKw(100.0)!!, EPS)
        assertEquals("raw 101 drops to 10.1", 10.1, BydSignalRules.enginePowerKw(101.0)!!, 1e-9)
    }

    @Test
    fun `engine power window is inclusive at both ends`() {
        assertNotNull(BydSignalRules.enginePowerKw(-200.0))
        assertNotNull(BydSignalRules.enginePowerKw(400.0))
        assertNull(BydSignalRules.enginePowerKw(-200.1))
        assertNull(BydSignalRules.enginePowerKw(400.1))
        assertNull(BydSignalRules.enginePowerKw(Double.NaN))
    }

    // ── external charging power ──────────────────────────────────────────────────

    /**
     * THE case this rule exists for: 221.7 raw from a Seal U DM-i is a real ~2.2 kW handshake
     * in hectowatts, not a 221 kW charger, which does not exist on AC.
     */
    @Test
    fun `hectowatt firmware reading is descaled to a real charger rate`() {
        assertEquals(2.217, BydSignalRules.externalChargingPowerKw(221.7)!!, 1e-6)
        assertEquals(1.895, BydSignalRules.externalChargingPowerKw(189.5)!!, 1e-6)
    }

    /** Below the threshold the value is already kW and must pass through untouched. */
    @Test
    fun `kW firmware reading passes through unscaled`() {
        assertEquals(7.0, BydSignalRules.externalChargingPowerKw(7.0)!!, EPS)
        assertEquals("50 is the boundary, still kW", 50.0, BydSignalRules.externalChargingPowerKw(50.0)!!, EPS)
    }

    /** BYD's 104857.5 sentinel must be rejected, never divided into a plausible number. */
    @Test
    fun `the BYD sentinel is rejected rather than descaled`() {
        assertNull("104857.5/100 would look like a valid 1048 kW",
            BydSignalRules.externalChargingPowerKw(104857.5))
    }

    @Test
    fun `external charging power rejects zero and negatives`() {
        assertNull(BydSignalRules.externalChargingPowerKw(0.0))
        assertNull(BydSignalRules.externalChargingPowerKw(0.1))
        assertNull(BydSignalRules.externalChargingPowerKw(-5.0))
    }

    @Test
    fun `scale discriminator agrees with the conversion`() {
        assertTrue(BydSignalRules.isHectowattScale(221.7))
        assertFalse(BydSignalRules.isHectowattScale(7.0))
        assertFalse("the sentinel is above the cap", BydSignalRules.isHectowattScale(104857.5))
    }

    // ── remaining energy ─────────────────────────────────────────────────────────

    /**
     * The real regression this guards: on Seal, 16.5 kWh at 20% SoC implies 82.5 kWh (correct)
     * while 20.6 kWh implies 103 kWh (wrong), and the wrong one poisoned auto-detection.
     * Both are inside the 10-130 envelope, so this check alone does NOT separate them — it
     * rejects the genuinely impossible, and the collector's source priority handles the rest.
     */
    @Test
    fun `remaining kwh is validated against implied pack capacity`() {
        assertTrue("16.5 kWh at 20% implies 82.5 kWh",
            BydSignalRules.isRemainKwhConsistentWithSoc(16.5, 20.0))
        assertFalse("2 kWh at 80% implies 2.5 kWh, no such pack",
            BydSignalRules.isRemainKwhConsistentWithSoc(2.0, 80.0))
        assertFalse("100 kWh at 50% implies 200 kWh, no such pack",
            BydSignalRules.isRemainKwhConsistentWithSoc(100.0, 50.0))
    }

    /**
     * Below 5% SoC the division amplifies noise without bound, so it cannot validate anything
     * and must decline rather than produce a confident wrong answer.
     */
    @Test
    fun `low soc cannot validate and declines`() {
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(20.0, 5.0))
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(20.0, 1.0))
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(20.0, 0.0))
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(Double.NaN, 50.0))
    }

    @Test
    fun `implied capacity window is inclusive at both ends`() {
        // 10 kWh implied at 100% SoC.
        assertTrue(BydSignalRules.isRemainKwhConsistentWithSoc(10.0, 100.0))
        // 130 kWh implied at 100% SoC.
        assertTrue(BydSignalRules.isRemainKwhConsistentWithSoc(130.0, 100.0))
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(9.9, 100.0))
        assertFalse(BydSignalRules.isRemainKwhConsistentWithSoc(130.1, 100.0))
    }

    /**
     * The last-resort tier: when nothing else wrote a remaining-energy value this cycle, the
     * `getBatteryCapacity` reading is descaled by 10 and used directly. Nothing cross-checks it
     * against SoC at that point, so this bare window is the ONLY thing standing between a junk
     * HAL reading and a remaining-energy figure the range estimator will trust.
     *
     * The upper bound is the half that matters. A stuck or wrongly-scaled counter reads HIGH,
     * and 120 kWh is above every BYD pack, so a value past it is definitionally junk.
     */
    @Test
    fun `remaining energy outside the plausible window is rejected`() {
        assertTrue(BydSignalRules.isPlausibleRemainKwh(60.0))
        assertTrue("just inside the lower bound", BydSignalRules.isPlausibleRemainKwh(1.1))
        assertTrue("just inside the upper bound", BydSignalRules.isPlausibleRemainKwh(119.9))

        // Exclusive at both ends.
        assertFalse(BydSignalRules.isPlausibleRemainKwh(1.0))
        assertFalse(BydSignalRules.isPlausibleRemainKwh(120.0))

        // A wrongly-scaled counter reads high; this is what the upper bound exists to stop.
        assertFalse("10x scale error", BydSignalRules.isPlausibleRemainKwh(600.0))
        assertFalse(BydSignalRules.isPlausibleRemainKwh(120.1))

        // Nothing usable.
        assertFalse(BydSignalRules.isPlausibleRemainKwh(0.0))
        assertFalse(BydSignalRules.isPlausibleRemainKwh(-5.0))
        assertFalse(BydSignalRules.isPlausibleRemainKwh(Double.NaN))
    }

    /**
     * `getBatteryCapacity` means different things on different models. Confusing a fixed Ah
     * rating for remaining energy writes an Ah number scaled by 10 into a kWh field.
     */
    @Test
    fun `a fixed Ah rating is distinguished from remaining energy`() {
        assertTrue("Atto 3 is 150 Ah", BydSignalRules.looksLikeAhRating(150.0))
        assertTrue(BydSignalRules.looksLikeAhRating(50.0))
        assertTrue(BydSignalRules.looksLikeAhRating(350.0))
        assertFalse("400 in 0.1 kWh units is 40 kWh remaining",
            BydSignalRules.looksLikeAhRating(400.0))
        assertFalse(BydSignalRules.looksLikeAhRating(49.9))
    }

    // ── charging state ───────────────────────────────────────────────────────────

    /**
     * IDLE(15) must NOT be terminal. It is the buggy reading some PHEV firmwares give WHILE
     * CHARGING, and treating it as terminal is what broke charge detection on those cars.
     */
    @Test
    fun `idle is not a terminal charging state`() {
        assertFalse("15=IDLE is the PHEV firmware bug", BydSignalRules.isTerminalChargingState(15))
        assertFalse("1=CHARGING is obviously not terminal", BydSignalRules.isTerminalChargingState(1))
    }

    @Test
    fun `explicit end-of-session states are terminal`() {
        for (s in listOf(0, 2, 4, 12)) {
            assertTrue("$s must be terminal", BydSignalRules.isTerminalChargingState(s))
        }
    }

    @Test
    fun `connected gun states are recognised`() {
        for (s in listOf(2, 3, 4, 5)) {
            assertTrue("$s must read as connected", BydSignalRules.isChargingGunConnected(s))
        }
        assertFalse("1 is disconnected", BydSignalRules.isChargingGunConnected(1))
        assertFalse("0 is not an assertion", BydSignalRules.isChargingGunConnected(0))
    }

    /**
     * Deliberately permissive. A false positive costs one HAL read; a false negative loses the
     * only reliable charging signal on a PHEV whose gun state is UNAVAILABLE and whose BMS is
     * stuck at IDLE.
     */
    @Test
    fun `parked charging is detected from any single sufficient signal`() {
        val no = Double.NaN
        assertTrue("charging power alone",
            BydSignalRules.possiblyChargingWhileParked(2.0, no, 15, 0))
        assertTrue("external power alone",
            BydSignalRules.possiblyChargingWhileParked(no, 1.9, 15, 0))
        assertTrue("BMS says charging",
            BydSignalRules.possiblyChargingWhileParked(no, no, 1, 0))
        assertTrue("gun connected alone",
            BydSignalRules.possiblyChargingWhileParked(no, no, 15, 3))
    }

    @Test
    fun `parked and idle with no signal is not charging`() {
        val no = Double.NaN
        assertFalse(BydSignalRules.possiblyChargingWhileParked(no, no, 15, 1))
        assertFalse("noise below the deadband does not count",
            BydSignalRules.possiblyChargingWhileParked(0.05, no, 15, 1))
    }

    /** Negative charging power still indicates activity — magnitude is what matters. */
    @Test
    fun `negative charging power still indicates activity`() {
        assertTrue(BydSignalRules.possiblyChargingWhileParked(-2.0, Double.NaN, 15, 1))
    }

    @Test
    fun `vtol is asserted by either gun state or charging type`() {
        assertTrue(BydSignalRules.isVtolCharging(5, 0))
        assertTrue(BydSignalRules.isVtolCharging(0, 3))
        assertFalse(BydSignalRules.isVtolCharging(2, 0))
    }

    // ── door locks ───────────────────────────────────────────────────────────────

    /**
     * THE inversion. SDK 1=unlock/2=lock; the web API is 1=locked/2=unlocked. Getting this
     * backwards reports the car as locked when it is standing open — the single most
     * consequential one-line error in this file.
     */
    @Test
    fun `sdk and api lock semantics are inverted`() {
        assertEquals("SDK lock(2) becomes API locked(1)",
            BydSignalRules.LOCK_API_LOCKED, BydSignalRules.lockSdkToApi(BydSignalRules.LOCK_SDK_LOCKED))
        assertEquals("SDK unlock(1) becomes API unlocked(2)",
            BydSignalRules.LOCK_API_UNLOCKED, BydSignalRules.lockSdkToApi(BydSignalRules.LOCK_SDK_UNLOCKED))
    }

    @Test
    fun `lock conversion is not the identity`() {
        assertTrue("if this passes as identity the inversion was dropped",
            BydSignalRules.lockSdkToApi(BydSignalRules.LOCK_SDK_LOCKED) != BydSignalRules.LOCK_SDK_LOCKED)
    }

    @Test
    fun `invalid and unexpected lock states are unknown`() {
        assertEquals(BydSignalRules.LOCK_API_UNKNOWN,
            BydSignalRules.lockSdkToApi(BydSignalRules.LOCK_SDK_INVALID))
        assertEquals(BydSignalRules.LOCK_API_UNKNOWN, BydSignalRules.lockSdkToApi(99))
        assertEquals(BydSignalRules.LOCK_API_UNKNOWN, BydSignalRules.lockSdkToApi(-1))
    }

    // ── overall lock aggregation ─────────────────────────────────────────────────

    private fun locks(vararg v: Int) = v

    /** All four locked is the only way to reach LOCKED. */
    @Test
    fun `all doors locked aggregates to locked`() {
        val L = BydSignalRules.LOCK_API_LOCKED
        assertEquals(L, BydSignalRules.deriveOverallLock(locks(L, L, L, L)))
    }

    /**
     * One open door makes the car open, whatever the others say — including when the others
     * are unknown. Reporting anything else would be reporting the car secure when it is not.
     */
    @Test
    fun `any unlocked door makes the car unlocked`() {
        val L = BydSignalRules.LOCK_API_LOCKED
        val U = BydSignalRules.LOCK_API_UNLOCKED
        val X = BydSignalRules.LOCK_API_UNKNOWN
        assertEquals(U, BydSignalRules.deriveOverallLock(locks(U, L, L, L)))
        assertEquals(U, BydSignalRules.deriveOverallLock(locks(L, L, L, U)))
        assertEquals("unlocked beats unknown", U, BydSignalRules.deriveOverallLock(locks(U, X, X, X)))
    }

    /**
     * THE asymmetry. A single unknown door must yield UNKNOWN, never LOCKED — surveillance
     * arming keys off this, so a false LOCKED would arm a sentry on a car standing open.
     * A false UNKNOWN merely declines to act.
     */
    @Test
    fun `one unknown door never aggregates to locked`() {
        val L = BydSignalRules.LOCK_API_LOCKED
        val X = BydSignalRules.LOCK_API_UNKNOWN
        assertEquals("three locked plus one unknown is NOT locked",
            X, BydSignalRules.deriveOverallLock(locks(L, L, L, X)))
        assertEquals(X, BydSignalRules.deriveOverallLock(locks(X, L, L, L)))
        assertEquals(X, BydSignalRules.deriveOverallLock(locks(X, X, X, X)))
    }

    /** Only the four doors count; trailing entries (all-area, aggregate) are not doors. */
    @Test
    fun `only the first four entries participate`() {
        val L = BydSignalRules.LOCK_API_LOCKED
        val U = BydSignalRules.LOCK_API_UNLOCKED
        assertEquals("a trailing unlocked entry is not a door",
            L, BydSignalRules.deriveOverallLock(locks(L, L, L, L, U, U, U)))
    }

    /** A malformed array must not throw or guess. */
    @Test
    fun `too few entries is unknown rather than an exception`() {
        val L = BydSignalRules.LOCK_API_LOCKED
        assertEquals(BydSignalRules.LOCK_API_UNKNOWN, BydSignalRules.deriveOverallLock(locks(L, L)))
        assertEquals(BydSignalRules.LOCK_API_UNKNOWN, BydSignalRules.deriveOverallLock(IntArray(0)))
    }

    // ── seats ────────────────────────────────────────────────────────────────────

    @Test
    fun `seat level shifts from the sdk one-based scale to zero-based`() {
        assertEquals("SDK off", 0, BydSignalRules.normalizeSeatGetterLevel(1))
        assertEquals("SDK low", 1, BydSignalRules.normalizeSeatGetterLevel(2))
        assertEquals("SDK high", 2, BydSignalRules.normalizeSeatGetterLevel(3))
    }

    @Test
    fun `unsupported seat readings are unknown not off`() {
        assertEquals("must not collapse to 0=off",
            -1, BydSignalRules.normalizeSeatGetterLevel(BydSignalRules.NO_VALUE))
        assertEquals(-1, BydSignalRules.normalizeSeatGetterLevel(0))
        assertEquals(-1, BydSignalRules.normalizeSeatGetterLevel(4))
    }

    // ── units ────────────────────────────────────────────────────────────────────

    /**
     * km is the safe default for any unexpected value: over-reporting distance by 60% would
     * corrupt every trip and every consumption bucket.
     */
    @Test
    fun `mileage unit maps to a conversion factor with km as the safe default`() {
        assertEquals("0 means miles", BydSignalRules.MILES_TO_KM,
            BydSignalRules.distanceFactorForMileageUnit(0), EPS)
        assertEquals("1 means km", 1.0, BydSignalRules.distanceFactorForMileageUnit(1), EPS)
        assertEquals("anything unexpected defaults to km",
            1.0, BydSignalRules.distanceFactorForMileageUnit(99), EPS)
        assertEquals(1.0, BydSignalRules.distanceFactorForMileageUnit(-1), EPS)
    }
}
