package net.bladewatch.bladewatch_ui

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import net.bladewatch.bladewatch_ui.adb.AdbKeyChannel
import net.bladewatch.bladewatch_ui.auth.JwtMinter
import net.bladewatch.bladewatch_ui.config.PublicConfigChannel
import net.bladewatch.bladewatch_ui.config.SecretConfigChannel
import net.bladewatch.bladewatch_ui.daemon.DaemonControl
import net.bladewatch.bladewatch_ui.ipc.IpcClient
import net.bladewatch.bladewatch_ui.liveview.LiveViewTexturePlugin
import net.bladewatch.bladewatch_ui.location.LocationServiceChannel
import net.bladewatch.bladewatch_ui.network.NetworkInfoChannel
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Thin wiring only — see the Kover exclusion for this class in
 * `app/build.gradle.kts` for why (Android-framework-bound, not unit-testable
 * without Robolectric). Every actual behaviour lives in the plain, fully
 * unit-tested Kotlin classes under ipc/, auth/, daemon/, config/, update/;
 * this class only registers the "net.bladewatch.flutter/privileged"
 * MethodChannel (BladeWatch-ncbb.2) and dispatches each `"<group>.<method>"`
 * call to the right one, translating [IpcException]s into the platform
 * channel error codes `MethodChannelBridge` (flutter_ui/lib/platform/) maps
 * back on the Dart side.
 */
class MainActivity : FlutterActivity() {

    private val ipcClient = IpcClient()
    private val jwtMinter = JwtMinter(ipcClient)
    private val daemonControl = DaemonControl(ipcClient)
    private val secretConfig = SecretConfigChannel(ipcClient)
    private val publicConfig = PublicConfigChannel(ipcClient)

    // BladeWatch-yz1e.4 (ADB Console): this APK's own ADB key pair — see
    // AdbKeyChannel's doc comment for why it's separate from the main app's.
    private val adbKeyChannel by lazy {
        AdbKeyChannel(File(filesDir, "adbkey"), File(filesDir, "adbkey.pub"))
    }
    private val networkInfoChannel by lazy { NetworkInfoChannel(this) }

    // BladeWatch-yz1e.6 (Location screen): this APK's own GPS probe — see
    // LocationServiceChannel's doc comment for why it is deliberately thin.
    private val locationServiceChannel by lazy { LocationServiceChannel(this) }

    // FlutterActivity extends plain android.app.Activity, not
    // androidx.activity.ComponentActivity, so the modern
    // registerForActivityResult API (what LocationFragment.kt itself uses)
    // is not available here — same classic ActivityCompat.requestPermissions
    // + onRequestPermissionsResult pair native's own non-Fragment callers use.
    private var pendingLocationPermissionResult: MethodChannel.Result? = null

    // BladeWatch-yz1e.3 (Settings → Appearance): themeMode/driveSide are pure
    // per-installation UI preferences local to THIS APK (net.bladewatch.flutter),
    // not shared/secret state — plain SharedPreferences, no IPC, unlike every
    // other group above. Native's equivalent (PreferencesManager.kt) can't be
    // read directly even though the two APKs share a UID: SharedPreferences
    // files live under each package's own app-private directory.
    private val prefs by lazy { getSharedPreferences("flutter_prefs", MODE_PRIVATE) }

    // BladeWatch-yz1e.10 (Live View texture plugin): registered against
    // flutterEngine.renderer (a TextureRegistry), so it can only be built
    // once configureFlutterEngine() runs — unlike every `by lazy` channel
    // above, which only need `this` (the Activity, available immediately).
    private lateinit var liveViewTexturePlugin: LiveViewTexturePlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The privileged channel MUST run off the platform/UI thread. Nearly every
        // method on it (auth.*, daemon.*, config.*) ends in IpcClient opening a
        // blocking TCP socket to the daemon on 127.0.0.1:19876, and Android kills
        // any network I/O on the main thread with NetworkOnMainThreadException —
        // whose getMessage() is null, which is why this surfaced on device as the
        // unhelpful "connect to 127.0.0.1:19876 failed: null". JVM unit tests
        // cannot catch this: there is no main-thread policy off-device.
        //
        // Serial (the default) is deliberate: it preserves the ordering the
        // daemon's single-connection-per-command IPC expects, e.g. secret_put
        // followed by auth_invalidate in JwtMinter.putDeviceSecret.
        //
        // The handful of methods that genuinely need the Activity thread hop back
        // explicitly with runOnUiThread -- see location.requestPermission and
        // setup.* in handleMethodCall.
        val privilegedTaskQueue = flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "net.bladewatch.flutter/privileged",
            StandardMethodCodec.INSTANCE,
            privilegedTaskQueue,
        ).setMethodCallHandler(::handleMethodCall)

        liveViewTexturePlugin = LiveViewTexturePlugin(flutterEngine.renderer)
        // A dedicated channel on a background TaskQueue, unlike the shared
        // "privileged" channel above: MediaCodec's dequeueInputBuffer has a
        // bounded but nonzero wait built in (see MediaCodecFrameDecoder),
        // called once per decoded video frame — keeping that off the
        // platform/UI thread is exactly what TaskQueue exists for. Serial
        // (the default) preserves frame ordering, matching the single
        // sequential decode loop LiveStreamClient.kt itself used natively.
        val liveViewTaskQueue = flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "net.bladewatch.flutter/live_view_texture",
            StandardMethodCodec.INSTANCE,
            liveViewTaskQueue,
        ).setMethodCallHandler(::handleLiveViewMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "auth.mintJwt" -> result.success(jwtMinter.mintJwt())
                "auth.stateVersion" -> result.success(jwtMinter.stateVersion())
                "auth.invalidate" -> {
                    jwtMinter.invalidate()
                    result.success(null)
                }
                "auth.getAccessCode" -> result.success(jwtMinter.getAccessCode())
                "auth.regenerateAccessCode" -> result.success(jwtMinter.regenerateAccessCode())
                "auth.setCustomAccessCode" -> {
                    val args = requireArgs(call)
                    result.success(jwtMinter.setCustomAccessCode(args.string("password")))
                }

                "daemon.start" -> result.success(jsonToMap(daemonControl.start()))
                "daemon.stop" -> result.success(jsonToMap(daemonControl.stop()))
                "daemon.status" -> result.success(jsonToMap(daemonControl.status()))
                "daemon.processStatus" -> result.success(jsonToMap(daemonControl.processStatus()))
                "daemon.tunnelStatus" -> result.success(jsonToMap(daemonControl.tunnelStatus()))
                "daemon.setEnabled" -> {
                    val args = requireArgs(call)
                    result.success(
                        jsonToMap(daemonControl.setDaemonEnabled(args.string("type"), args.bool("enabled"))),
                    )
                }

                "config.get" -> {
                    val args = requireArgs(call)
                    result.success(secretConfig.get(args.string("section"), args.string("key")))
                }
                "config.put" -> {
                    val args = requireArgs(call)
                    result.success(secretConfig.put(args.string("section"), args.string("key"), args.string("value")))
                }
                "config.delete" -> {
                    val args = requireArgs(call)
                    result.success(secretConfig.delete(args.string("section"), args.string("key")))
                }

                // BladeWatch-hygs: the PUBLIC config store, deliberately a separate
                // group from config.* above so no call site can reach the secret
                // store by typo.
                "publicConfig.getSection" ->
                    result.success(publicConfig.getSection(requireArgs(call).string("section")))
                "publicConfig.putBoolean" -> {
                    val args = requireArgs(call)
                    result.success(
                        publicConfig.putBoolean(
                            args.string("section"),
                            args.string("key"),
                            args.bool("value"),
                        ),
                    )
                }

                "adb.getPublicKey" -> result.success(adbKeyChannel.getPublicKey())
                "adb.sign" -> {
                    val args = requireArgs(call)
                    result.success(adbKeyChannel.sign(args.byteArray("token")))
                }

                "network.current" -> result.success(networkInfoChannel.currentNetwork())

                "location.hasPermission" -> result.success(locationServiceChannel.hasPermission())
                "location.requestPermission" -> {
                    // Back to the Activity thread: the channel now runs on a
                    // background TaskQueue, and requestPermissions drives UI.
                    // pendingLocationPermissionResult is also read from
                    // onRequestPermissionsResult, which is delivered on main, so
                    // writing it here keeps that access single-threaded.
                    runOnUiThread {
                        pendingLocationPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                            LOCATION_PERMISSION_REQUEST_CODE,
                        )
                    }
                }
                "location.providerEnabled" -> result.success(locationServiceChannel.providerEnabled())
                "location.startUpdates" -> {
                    val args = requireArgs(call)
                    result.success(locationServiceChannel.startUpdates(args.string("provider")))
                }
                "location.stopUpdates" -> {
                    locationServiceChannel.stopUpdates()
                    result.success(null)
                }
                "location.currentSample" -> result.success(locationServiceChannel.currentSample())

                "prefs.getThemeMode" -> result.success(prefs.getString("themeMode", null))
                "prefs.setThemeMode" -> {
                    prefs.edit().putString("themeMode", requireArgs(call).string("value")).apply()
                    result.success(null)
                }
                "prefs.getDriveSide" -> result.success(prefs.getString("driveSide", null))
                "prefs.setDriveSide" -> {
                    prefs.edit().putString("driveSide", requireArgs(call).string("value")).apply()
                    result.success(null)
                }
                "prefs.getLocationUiMode" -> result.success(prefs.getString("locationUiMode", null))
                "prefs.setLocationUiMode" -> {
                    prefs.edit().putString("locationUiMode", requireArgs(call).string("value")).apply()
                    result.success(null)
                }
                "prefs.getSetupGuideLastSeenBuild" -> result.success(prefs.getString("setupGuideLastSeenBuild", null))
                "prefs.setSetupGuideLastSeenBuild" -> {
                    prefs.edit().putString("setupGuideLastSeenBuild", requireArgs(call).string("value")).apply()
                    result.success(null)
                }

                // Both start activities, so they hop back to the Activity thread
                // now that this channel runs on a background TaskQueue.
                "setup.openAutoStartSettings" -> {
                    runOnUiThread { openAutoStartSettings() }
                    result.success(null)
                }
                "setup.openOverlaySettings" -> {
                    runOnUiThread { openOverlaySettings() }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        } catch (e: IpcException.TokenUnreadable) {
            result.error("TOKEN_UNREADABLE", e.message, null)
        } catch (e: IpcException.DaemonNotListening) {
            result.error("DAEMON_NOT_LISTENING", e.message, null)
        } catch (e: IpcException.CommandRejected) {
            result.error("COMMAND_REJECTED", e.message, null)
        } catch (e: IpcException.Timeout) {
            result.error("TIMEOUT", e.message, null)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: Exception) {
            result.error("COMMAND_REJECTED", e.message ?: e.javaClass.simpleName, null)
        }
    }

    // BladeWatch-yz1e.10: runs on liveViewTaskQueue's background thread, not
    // the platform/UI thread (see configureFlutterEngine()) — MainActivity
    // itself is not touched from here, only liveViewTexturePlugin, which
    // owns no Activity/UI state.
    private fun handleLiveViewMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                // TextureRegistry.createSurfaceProducer is @UiThread, but this
                // channel runs on a background TaskQueue so a MediaCodec call
                // never blocks the platform thread. Both constraints are real,
                // so the two kinds of call are split: the TextureRegistry ones
                // hop to the main thread, the MediaCodec ones stay off it.
                // Without this hop the very first call failed with
                // "Methods marked with @UiThread must be executed on the main
                // thread. Current thread: flutter-worker-2", so Live View could
                // never start at all.
                "liveView.createTexture" -> runOnUiThreadCatching(result) {
                    result.success(liveViewTexturePlugin.createTexture())
                }
                "liveView.configure" -> {
                    val args = requireArgs(call)
                    liveViewTexturePlugin.configure(args.long("textureId"), args.int("width"), args.int("height"))
                    result.success(null)
                }
                "liveView.feedFrame" -> {
                    val args = requireArgs(call)
                    liveViewTexturePlugin.feedFrame(args.long("textureId"), args.byteArray("bytes"), args.bool("isCodecConfig"))
                    result.success(null)
                }
                "liveView.dispose" -> {
                    // Releases the SurfaceProducer, so same @UiThread rule as
                    // createTexture above.
                    val textureId = requireArgs(call).long("textureId")
                    runOnUiThreadCatching(result) {
                        liveViewTexturePlugin.dispose(textureId)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            // No IPC/daemon involved in this plugin at all (see its own doc
            // comment) — every failure here is a caller/argument bug, not a
            // daemon-connectivity condition, so a single generic error code
            // is correct, unlike handleMethodCall's IpcException mapping above.
            result.error("LIVE_VIEW_ERROR", e.message ?: e.javaClass.simpleName, null)
        }
    }

    /**
     * Runs [block] on the main thread, reporting any failure through [result].
     *
     * The enclosing try/catch cannot do this: by the time the posted block
     * runs, [handleLiveViewMethodCall] has already returned, so a throw inside
     * it would reach the main looper's uncaught handler and leave the Dart
     * side awaiting a reply that never comes. Catches Throwable rather than
     * Exception because the failure that motivated this — a @UiThread
     * violation — surfaces as an Error, which `catch (e: Exception)` misses.
     */
    private fun runOnUiThreadCatching(result: MethodChannel.Result, block: () -> Unit) {
        runOnUiThread {
            try {
                block()
            } catch (t: Throwable) {
                result.error("LIVE_VIEW_ERROR", t.message ?: t.javaClass.simpleName, null)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != LOCATION_PERMISSION_REQUEST_CODE) return
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingLocationPermissionResult?.success(granted)
        pendingLocationPermissionResult = null
    }


    // BladeWatch-yz1e.11 (Setup Guide dialog): ground truth
    // `SetupGuideDialog.openAutoStartSettings()` — same 4-level cascade,
    // each level swallowing its own failure and falling through, since BYD
    // firmware varies in which of these resolves. Best-effort: if every
    // level fails, there is nothing more the UI can usefully do, matching
    // native's own silent-log-and-give-up ending.
    private fun openAutoStartSettings() {
        try {
            val direct = Intent().apply {
                component = ComponentName("com.byd.appstartmanagement", "com.byd.appstartmanagement.frame.AppStartManagement")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(direct)
            return
        } catch (_: Exception) {}

        try {
            val launch = packageManager.getLaunchIntentForPackage("com.byd.appstartmanagement")
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
                return
            }
        } catch (_: Exception) {}

        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return
        } catch (_: Exception) {}

        try {
            startActivity(Intent(Settings.ACTION_APPLICATION_SETTINGS))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (_: Exception) {}
        }
    }

    // Ground truth: `SetupGuideDialog.java`'s overlay-permission step, but
    // targeted at the MAIN app's package (`net.bladewatch.app`), not this
    // Flutter APK's own — this APK declares no `SYSTEM_ALERT_WINDOW` use of
    // its own (it has no status-overlay-service equivalent), while the main
    // app does, so it is the one whose permission this screen must manage.
    // `ACTION_MANAGE_OVERLAY_PERMISSION` with an explicit `package:` URI
    // navigates the user to another app's permission toggle without the
    // caller needing to hold that permission itself.
    private fun openOverlaySettings() {
        try {
            startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:net.bladewatch.app")))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
            } catch (_: Exception) {}
        }
    }


    private fun requireArgs(call: MethodCall): Map<*, *> =
        call.arguments as? Map<*, *> ?: throw IllegalArgumentException("${call.method} requires a Map argument")

    private fun Map<*, *>.string(key: String): String =
        this[key] as? String ?: throw IllegalArgumentException("missing or non-String argument '$key'")

    private fun Map<*, *>.byteArray(key: String): ByteArray =
        this[key] as? ByteArray ?: throw IllegalArgumentException("missing or non-ByteArray argument '$key'")

    private fun Map<*, *>.int(key: String): Int =
        this[key] as? Int ?: throw IllegalArgumentException("missing or non-Int argument '$key'")

    // The standard method codec sends a Dart `int` as a 32-bit Integer when
    // it fits, and only as a Long otherwise — a textureId is usually small
    // enough to arrive as an Int even though TextureRegistry.TextureEntry.id()
    // itself returns a Long, so both must be accepted here (BladeWatch-
    // yz1e.10: this exact mismatch is the "dropped or mistyped field" this
    // task's own notes warn a platform channel can produce).
    private fun Map<*, *>.long(key: String): Long = when (val v = this[key]) {
        is Long -> v
        is Int -> v.toLong()
        else -> throw IllegalArgumentException("missing or non-integer argument '$key'")
    }

    private fun Map<*, *>.bool(key: String): Boolean =
        this[key] as? Boolean ?: throw IllegalArgumentException("missing or non-Boolean argument '$key'")

    /**
     * Converts a daemon IPC response into something StandardMethodCodec can encode.
     *
     * This has to recurse. A shallow copy leaves nested values as org.json types,
     * and the codec supports only primitives, String, byte arrays, List and Map --
     * anything else fails the whole call with "Unsupported value: ... of type class
     * org.json.JSONObject". That is not hypothetical: daemonStatus replies
     * {"status":"ok","daemons":{...}}, so the nested "daemons" object broke every
     * call to it on device while the JVM tests passed, because the test fake never
     * runs the codec.
     *
     * JSONObject.NULL is a sentinel singleton, not Kotlin null, and would itself be
     * an unsupported value -- map it to null.
     */
    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        json.keys().forEach { key -> map[key] = jsonToCodecValue(json.get(key)) }
        return map
    }

    private fun jsonToCodecValue(value: Any?): Any? = when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> jsonToMap(value)
        is JSONArray -> (0 until value.length()).map { jsonToCodecValue(value.get(it)) }
        else -> value
    }


    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 4001
    }
}
