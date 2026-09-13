package net.bladewatch.bladewatch_ui.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import androidx.core.content.ContextCompat

/**
 * BladeWatch-yz1e.6 (Location screen): this APK's own on-device GPS probe.
 * Ground truth: `LocationGpsController.kt`'s direct `LocationManager` usage.
 * Deliberately thin — permission/provider precedence and every state
 * transition live in Dart's `LocationController`
 * (`flutter_ui/lib/screens/location/location_controller.dart`), polled on a
 * timer, so they are covered by Dart tests; this class only owns the actual
 * `LocationManager` registration and caches the latest sample for Dart to
 * read.
 *
 * Excluded from the Kover coverage gate (see `build.gradle.kts`) for the
 * same reason `NetworkInfoChannel` is: `LocationManager` is a framework
 * service this project does not use Robolectric to fake.
 */
class LocationServiceChannel(private val context: Context) {
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var lastSample: Location? = null

    private val listener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            lastSample = location
        }
    }

    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    /** Result shape: `gps`/`network` are each whether that provider is currently enabled. */
    fun providerEnabled(): Map<String, Any?> = mapOf(
        "gps" to isProviderEnabled(LocationManager.GPS_PROVIDER),
        "network" to isProviderEnabled(LocationManager.NETWORK_PROVIDER),
    )

    /** Result shape: `{"ok": true}` or `{"ok": false, "reason": String?}`. */
    fun startUpdates(provider: String): Map<String, Any?> {
        stopUpdates()
        return runCatching {
            locationManager.requestLocationUpdates(provider, 1_000L, 0f, listener, Looper.getMainLooper())
            mapOf("ok" to true)
        }.getOrElse { mapOf("ok" to false, "reason" to it.message) }
    }

    fun stopUpdates() {
        lastSample = null
        runCatching { locationManager.removeUpdates(listener) }
    }

    /** The most recent cached sample since the last [startUpdates], or null. */
    fun currentSample(): Map<String, Any?>? {
        val location = lastSample ?: return null
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "bearingDegrees" to if (location.hasBearing()) location.bearing else null,
            "speedMetersPerSecond" to if (location.hasSpeed()) location.speed else null,
            "accuracyMeters" to if (location.hasAccuracy()) location.accuracy else null,
            "altitudeMeters" to if (location.hasAltitude()) location.altitude else null,
            "provider" to (location.provider ?: ""),
            "timestampMs" to (if (location.time > 0L) location.time else System.currentTimeMillis()),
        )
    }

    private fun isProviderEnabled(provider: String): Boolean =
        runCatching { locationManager.isProviderEnabled(provider) }.getOrDefault(false)
}
