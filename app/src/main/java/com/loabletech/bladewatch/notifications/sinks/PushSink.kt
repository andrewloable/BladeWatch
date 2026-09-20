package net.bladewatch.app.notifications.sinks

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.CategoryRegistry
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent
import net.bladewatch.app.notifications.push.PushPayloadEncoder
import net.bladewatch.app.notifications.push.PushSubscription
import net.bladewatch.app.notifications.push.PushTransport
import net.bladewatch.app.notifications.push.SubscriptionStore
import net.bladewatch.app.notifications.push.VapidKeyStore
import net.bladewatch.app.notifications.push.VapidSigner
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference
import kotlin.math.min

/**
 * The push sink. For each notification it
 *  - filters subscriptions by per-device preferences,
 *  - signs a VAPID JWT scoped to the endpoint origin,
 *  - encrypts the payload with aes128gcm,
 *  - POSTs to the push service,
 *  - removes the subscription on 404/410 (Gone).
 *
 * Sends are dispatched to a small executor so a slow push service doesn't back up the
 * [NotificationBus] executor.
 */
class PushSink(
    private val subs: SubscriptionStore,
    private val registry: CategoryRegistry,
    private val keyStore: VapidKeyStore,
    private val signer: VapidSigner
) : NotificationBus.Sink {

    // Lazy: the executor (and its 2 worker threads) only spins up when we actually need to send a
    // push. A car with no registered phones never pays this cost — the early return below
    // short-circuits before this is touched.
    private val executorRef = AtomicReference<ExecutorService>()

    override fun onNotification(event: NotificationEvent) {
        // Cheapest possible early-out: zero phones registered means no push work, ever. Don't
        // touch the registry, don't allocate, don't spin up the executor.
        val all = subs.all()
        if (all.isEmpty()) return

        val meta = registry.get(event.category)
        if (meta == null) {
            logger.warn("dropping unregistered category: " + event.category)
            return
        }
        // Resolve the click URL: event override > registry default. We only allocate a wrapped
        // event when an override is actually needed.
        val enriched = if (event.clickUrl != null) {
            event
        } else {
            NotificationEvent(
                event.category, event.severity, event.title, event.body,
                event.tag, meta.defaultClickUrl, event.data
            )
        }

        val now = System.currentTimeMillis()
        var exec: ExecutorService? = null // lazy
        // Categories may opt out of the quiet-hours block at the registry level (e.g. charging
        // complete — the whole point is to wake the user so they unplug). CRITICAL severity also
        // bypasses, as before.
        val categoryBypassesQuiet = meta.bypassQuietHours
        for (sub in all) {
            if (sub.isMuted(event.category)) continue
            if (event.severity.ordinal < sub.minSeverity.ordinal) continue
            if (sub.inQuietHours(now) &&
                event.severity != NotificationEvent.Severity.CRITICAL &&
                !categoryBypassesQuiet
            ) {
                continue
            }
            if (exec == null) exec = executor()
            exec.execute { sendOne(sub, enriched) }
        }
    }

    /**
     * Lazy executor: created on the first eligible send. Kept around once created — the same 2
     * threads service all subsequent pushes.
     */
    private fun executor(): ExecutorService {
        executorRef.get()?.let { return it }
        val created = Executors.newFixedThreadPool(2) { r ->
            Thread(r, "PushSink").apply { isDaemon = true }
        }
        if (executorRef.compareAndSet(null, created)) return created
        // lost the race — shut ours down
        created.shutdown()
        return executorRef.get()
    }

    private fun sendOne(sub: PushSubscription, event: NotificationEvent) {
        try {
            val payload = event.toPayloadJson()
            val plaintext = payload.toString().toByteArray(Charsets.UTF_8)

            val encoded = PushPayloadEncoder.encrypt(plaintext, sub.p256dh, sub.auth)
            val jwt = signer.signFor(sub.endpoint)
            val pubKey = keyStore.publicKeyB64Url()

            // One retry for transient failures (5xx / 408 / 429). FCM occasionally sheds load
            // during real intrusion bursts — losing a single notification at the moment the user
            // cares most is the worst-case failure mode, so we make a single bounded retry with
            // the server-suggested Retry-After when present.
            var result: PushTransport.Result? = null
            for (attempt in 0 until 2) {
                result = PushTransport.send(
                    sub.endpoint, jwt, pubKey, encoded.body, TTL_SECONDS
                )

                if (result.expired()) {
                    logger.info(
                        "subscription expired (" + result.status + "), removing: " + sub.id
                    )
                    subs.remove(sub.id)
                    return
                }
                if (result.ok()) break
                if (!result.transientFailure() || attempt == 1) break

                val sleepMs = if (result.retryAfterSeconds > 0) {
                    min(result.retryAfterSeconds * 1000L, 30_000L)
                } else {
                    1500L // sensible default for unhinted 5xx
                }
                try {
                    Thread.sleep(sleepMs)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return
                }
            }
            if (result != null && !result.ok()) {
                logger.warn(
                    "push failed " + result.status + " for " + sub.id + ": " + result.body
                )
                return
            }
            sub.lastSeenAt = System.currentTimeMillis()
        } catch (e: Exception) {
            logger.error("send failed for " + sub.id + ": " + e.message)
        }
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("PushSink")
        const val TTL_SECONDS = 86_400 // 24h
    }
}
