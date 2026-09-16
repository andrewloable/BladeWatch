package net.bladewatch.app.byd

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-fpdz.1: the drivetrain decision rule, and specifically its ORDER.
 *
 * The bug this pins: the fuel HAL returns BMS sentinels during firmware warm-up. Both signals
 * therefore read as sentinel on a PHEV that has simply not finished booting, the both-sentinel
 * branch concludes BEV, and that verdict is cached for 60 seconds. For that minute a PHEV is
 * treated as a BEV — fuel percent disappears and any fuel-aware trip logic sees nothing.
 * Overdrive hit exactly this and fixed it in v17 by consulting pack capacity FIRST, because a
 * known sub-30 kWh pack names a PHEV outright: the smallest BYD BEV is the Atto 3 at 49.9 kWh.
 *
 * The real method needs a HAL device and reflection, so the decision is extracted as a pure
 * function and tested here. The reflection that feeds it is unchanged by this task.
 */
class DrivetrainDecisionTest {

    private fun decide(
        nominalKwh: Double,
        pctReal: Boolean,
        rangeReal: Boolean,
        pctSentinel: Boolean,
        rangeSentinel: Boolean,
    ): Int = BydDataCollector.decideDrivetrain(
        nominalKwh, pctReal, rangeReal, pctSentinel, rangeSentinel
    )

    /**
     * THE BUG. A known PHEV-sized pack with both fuel signals still at their warm-up sentinels
     * must resolve to PHEV. Before the capacity gate this returned BEV and cached it for a
     * minute.
     */
    @Test
    fun `known small pack wins over warm-up sentinels`() {
        assertEquals(
            "sub-30 kWh pack with both signals at sentinel must be PHEV",
            BydDataCollector.DRIVETRAIN_PHEV,
            decide(21.5, false, false, true, true)
        )
    }

    /** The capacity gate must not fire when capacity is unknown — that is today's behaviour. */
    @Test
    fun `unknown capacity leaves the existing rule untouched`() {
        assertEquals(
            "both sentinel with no capacity signal is still BEV",
            BydDataCollector.DRIVETRAIN_BEV,
            decide(0.0, false, false, true, true)
        )
    }

    /** A BEV-sized pack must not be dragged to PHEV by the gate. */
    @Test
    fun `bev sized pack stays bev`() {
        assertEquals(BydDataCollector.DRIVETRAIN_BEV, decide(60.0, false, false, true, true))
        assertEquals(BydDataCollector.DRIVETRAIN_BEV, decide(49.9, false, false, true, true))
    }

    /**
     * The threshold is a boundary, and boundaries are where off-by-one lives. 30.0 is NOT a
     * PHEV pack; anything strictly below it is.
     */
    @Test
    fun `thirty kwh is the exclusive boundary`() {
        assertEquals(
            "29.99 is a PHEV pack",
            BydDataCollector.DRIVETRAIN_PHEV,
            decide(29.99, false, false, true, true)
        )
        assertEquals(
            "30.0 must NOT be gated as PHEV",
            BydDataCollector.DRIVETRAIN_BEV,
            decide(30.0, false, false, true, true)
        )
    }

    /** Both fuel signals real is PHEV, with or without a capacity hint. */
    @Test
    fun `both fuel signals real is phev`() {
        assertEquals(BydDataCollector.DRIVETRAIN_PHEV, decide(21.5, true, true, false, false))
        assertEquals(BydDataCollector.DRIVETRAIN_PHEV, decide(0.0, true, true, false, false))
    }

    /**
     * One real signal plus one sentinel is the empty-tank / zero-range case: PHEV, but held
     * provisionally so a transient HAL miss re-probes in seconds rather than a minute.
     */
    @Test
    fun `one real one sentinel is provisional phev`() {
        assertEquals(
            BydDataCollector.DRIVETRAIN_PHEV_PROVISIONAL,
            decide(0.0, true, false, false, true)
        )
        assertEquals(
            BydDataCollector.DRIVETRAIN_PHEV_PROVISIONAL,
            decide(0.0, false, true, true, false)
        )
    }

    /**
     * A known small pack must NOT be downgraded to provisional. Capacity is the stronger
     * signal; caching it for the full TTL is the entire point of putting it first.
     */
    @Test
    fun `capacity gate outranks the provisional case`() {
        assertEquals(BydDataCollector.DRIVETRAIN_PHEV, decide(21.5, true, false, false, true))
    }

    /** Nothing conclusive at all stays unknown, so the caller does not cache a guess. */
    @Test
    fun `nothing conclusive stays unknown`() {
        assertEquals(
            BydDataCollector.DRIVETRAIN_UNKNOWN,
            decide(0.0, false, false, false, false)
        )
    }

    /** A negative or NaN capacity is not a signal and must not gate anything. */
    @Test
    fun `nonsense capacity is ignored`() {
        assertEquals(BydDataCollector.DRIVETRAIN_BEV, decide(-5.0, false, false, true, true))
        assertEquals(
            BydDataCollector.DRIVETRAIN_BEV,
            decide(Double.NaN, false, false, true, true)
        )
    }
}
