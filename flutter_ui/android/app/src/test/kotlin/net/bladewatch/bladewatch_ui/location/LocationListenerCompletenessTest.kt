package net.bladewatch.bladewatch_ui.location

import android.location.LocationListener
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-pg6r: [LocationServiceChannel]'s listener must implement ALL FOUR
 * `LocationListener` methods, not just `onLocationChanged`.
 *
 * `onStatusChanged`, `onProviderEnabled` and `onProviderDisabled` only gained default
 * implementations in API 30. On API 29 — this head unit, and this APK's `minSdk` — they are
 * abstract. `compileSdk` is modern, so Kotlin compiles happily against the API 30+ shape and
 * an omission cannot fail the build. It surfaces on the car instead, on the main looper, the
 * instant the framework reports a provider toggle, and it takes the whole UI process with it:
 *
 *     FATAL EXCEPTION: main
 *     java.lang.AbstractMethodError: abstract method
 *       "void android.location.LocationListener.onProviderDisabled(java.lang.String)"
 *
 * This asserts against the COMPILED CLASS rather than the source text, for two reasons. It is
 * what actually ships — a method present in source but erased by some future desugaring step
 * would still fail here. And because the class arrives on the test classpath, the check cannot
 * go up-to-date-blind the way a test that reads a source tree as data does (see CLAUDE.md,
 * "Gradle up-to-date blindness"), so it needs no extra `inputs` plumbing to stay honest.
 *
 * [LocationServiceChannel] itself cannot be constructed here — it resolves `LOCATION_SERVICE`
 * in a field initialiser — so this reflects over the type without instantiating it.
 */
class LocationListenerCompletenessTest {

    /** Every abstract method of the API 29 interface. Spelled out, not derived. */
    private val required = listOf(
        "onLocationChanged",
        "onStatusChanged",
        "onProviderEnabled",
        "onProviderDisabled",
    )

    private fun listenerClass(): Class<*> {
        val field = LocationServiceChannel::class.java.declaredFields.firstOrNull {
            LocationListener::class.java.isAssignableFrom(it.type)
        }
        requireNotNull(field) {
            "LocationServiceChannel no longer holds a LocationListener field — this guard has " +
                "lost its subject and would silently pass. Re-point it at the new listener."
        }
        return field.type
    }

    @Test
    fun theListenerImplementsEveryApi29LocationListenerMethod() {
        val declared = listenerClass().declaredMethods.map { it.name }.toSet()
        for (name in required) {
            assertTrue(
                "LocationServiceChannel's listener does not declare $name(). On API 29 that " +
                    "method is abstract, so the framework calling it throws AbstractMethodError " +
                    "and kills the app. Declared: ${declared.sorted()}",
                name in declared,
            )
        }
    }

    @Test
    fun theListenerReallyIsALocationListener() {
        assertTrue(
            "the field this guard inspects is no longer a LocationListener",
            LocationListener::class.java.isAssignableFrom(listenerClass()),
        )
    }
}
