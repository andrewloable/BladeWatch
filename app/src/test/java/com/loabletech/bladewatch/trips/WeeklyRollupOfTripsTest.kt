package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-jkuz: the Period Summary is ONE rollup over exactly the selected days' trips, so its
 * count, distance and cost agree with the trip list and the dashboard for the same days.
 */
class WeeklyRollupOfTripsTest {

    private fun trip(km: Double, secs: Int, cost: Double, kwhStart: Double, kwhEnd: Double, score: Int) = TripRecord().apply {
        distanceKm = km
        durationSeconds = secs
        tripCost = cost
        this.kwhStart = kwhStart
        this.kwhEnd = kwhEnd
        efficiencySocPerKm = km / 10
        energyPerKm = 0.1 * km
        anticipationScore = score
        smoothnessScore = score
        speedDisciplineScore = score
        efficiencyScore = score
        consistencyScore = score
    }

    @Test
    fun `sums what adds up and averages the rest per trip`() {
        val r = WeeklyRollup.ofTrips(listOf(trip(10.0, 600, 12.0, 50.0, 48.0, 80), trip(30.0, 1800, 30.0, 48.0, 43.0, 60)))
        assertEquals(2, r.tripCount)
        assertEquals(40.0, r.totalDistanceKm, 1e-9)
        assertEquals(2400, r.totalDurationSeconds)
        assertEquals(42.0, r.totalCost, 1e-9)
        assertEquals(7.0, r.totalEnergyKwh, 1e-9)
        assertEquals(2.0, r.avgEfficiency, 1e-9)
        assertEquals(2.0, r.avgEnergyPerKm, 1e-9)
        assertEquals(70, r.avgEfficiencyScore)
        assertEquals(70, r.avgAnticipation)
    }

    @Test
    fun `no trips is an empty rollup`() {
        val r = WeeklyRollup.ofTrips(emptyList())
        assertEquals(0, r.tripCount)
        assertEquals(0.0, r.totalDistanceKm, 0.0)
    }
}
