package com.overdrive.app.byd.cloud;

import com.overdrive.app.byd.cloud.crypto.BydCryptoUtils;
import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.mqtt.ProxyHelper;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.json.JSONObject;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Subscribes to BYD's EMQ MQTT broker for real-time vehicle state push.
 * Decrypts incoming messages and feeds them to BydCloudDataProvider.
 */
public final class BydCloudMqttSubscriber implements MqttCallback {

    private static final String TAG = "CloudMqttSub";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);

    private static final int BACKOFF_BASE_SECONDS = 5;
    private static final int BACKOFF_CAP_SECONDS = 300;
    private static final long SESSION_REFRESH_MS = 25 * 60 * 1000; // 25 min (before 30 min expiry)
    private static final long REAUTH_COOLDOWN_MS = 60 * 1000; // matches pyBYD _MQTT_REAUTH_COOLDOWN_S

    private final BydCloudClient client;
    private final BydCloudDataProvider dataProvider;

    private volatile MqttClient mqttClient;
    private volatile String decryptKey;
    private volatile String topic;
    private volatile boolean running = false;
    private volatile int consecutiveFailures = 0;
    private volatile long lastConnectAttemptMs = 0;
    private volatile long lastReauthAtMs = 0;

    private final AtomicBoolean connecting = new AtomicBoolean(false);
    private ScheduledExecutorService scheduler;

    public BydCloudMqttSubscriber(BydCloudClient client) {
        this.client = client;
        this.dataProvider = BydCloudDataProvider.getInstance();
    }

    public void start() {
        if (running) return;
        running = true;
        consecutiveFailures = 0;

        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "CloudMqttSub");
            t.setDaemon(true);
            return t;
        });

        scheduler.execute(this::connectAndSubscribe);

        // Session refresh timer
        scheduler.scheduleAtFixedRate(() -> {
            if (running) refreshSession();
        }, SESSION_REFRESH_MS, SESSION_REFRESH_MS, TimeUnit.MILLISECONDS);
    }

    public void stop() {
        running = false;
        if (scheduler != null) {
            scheduler.shutdownNow();
            scheduler = null;
        }
        disconnectQuietly();
        dataProvider.reset();
    }

    public boolean isConnected() {
        return mqttClient != null && mqttClient.isConnected();
    }

    // ── Connection ──────────────────────────────────────────────────────

    private void connectAndSubscribe() {
        if (!running || !connecting.compareAndSet(false, true)) return;

        try {
            lastConnectAttemptMs = System.currentTimeMillis();

            // Ensure we have a valid session
            client.ensureSession();

            // Discover broker
            String brokerHost = client.fetchEmqBrokerHost();
            // Broker may already include port (e.g., "host:8883") — don't double-append
            String brokerUri;
            if (brokerHost.contains(":")) {
                brokerUri = "ssl://" + brokerHost;
            } else {
                brokerUri = "ssl://" + brokerHost + ":8883";
            }

            // Build credentials
            String[] creds = client.buildMqttCredentials();
            String clientId = creds[0];
            String username = creds[1];
            String password = creds[2];

            topic = client.getMqttTopic();
            decryptKey = client.getMqttDecryptKey();

            logger.info("Connecting to BYD EMQ: " + brokerUri + " topic=" + topic
                    + " proxy=" + ProxyHelper.isProxyAvailable());

            // Create Paho client
            MqttClient mc = new MqttClient(brokerUri, clientId, new MemoryPersistence());
            mc.setCallback(this);

            MqttConnectOptions opts = new MqttConnectOptions();
            opts.setCleanSession(true);
            opts.setConnectionTimeout(15);
            opts.setKeepAliveInterval(60);
            opts.setAutomaticReconnect(false);
            opts.setUserName(username);
            opts.setPassword(password.toCharArray());

            // SSL with proxy support — same pattern as MqttPublisherService
            boolean proxyActive = ProxyHelper.isProxyAvailable();
            if (proxyActive) {
                opts.setSocketFactory(ProxyHelper.getProxiedSslSocketFactory(false));
            } else {
                // Clear any leftover system SOCKS properties
                System.clearProperty("socksProxyHost");
                System.clearProperty("socksProxyPort");
                opts.setSocketFactory(javax.net.ssl.SSLSocketFactory.getDefault());
            }

            mc.connect(opts);
            mc.subscribe(topic, 1);

            mqttClient = mc;
            consecutiveFailures = 0;
            dataProvider.setMqttConnected(true);
            logger.info("Connected and subscribed to BYD EMQ");

        } catch (Exception e) {
            consecutiveFailures++;
            String msg = e.getMessage() != null ? e.getMessage() : "";
            logger.warn("EMQ connect failed: " + msg);
            ProxyHelper.invalidateCache();

            // Force re-login on auth/session errors (code 1005, token expired, etc.)
            if (msg.contains("1005") || msg.contains("token") || msg.contains("Login failed")) {
                try {
                    logger.info("Forcing re-login due to auth error...");
                    client.login();
                } catch (Exception loginErr) {
                    logger.warn("Re-login failed: " + loginErr.getMessage());
                }
            }

            disconnectQuietly();
            scheduleReconnect();
        } finally {
            connecting.set(false);
        }
    }

    private void scheduleReconnect() {
        if (!running || scheduler == null || scheduler.isShutdown()) return;
        long delay = Math.min(
                BACKOFF_BASE_SECONDS * (1L << Math.min(consecutiveFailures - 1, 10)),
                BACKOFF_CAP_SECONDS);
        logger.info("Reconnecting in " + delay + "s (attempt " + consecutiveFailures + ")");
        try {
            scheduler.schedule(this::connectAndSubscribe, delay, TimeUnit.SECONDS);
        } catch (Exception ignored) {}
    }

    private void refreshSession() {
        if (!running) return;
        try {
            logger.info("Refreshing BYD cloud session...");
            disconnectQuietly();
            // Force a fresh login — ensureSession() is a no-op while the
            // current 30-min session hasn't expired, so the encryToken
            // (and therefore decryptKey) would never rotate.
            client.login();
            connectAndSubscribe();
        } catch (Exception e) {
            logger.warn("Session refresh failed: " + e.getMessage());
            scheduleReconnect();
        }
    }

    /**
     * Triggered when message decryption fails repeatedly — assume the
     * server-side key rotated and force a full re-login + reconnect.
     * Rate-limited to avoid login storms on truly malformed traffic.
     */
    private void scheduleReauth() {
        if (!running) return;
        long now = System.currentTimeMillis();
        if (now - lastReauthAtMs < REAUTH_COOLDOWN_MS) return;
        lastReauthAtMs = now;

        ScheduledExecutorService s = scheduler;
        if (s == null || s.isShutdown()) return;

        logger.info("MQTT decrypt failed — scheduling re-authentication");
        try {
            s.execute(() -> {
                if (!running) return;
                try {
                    disconnectQuietly();
                    client.login();
                    connectAndSubscribe();
                } catch (Exception e) {
                    logger.warn("MQTT re-auth failed: " + e.getMessage());
                    scheduleReconnect();
                }
            });
        } catch (Exception ignored) {}
    }

    private void disconnectQuietly() {
        MqttClient mc = mqttClient;
        mqttClient = null;
        dataProvider.setMqttConnected(false);
        if (mc != null) {
            try {
                if (mc.isConnected()) mc.disconnect(2000);
            } catch (Exception ignored) {}
            try { mc.close(); } catch (Exception ignored) {}
        }
        // Clean up JVM-level SOCKS proxy properties
        System.clearProperty("socksProxyHost");
        System.clearProperty("socksProxyPort");
    }

    // ── MqttCallback ────────────────────────────────────────────────────

    @Override
    public void connectionLost(Throwable cause) {
        dataProvider.setMqttConnected(false);
        logger.warn("EMQ connection lost: " + (cause != null ? cause.getMessage() : "unknown"));
        consecutiveFailures++;
        ProxyHelper.invalidateCache();
        if (running) scheduleReconnect();
    }

    @Override
    public void messageArrived(String topic, MqttMessage message) {
        byte[] payload = message.getPayload();
        if (payload == null || payload.length == 0) return;

        String encrypted = new String(payload, java.nio.charset.StandardCharsets.UTF_8).trim();
        if (encrypted.isEmpty()) return;

        // ── Decrypt ─────────────────────────────────────────────────────
        String decrypted;
        try {
            decrypted = BydCryptoUtils.aesDecryptUtf8(encrypted, decryptKey);
        } catch (Exception e) {
            // AES failure (BadPadding) or wrong key producing garbage UTF-8.
            // Treat as stale-key — schedule a forced re-login.
            logger.debug("MQTT decrypt failed: " + e.getMessage());
            scheduleReauth();
            return;
        }

        JSONObject envelope;
        try {
            envelope = new JSONObject(decrypted);
        } catch (Exception e) {
            // Decrypted but not valid JSON — also a key-mismatch symptom
            // (random bytes happened to satisfy PKCS#7 padding).
            logger.debug("MQTT JSON parse failed: " + e.getMessage());
            scheduleReauth();
            return;
        }

        // ── Unwrap envelope ─────────────────────────────────────────────
        // BYD MQTT push shape: { event, vin, data: { uuid, respondData: {...} } }
        // (matches pyBYD _on_mqtt_event)
        String event = envelope.optString("event", "");
        JSONObject data = envelope.optJSONObject("data");
        JSONObject respondData = data != null ? data.optJSONObject("respondData") : null;
        if (respondData == null) respondData = envelope; // legacy / unwrapped fallback

        try {
            switch (event) {
                case "vehicleInfo":
                    dataProvider.updateFromVehicleInfo(respondData, null);
                    break;
                // Other event types (smartCharge, energyConsumption,
                // remoteControl) currently have no consumer — ignore quietly.
                default:
                    logger.debug("MQTT event ignored: event=" + event);
                    break;
            }
        } catch (Exception e) {
            logger.warn("MQTT dispatch failed: " + e.getMessage());
        }
    }

    @Override
    public void deliveryComplete(IMqttDeliveryToken token) {
        // Subscriber only — no publishes
    }
}
