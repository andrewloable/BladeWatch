package net.bladewatch.app.services

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log

import androidx.core.content.ContextCompat

import net.bladewatch.app.server.IpcTokenManager

import org.json.JSONObject

import java.io.File
import java.net.ConnectException
import java.net.InetSocketAddress
import java.net.Socket
import java.net.SocketException
import java.net.SocketTimeoutException

/**
 * Location Sidecar Service - Sends GPS coordinates to daemon via IPC.
 *
 * This foreground service has proper permissions to access LocationManager.
 * It sends GPS data via TCP to port 19877 (SurveillanceIpcServer).
 * Sends periodically (every 2s) so daemon gets data even after restart.
 *
 * Start via: am start-foreground-service -n net.bladewatch.app/.services.LocationSidecarService
 */
class LocationSidecarService : Service(), LocationListener {

    private var locationManager: LocationManager? = null
    private var handler: Handler? = null
    private var periodicSender: Runnable? = null
    private var latitude = 0.0
    private var longitude = 0.0
    private var speed = 0.0f
    private var heading = 0.0f
    private var accuracy = 0.0f
    private var altitude = 0.0
    private var permissionGranted = false

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service created")

        // Create notification channel FIRST
        createNotificationChannel()

        // FIX #1: Load previous location immediately from disk cache.
        // Even if GPS is currently off/dead, we report where the car was last seen.
        // This prevents the "0,0 silence trap" when service restarts.
        loadFromLocalCache()

        // Check location permission BEFORE starting foreground with location type
        // Android 14+ (SDK 34+) requires runtime permission to be granted before
        // starting a foreground service with FOREGROUND_SERVICE_TYPE_LOCATION
        val hasPermission = hasLocationPermission()

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ - must have permission before using location type
            if (hasPermission) {
                startForeground(
                    NOTIFICATION_ID, notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                )
            } else {
                // Start with dataSync type (declared in manifest),
                // will upgrade when permission granted
                startForeground(
                    NOTIFICATION_ID, notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10-13
            startForeground(
                NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        if (!hasPermission) {
            Log.e(TAG, "Location permission not granted - service will wait for permission")
            permissionGranted = false

            // Start a retry loop to check for permissions
            val h = Handler(Looper.getMainLooper())
            handler = h
            h.postDelayed(
                object : Runnable {
                    override fun run() {
                        if (hasLocationPermission()) {
                            Log.i(TAG, "Location permission now granted, starting updates")
                            permissionGranted = true

                            // Upgrade to location foreground service type now that we
                            // have permission
                            if (Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                            ) {
                                try {
                                    stopForeground(STOP_FOREGROUND_DETACH)
                                    startForeground(
                                        NOTIFICATION_ID, buildNotification(),
                                        ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                                    )
                                } catch (e: Exception) {
                                    Log.w(
                                        TAG,
                                        "Could not upgrade to location FGS type: " + e.message
                                    )
                                }
                            }

                            startLocationUpdates()
                            startPeriodicSender()
                        } else {
                            Log.d(TAG, "Still waiting for location permission...")
                            h.postDelayed(this, 5000) // Check every 5 seconds
                        }
                    }
                },
                5000
            )
            return
        }

        permissionGranted = true

        // Start location updates
        startLocationUpdates()

        // Start periodic sender
        startPeriodicSender()
    }

    private fun startPeriodicSender() {
        val h = handler ?: Handler(Looper.getMainLooper()).also { handler = it }

        // FIX #3: Always send GPS data, even if 0,0.
        // Thanks to loadFromLocalCache(), we should have valid cached coordinates.
        // If it's truly 0,0 (brand new install), the daemon handles "invalid location" logic.
        // The sender should never be the gatekeeper - that's the daemon's job.
        val sender = object : Runnable {
            override fun run() {
                sendGpsViaTcp()

                // If no fresh GPS fix in 30 seconds, request one explicitly
                // This handles cases where the provider stopped sending updates
                val lm = locationManager
                if (permissionGranted && lm != null) {
                    try {
                        val lastGps = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                        if (lastGps != null) {
                            val fixAge = System.currentTimeMillis() - lastGps.time
                            if (fixAge < 10000) {
                                // Fresh fix available that we might have missed
                                onLocationChanged(lastGps)
                            }
                        }
                    } catch (e: SecurityException) {
                        Log.w(TAG, "Location permission lost in periodic sender: " + e.message)
                    } catch (e: Exception) {
                        Log.w(TAG, "Periodic sender error: " + e.message)
                    }
                }

                h.postDelayed(this, 2000)
            }
        }
        periodicSender = sender
        h.postDelayed(sender, 2000)
    }

    private fun hasLocationPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Service",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "GPS tracking for surveillance"
            channel.setShowBadge(false)

            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            // Pre-O Android Auto builds do not support notification channels.
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Location Active")
            .setContentText("GPS tracking running")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .build()
    }

    private fun startLocationUpdates() {
        try {
            val lm = getSystemService(LOCATION_SERVICE) as LocationManager?
            locationManager = lm

            if (lm == null) {
                Log.e(TAG, "LocationManager not available")
                return
            }

            // Request GPS updates
            if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    1000, // 1 second
                    0.0f, // 0 meters - always get updates even when stationary
                    this
                )
                Log.i(TAG, "GPS provider started (minDistance=0)")
            }

            // Also use network provider as fallback
            if (lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                lm.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    2000, // 2 seconds
                    0.0f, // 0 meters
                    this
                )
                Log.i(TAG, "Network provider started (minDistance=0)")
            }

            // Get last known location immediately
            val lastGps = lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val lastNetwork = lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)

            Log.i(TAG, "Last GPS: $lastGps, Last Network: $lastNetwork")

            if (lastGps != null) {
                onLocationChanged(lastGps)
            } else if (lastNetwork != null) {
                onLocationChanged(lastNetwork)
            } else {
                // Send initial update (will fail if daemon not running yet, that's OK)
                sendGpsViaTcp()
                Log.i(TAG, "No last known location, sent initial update")
            }
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission denied: " + e.message)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start location updates: " + e.message)
        }
    }

    override fun onLocationChanged(location: Location) {
        val hadFix = latitude != 0.0 || longitude != 0.0

        latitude = location.latitude
        longitude = location.longitude
        speed = if (location.hasSpeed()) location.speed else 0.0f
        heading = if (location.hasBearing()) location.bearing else 0.0f
        accuracy = if (location.hasAccuracy()) location.accuracy else 0.0f
        altitude = if (location.hasAltitude()) location.altitude else 0.0

        // Only log the first fix at INFO; suppress steady-state spam.
        // Individual fixes go to DEBUG so they're still available via
        // `adb logcat *:V` but don't fill the normal log.
        if (!hadFix) {
            Log.i(TAG, "First location fix: $latitude, $longitude")
        } else {
            Log.d(TAG, "Location update: $latitude, $longitude")
        }

        // Send to daemon via IPC
        sendGpsViaTcp()

        // Also save to app's local cache (persists across reboots, readable by daemon)
        saveToLocalCache()
    }

    /**
     * Save GPS to app's local cache file.
     * This file persists across reboots and can be read by the daemon.
     * The daemon (UID 2000) can read from /data/data/net.bladewatch.app/files/ but cannot
     * write to it.
     */
    private fun saveToLocalCache() {
        if (latitude == 0.0 && longitude == 0.0) return

        try {
            val json = JSONObject()
            json.put("lat", latitude)
            json.put("lng", longitude)
            json.put("speed", speed)
            json.put("heading", heading)
            json.put("accuracy", accuracy)
            json.put("altitude", altitude)
            json.put("time", System.currentTimeMillis())
            val content = json.toString()

            // Write to app's files directory
            val file = File(filesDir, "gps_cache.json")
            val tmp = File(filesDir, "gps_cache.json.tmp")

            tmp.writeText(content)

            if (!tmp.renameTo(file)) {
                // Fallback: direct write
                file.writeText(content)
                tmp.delete()
            }

            // Make readable by other UIDs (daemon UID 2000)
            file.setReadable(true, false)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save local GPS cache: " + e.message)
        }
    }

    /**
     * Load GPS from app's local cache file on service startup.
     * Always loads cached location (better than nothing), but marks it so
     * we know to prioritize fresh GPS fixes when they arrive.
     */
    private fun loadFromLocalCache() {
        try {
            val file = File(filesDir, "gps_cache.json")
            if (!file.exists()) {
                Log.i(TAG, "No GPS cache file found")
                return
            }

            val json = JSONObject(file.readText())
            val lat = json.optDouble("lat", 0.0)
            val lng = json.optDouble("lng", 0.0)

            if (lat != 0.0 || lng != 0.0) {
                latitude = lat
                longitude = lng
                speed = json.optDouble("speed", 0.0).toFloat()
                heading = json.optDouble("heading", 0.0).toFloat()
                accuracy = json.optDouble("accuracy", 0.0).toFloat()
                altitude = json.optDouble("altitude", 0.0)

                val cacheTime = json.optLong("time", 0)
                val ageMs =
                    if (cacheTime > 0) System.currentTimeMillis() - cacheTime else -1
                Log.i(
                    TAG,
                    "Loaded cached location (" +
                        (if (ageMs > 0) (ageMs / 1000).toString() + "s old" else "unknown age") +
                        "): " + lat + ", " + lng
                )

                // Send cached location to daemon immediately — better than nothing
                sendGpsViaTcp()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load GPS cache: " + e.message)
        }
    }

    private fun sendGpsViaTcp() {
        // Must run on background thread (Android doesn't allow network on main thread)
        Thread({
            var socket: Socket? = null
            try {
                val json = JSONObject()
                json.put("command", "UPDATE_GPS")
                json.put("lat", latitude)
                json.put("lng", longitude)
                json.put("speed", speed)
                json.put("heading", heading)
                json.put("accuracy", accuracy)
                json.put("altitude", altitude)
                json.put("time", System.currentTimeMillis())
                val token = IpcTokenManager.getToken()
                if (token != null) json.put("token", token)

                val s = Socket()
                socket = s
                s.connect(InetSocketAddress("127.0.0.1", 19877), 1000)
                s.soTimeout = 1000

                val out = s.getOutputStream()
                out.write((json.toString() + "\n").toByteArray())
                out.flush()

                // Read response to confirm daemon received it
                val response = s.getInputStream().bufferedReader().readLine()
                if (response == null) {
                    Log.w(TAG, "No response from daemon - GPS update may be lost")
                }
            } catch (e: ConnectException) {
                // Daemon not running yet - expected on startup
            } catch (e: SocketTimeoutException) {
                // The daemon received GPS via a best-effort local socket but
                // did not answer before our short timeout. Location keeps
                // flowing on the next tick, so keep this out of error logs.
                Log.w(TAG, "IPC response timeout - GPS update will retry")
            } catch (e: SocketException) {
                // The daemon can close the local socket while restarting; the
                // next GPS tick reconnects, so this is startup noise, not app failure.
                Log.w(TAG, "IPC socket reset - GPS update will retry")
            } catch (e: Exception) {
                Log.e(TAG, "IPC error: " + e.javaClass.simpleName + ": " + e.message)
            } finally {
                if (socket != null) {
                    try {
                        socket.close()
                    } catch (e: Exception) {
                        Log.w(TAG, "Socket close error: " + e.message)
                    }
                }
            }
        }, "GPS-IPC").start()
    }

    @Suppress("DEPRECATION") // Kept for legacy providers on older Android Auto builds.
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        Log.d(TAG, "Provider $provider status: $status")
    }

    override fun onProviderEnabled(provider: String) {
        Log.i(TAG, "Provider enabled: $provider")
    }

    override fun onProviderDisabled(provider: String) {
        Log.w(TAG, "Provider disabled: $provider")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Service started")
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()

        val h = handler
        val sender = periodicSender
        if (h != null && sender != null) {
            h.removeCallbacks(sender)
        }

        locationManager?.removeUpdates(this)

        Log.i(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "LocationSidecar"
        private const val CHANNEL_ID = "location_sidecar"
        private const val NOTIFICATION_ID = 9999
    }
}
