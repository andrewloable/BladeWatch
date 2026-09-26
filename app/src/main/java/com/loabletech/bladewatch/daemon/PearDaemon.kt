package net.bladewatch.app.daemon

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.system.Os
import java.io.File
import java.nio.ByteBuffer
import java.util.Base64
import kotlin.system.exitProcess
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import to.holepunch.bare.kit.IPC
import to.holepunch.bare.kit.Worklet

/**
 * The Pear peer: a standalone daemon, `pear_daemon`, beside byd_cam_daemon / sentry_daemon /
 * acc_sentry_daemon. Hosts a bare-kit [Worklet] running pear-end (the stock flutter_pear worklet
 * bundle) and joins this car's Hyperswarm topic ([PearTopic]) so a paired companion can find it
 * from anywhere.
 *
 * Launched by [net.bladewatch.app.launcher.PearLauncher] as
 * `app_process -Djava.library.path=... --nice-name=pear_daemon`. Supervised the way tor is: if the
 * worklet dies, this process exits and DaemonStartupManager's 30 s health check relaunches it.
 *
 * Every runtime requirement below was found and verified by the BladeWatch-rdtj.2 spike on the real
 * head unit; each is load-bearing, and removing one crashes or silently breaks the daemon:
 *  1. An Application must be bound before `worklet.start()` -- see [installApplicationForBareKit].
 *  2. Worklet and IPC must live on a thread whose Looper is prepared AND pumped -- see [main].
 *  3. The launch needs `-Djava.library.path` with the APK's native dir first (PearLauncher).
 *  4. libc++_shared.so and pear-end's addon .so files must ship in the APK (app/build.gradle.kts).
 *  5. Storage must be shell-writable -- see [STORAGE_DIR].
 */
object PearDaemon {
    private const val TAG = "PearDaemon"
    private const val SINGLETON_LOCK_FILE = "/data/local/tmp/pear_daemon.lock"

    /**
     * pear-end's storage root (its argv[0] under BareKit); Corestore opens RocksDB here at module
     * load. Not the app's filesDir, which FlutterPearBarePlugin passes: this daemon is shell uid and
     * cannot write the app's private data. 0700, because pear-end creates its corestore INSIDE as
     * 0777 -- this directory's mode is the only thing keeping it private.
     *
     * Once pairing exists this holds the car's permanent Pear identity. Deleting it strands every
     * paired companion, exactly like deleting tor's hs/ directory. Never remove it to "reset" state.
     */
    const val STORAGE_DIR = "/data/local/tmp/pear"

    private const val BUNDLE_ASSET = "pear/pear-end.bundle"

    /**
     * The car's swarm.join: its topic, accepting companions it cannot find announced
     * (BladeWatch-lw0o). pear-end otherwise uses a connection a companion dialed in only once its
     * own discovery finds that companion's announcement -- about a minute of retries -- and from a
     * phone behind a slow or randomizing NAT it often never does: the connection sits open and
     * silent (5 of 8 routes from a hotspot, 2026-09-26). Honoured by pear-end only while this is
     * the worklet's sole topic with the option, which it is; an older pear-end ignores it.
     */
    internal fun joinParams(topic: String): JSONObject =
        JSONObject().put("topic", topic).put("acceptUnannounced", true)

    // pear-end request ids; any number works, these just have to be unique while in flight.
    private const val ID_ATTACH_INFO = 1
    private const val ID_SWARM_JOIN = 2
    private const val ID_DHT_STATUS = 3
    private const val FIRST_WRITE_ID = 100 // connection.write requests count up from here

    private const val SWEEP_INTERVAL_MS = 30_000L

    private lateinit var log: DaemonLogger

    @JvmStatic
    fun main(args: Array<String>) {
        DaemonLogger.configure(
            DaemonLogger.Config.defaults()
                .withStdoutLog(true)
                .withFileLog(true)
                .withConsoleLog(true)
        )
        log = DaemonLogger.getInstance(TAG, "/data/local/tmp")
        log.info("=== PearDaemon starting, pid=${Process.myPid()} uid=${Process.myUid()} ===")

        val lock = DaemonSingletonLock(
            File(SINGLETON_LOCK_FILE), Process.myPid(), DaemonSingletonLock.PROC_LIVENESS
        ) { msg -> log.info(msg) }
        if (!lock.acquire()) die("another PearDaemon instance holds the singleton lock")
        Runtime.getRuntime().addShutdownHook(Thread { lock.release() })

        // Before DaemonBootstrap.init(), not after: its manual ActivityThread construction builds a
        // Handler, which needs a Looper on this thread. And bare-kit's IPC captures THIS thread's
        // ALooper -- IPC_init calls ALooper_forThread() then ALooper_acquire() with no null check,
        // and registers the pipe fd on it, so the Looper must also be pumped (Looper.loop below).
        if (Looper.myLooper() == null) Looper.prepareMainLooper()
        val handler = Handler(Looper.myLooper()!!)

        val context = DaemonBootstrap.init(grantPermissions = false)
            ?: die("DaemonBootstrap.init() returned no context")
        handler.post { boot(context, handler) }
        Looper.loop()
    }

    private fun boot(context: Context, handler: Handler) {
        try {
            installApplicationForBareKit(context)
            val bundle = context.assets.open(BUNDLE_ASSET).use { it.readBytes() }
            File(STORAGE_DIR).mkdirs()
            Os.chmod(STORAGE_DIR, 0b111_000_000) // 0700: rwx for shell only
            val topic = PearTopic.topicHex(SecretConfigStore())

            val worklet = Worklet(null)
            val source = ByteBuffer.allocateDirect(bundle.size).apply { put(bundle); flip() }
            // The first argument only names the bundle for stack traces; the bytes come from source.
            worklet.start("/pear-end.bundle", source, arrayOf(STORAGE_DIR))
            Session(IPC(worklet), handler).start(topic)
        } catch (t: Throwable) {
            die("boot failed: ${t.javaClass.name}: ${t.message}", t)
        }
    }

    /**
     * One worklet's IPC: sends the boot requests, reads frames, reacts to responses and events, and
     * carries [PearStreamPump]'s traffic -- `connection.data` in, `connection.write` out.
     *
     * Everything here runs on the IPC [handler] thread; the pump's socket threads reach it only
     * through [sendToPeer], which posts.
     *
     * Logs states and counts, never the topic, peer keys or payloads -- the topic is a capability to
     * find the car, and daemon logs end up in bug reports.
     */
    private class Session(private val ipc: IPC, private val handler: Handler) {
        private val decoder = PearIpc.FrameDecoder()
        private var peers = 0
        private val outgoing = ArrayDeque<ByteBuffer>()
        private var writing = false
        private var nextWriteId = FIRST_WRITE_ID
        private val writesInFlight = HashMap<Int, String>() // connection.write id -> peer
        private val pump = PearStreamPump(send = ::sendToPeer)
        private val status = PearStatus(File(PearStatus.PATH))

        fun start(topic: String) {
            status.write() // replaces whatever a previous run left: not joined yet
            armRead()
            request(ID_ATTACH_INFO, "attach.info", JSONObject())
            request(ID_SWARM_JOIN, "swarm.join", joinParams(topic))
            scheduleSweep()
        }

        /** One multiplexed frame to [peer]. Called from the pump's socket threads. */
        private fun sendToPeer(peer: String, message: ByteArray) {
            val data = Base64.getEncoder().encodeToString(message)
            handler.post {
                val id = nextWriteId
                nextWriteId = if (id == Int.MAX_VALUE) FIRST_WRITE_ID else id + 1
                writesInFlight[id] = peer
                request(id, "connection.write", JSONObject().put("peer", peer).put("data", data))
            }
        }

        private fun request(id: Int, method: String, params: JSONObject) {
            val frame = PearIpc.encodeJson(JSONObject().put("id", id).put("m", method).put("p", params).toString())
            outgoing.addLast(ByteBuffer.allocateDirect(frame.size).apply { put(frame); flip() })
            drain()
        }

        /**
         * Exactly one IPC write in flight. bare-kit's `IPC.write(buf, cb)` finishes a partial write
         * from a `writable()` callback, and a second write issued meanwhile goes straight to the pipe
         * AHEAD of the first one's remainder and replaces its callback: interleaved frames, and a
         * completion that never fires (read off bare-kit 2.5.5's IPC.class). A couple of small boot
         * requests never hit that; a video stream does.
         */
        private fun drain() {
            if (writing) return
            val next = outgoing.removeFirstOrNull() ?: return
            writing = true
            ipc.write(next) { error ->
                if (error != null) die("ipc write failed: ${error.message}", error)
                // Posted: the callback runs synchronously inside ipc.write when the whole buffer
                // fits, and draining inline would recurse once per queued frame.
                handler.post {
                    writing = false
                    drain()
                }
            }
        }

        private fun scheduleSweep() {
            handler.postDelayed({
                pump.sweepIdle()
                request(ID_DHT_STATUS, "dht.status", JSONObject())
                scheduleSweep()
            }, SWEEP_INTERVAL_MS)
        }

        private fun armRead() {
            ipc.read { data, error ->
                // A worklet this daemon cannot talk to is useless. Exiting lets the health check
                // relaunch a fresh one, which is the whole crash-recovery design.
                if (error != null) die("ipc read failed: ${error.message}", error)
                if (data == null) die("worklet IPC closed -- the worklet exited")
                val chunk = ByteArray(data.remaining()).also { data.get(it) }
                val frames = try {
                    decoder.feed(chunk)
                } catch (e: IllegalArgumentException) {
                    die("unrecoverable IPC framing error: ${e.message}", e)
                }
                frames.filter { it.type == PearIpc.FRAME_JSON }.forEach { handle(JSONObject(it.text())) }
                // Posted, not called: IPC.read can deliver synchronously when data is buffered, and
                // re-arming inline would recurse once per chunk (FlutterPearBarePlugin does the same).
                handler.post { armRead() }
            }
        }

        private fun handle(frame: JSONObject) {
            if (frame.has("ev")) return onEvent(frame.getString("ev"), frame.optJSONObject("p"))
            when (val id = frame.optInt("id", -1)) {
                ID_ATTACH_INFO -> {
                    val ok = frame.optJSONObject("ok") ?: die("attach.info failed: ${frame.opt("err")}")
                    log.info("worklet up, pear-end bundle ${ok.optString("bundleVersion")}")
                }
                ID_SWARM_JOIN -> {
                    if (!frame.has("ok")) die("swarm.join failed: ${frame.opt("err")}")
                    log.info("joined this car's topic; announcing on the DHT")
                    status.joined = true
                    status.write()
                    request(ID_DHT_STATUS, "dht.status", JSONObject())
                }
                ID_DHT_STATUS -> {
                    // An error means this pear-end has no dht.status (older than flutter_pear 0.4.4):
                    // reachability is then unknown, not false.
                    status.online = frame.optJSONObject("ok")?.optBoolean("online")
                    status.write()
                }
                // A failed connection.write means pear-end no longer knows the peer: its streams are
                // dead even if the connection.close event has not arrived yet.
                else -> writesInFlight.remove(id)?.let { peer -> if (frame.has("err")) pump.onPeerClosed(peer) }
            }
        }

        private fun onEvent(event: String, p: JSONObject?) {
            when (event) {
                "swarm.lifecycle" -> p?.optString("state")?.takeIf { it.isNotEmpty() }
                    ?.let { log.info("swarm state: $it") }
                "swarm.connection" -> {
                    log.info("companion connected (peers=${++peers})")
                    status.companions = peers
                    status.lastCompanionAt = System.currentTimeMillis()
                    status.write()
                }
                "connection.data" -> {
                    val peer = p?.optString("peer").orEmpty()
                    val message = try {
                        Base64.getDecoder().decode(p?.optString("data").orEmpty())
                    } catch (e: IllegalArgumentException) {
                        return // not from pear-end, whatever it is: nothing to pump
                    }
                    if (peer.isNotEmpty()) pump.onMessage(peer, message)
                }
                "connection.close" -> {
                    peers = (peers - 1).coerceAtLeast(0)
                    log.info("companion disconnected (peers=$peers)")
                    status.companions = peers
                    status.write()
                    p?.optString("peer")?.takeIf { it.isNotEmpty() }?.let(pump::onPeerClosed)
                }
                "worklet.crash" -> die("worklet crashed: ${p?.optString("kind")}: ${p?.optString("message")}")
                "rpc.diagnostic" -> log.warn("pear-end diagnostic: ${p?.optString("reason")}")
            }
        }
    }

    /**
     * libbare-kit.so's `bare_kit__on_thread_enter` runs on every native thread bare creates, the
     * worklet thread included, and does -- with no null check:
     *
     *     Thread.currentThread().setContextClassLoader(
     *         ActivityThread.currentApplication().getClassLoader())
     *
     * Recovered by disassembling the 2.5.5 .so: the JNI function-table offsets it calls, plus the
     * rodata strings each call passes. In any real app an Application exists by then. In an
     * app_process daemon nothing ever binds one, so currentApplication() is null and ART aborts the
     * whole process on GetObjectClass(null) -- "JNI DETECTED ERROR IN APPLICATION: java_object ==
     * null in call to GetObjectClass", from the `bare-worklet` thread (BladeWatch-rdtj.2).
     *
     * So bind a stand-in whose class loader is the one that loaded bare-kit's own Java classes,
     * which is what the hook exists to hand its threads. Local to this daemon on purpose: doing it
     * in the shared DaemonBootstrap would change what BYD SDK code sees from currentApplication()
     * in CameraDaemon and SentryDaemon too.
     */
    private fun installApplicationForBareKit(context: Context) {
        val activityThread = Class.forName("android.app.ActivityThread")
        // Set by DaemonBootstrap.init(); currentApplication() reads mInitialApplication off it.
        val current = activityThread.getMethod("currentActivityThread").invoke(null)
            ?: error("no current ActivityThread -- DaemonBootstrap.init() must run first")
        activityThread.getDeclaredField("mInitialApplication")
            .apply { isAccessible = true }
            .set(current, BareKitApplication(context, Worklet::class.java.classLoader!!))
        checkNotNull(activityThread.getMethod("currentApplication").invoke(null)) {
            "ActivityThread.currentApplication() is still null after setting mInitialApplication"
        }
    }

    /** See [installApplicationForBareKit]. */
    private class BareKitApplication(base: Context, private val loader: ClassLoader) :
        Application() {
        init {
            attachBaseContext(base)
        }

        override fun getClassLoader(): ClassLoader = loader
    }

    private fun die(reason: String, cause: Throwable? = null): Nothing {
        log.error("FATAL: $reason", cause)
        exitProcess(1)
    }
}
