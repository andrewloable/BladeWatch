package com.overdrive.app.abrp;

import android.content.Context;

import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.monitor.BatterySocData;
import com.overdrive.app.monitor.ChargingStateData;
import com.overdrive.app.monitor.GearMonitor;
import com.overdrive.app.monitor.GpsMonitor;
import com.overdrive.app.monitor.VehicleDataMonitor;

import org.json.JSONObject;

import java.lang.reflect.Method;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

/**
 * ABRP Telemetry Service - collects vehicle telemetry and uploads to ABRP API.
 *
 * Collects all ABRP Gold Standard fields from BYD vehicle monitors and reflection-based
 * device access, assembles JSON payloads, and POSTs them to the ABRP API at adaptive intervals.
 *
 * Runs as a scheduled thread inside CameraDaemon.
 */
public class AbrpTelemetryService {

    private static final String TAG = "AbrpTelemetryService";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);

    private static final String ABRP_API_URL = "https://api.iternio.com/1/tlm/send";
    
    // ABRP API key — hardcoded "Open Source" key for third-party/DIY apps.
    // This identifies the app to ABRP, NOT the user.
    // The user provides their own "token" via the UI (from ABRP "Link Generic").
    // Replace with your own key if you register at contact@iternio.com.
    private static final String PUBLIC_API_KEY = "42407443-7db2-4a3d-8950-0029ecb42a67";

    // Adaptive intervals
    private static final int DRIVING_INTERVAL_SECONDS = 5;
    private static final int PARKED_INTERVAL_SECONDS = 30;

    // Backoff
    private static final int BACKOFF_BASE_SECONDS = 5;
    private static final int BACKOFF_CAP_SECONDS = 300;

    // Configuration and estimator
    private final AbrpConfig config;
    private final SohEstimator sohEstimator;

    // Data source references
    private final VehicleDataMonitor vehicleDataMonitor;
    private final GpsMonitor gpsMonitor;
    private final GearMonitor gearMonitor;

    // Reflection-accessed devices
    private Object engineDevice;        // BYDAutoEngineDevice
    private Method getEnginePowerMethod;
    private Object chargingDevice;      // BYDAutoChargingDevice
    private Method getChargingGunStateMethod;
    private Object instrumentDevice;    // BYDAutoInstrumentDevice
    private Method getOutCarTemperatureMethod;
    private Object statisticDevice;     // BYDAutoStatisticDevice
    private Method getTotalMileageValueMethod;
    private Object speedDevice;         // BYDAutoSpeedDevice
    private Method getCurrentSpeedMethod;
    private Object acDevice;            // BYDAutoAcDevice
    private Method getTempratureMethod;
    private Object gearboxDevice;       // BYDAutoGearboxDevice
    private Method getGearboxAutoModeTypeMethod;

    // HTTP client (proxy configured lazily on first upload)
    private OkHttpClient httpClient;
    private volatile boolean proxyChecked = false;
    private volatile long lastProxyCheckTime = 0;

    // Scheduler
    private ScheduledExecutorService scheduler;
    private ScheduledFuture<?> scheduledTask;

    // State
    private volatile boolean running;
    private int consecutiveFailures;
    private long lastUploadTime;
    private long totalUploads;
    private long failedUploads;
    private JSONObject lastTelemetrySnapshot;
    
    // Weather temperature cache (fetched from Open-Meteo API using GPS coords)
    private volatile double cachedWeatherTemp = Double.NaN;
    private volatile long lastWeatherFetchTime = 0;
    private static final long WEATHER_CACHE_MS = 10 * 60 * 1000; // 10 minutes

    public AbrpTelemetryService(AbrpConfig config, SohEstimator sohEstimator) {
        this.config = config;
        this.sohEstimator = sohEstimator;
        this.vehicleDataMonitor = VehicleDataMonitor.getInstance();
        this.gpsMonitor = GpsMonitor.getInstance();
        this.gearMonitor = GearMonitor.getInstance();
        this.running = false;
        this.consecutiveFailures = 0;
        this.lastUploadTime = 0;
        this.totalUploads = 0;
        this.failedUploads = 0;

        // Default client without proxy — proxy configured lazily on first upload
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .build();
    }
    
    /**
     * Get HTTP client with sing-box proxy if available.
     * Probes port 8119 once on first call, caches result.
     * Called from background thread only (never main thread).
     */
    private OkHttpClient getProxiedClient() {
        // Re-check proxy availability periodically (proxy may go up/down with ACC state)
        long now = System.currentTimeMillis();
        if (proxyChecked && (now - lastProxyCheckTime) < 60_000) return httpClient;
        proxyChecked = true;
        lastProxyCheckTime = now;
        
        boolean proxyAvailable = false;
        try {
            java.net.Socket probe = new java.net.Socket();
            probe.connect(new java.net.InetSocketAddress("127.0.0.1", 8119), 200);
            probe.close();
            proxyAvailable = true;
        } catch (Exception e) {
            // Proxy not available
        }
        
        if (proxyAvailable) {
            httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .proxy(new java.net.Proxy(java.net.Proxy.Type.HTTP,
                    new java.net.InetSocketAddress("127.0.0.1", 8119)))
                .build();
            logger.info("Using sing-box proxy for ABRP uploads");
        } else {
            httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .build();
            logger.info("No proxy, using direct connection for ABRP");
        }
        return httpClient;
    }

    /**
     * Initialize reflection-based device access using PermissionBypassContext.
     * Each device is initialized independently — if one fails, others still work.
     */
    public void init(Context context) {
        logger.info("Initializing reflection-based device access...");

        Context permissiveContext = createPermissiveContext(context);
        if (permissiveContext == null) {
            logger.error("Failed to create permissive context, reflection devices unavailable");
            return;
        }

        // BYDAutoEngineDevice — for getEnginePower()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.engine.BYDAutoEngineDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            engineDevice = getInstance.invoke(null, permissiveContext);
            getEnginePowerMethod = deviceClass.getMethod("getEnginePower");
            logger.info("BYDAutoEngineDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoEngineDevice unavailable: " + e.getMessage());
        }

        // BYDAutoChargingDevice — for getChargingGunState()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.charging.BYDAutoChargingDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            chargingDevice = getInstance.invoke(null, permissiveContext);
            getChargingGunStateMethod = deviceClass.getMethod("getChargingGunState");
            logger.info("BYDAutoChargingDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoChargingDevice unavailable: " + e.getMessage());
        }

        // BYDAutoInstrumentDevice — for getOutCarTemperature()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            instrumentDevice = getInstance.invoke(null, permissiveContext);
            getOutCarTemperatureMethod = deviceClass.getMethod("getOutCarTemperature");
            logger.info("BYDAutoInstrumentDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoInstrumentDevice unavailable: " + e.getMessage());
        }

        // BYDAutoStatisticDevice — for getTotalMileageValue()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.statistic.BYDAutoStatisticDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            statisticDevice = getInstance.invoke(null, permissiveContext);
            getTotalMileageValueMethod = deviceClass.getMethod("getTotalMileageValue");
            logger.info("BYDAutoStatisticDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoStatisticDevice unavailable: " + e.getMessage());
        }

        // BYDAutoSpeedDevice — for getCurrentSpeed()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.speed.BYDAutoSpeedDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            speedDevice = getInstance.invoke(null, permissiveContext);
            getCurrentSpeedMethod = deviceClass.getMethod("getCurrentSpeed");
            logger.info("BYDAutoSpeedDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoSpeedDevice unavailable: " + e.getMessage());
        }

        // BYDAutoAcDevice — for getTemprature(int) as fallback for ext_temp
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.ac.BYDAutoAcDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            acDevice = getInstance.invoke(null, permissiveContext);
            getTempratureMethod = deviceClass.getMethod("getTemprature", int.class);
            logger.info("BYDAutoAcDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoAcDevice unavailable: " + e.getMessage());
        }

        // BYDAutoGearboxDevice — for getGearboxAutoModeType()
        try {
            Class<?> deviceClass = Class.forName("android.hardware.bydauto.gearbox.BYDAutoGearboxDevice");
            Method getInstance = deviceClass.getMethod("getInstance", Context.class);
            gearboxDevice = getInstance.invoke(null, permissiveContext);
            getGearboxAutoModeTypeMethod = deviceClass.getMethod("getGearboxAutoModeType");
            logger.info("BYDAutoGearboxDevice initialized");
        } catch (Exception e) {
            logger.warn("BYDAutoGearboxDevice unavailable: " + e.getMessage());
        }

        logger.info("Device initialization complete");
    }

    // ==================== TELEMETRY COLLECTION ====================

    /**
     * Collect telemetry from all data sources and assemble ABRP Gold Standard payload.
     * Missing fields are omitted (ABRP accepts partial payloads).
     */
    public JSONObject collectTelemetry() {
        JSONObject payload = new JSONObject();

        try {
            // utc — current Unix timestamp in SECONDS
            payload.put("utc", System.currentTimeMillis() / 1000);

            // soc — battery State of Charge percentage
            BatterySocData socData = vehicleDataMonitor.getBatterySoc();
            double soc = -1;
            if (socData != null) {
                soc = socData.socPercent;
                payload.put("soc", soc);
            }

            // power — net battery power in kW (raw from BYD, no conversion)
            // Only reject garbage values (|value| > 300 kW is impossible for this car)
            // Fallback: ChargingStateMonitor for charging power when engine device returns 0
            try {
                double powerKw = 0;
                boolean gotEnginePower = false;

                if (engineDevice != null && getEnginePowerMethod != null) {
                    Object rawPower = getEnginePowerMethod.invoke(engineDevice);
                    if (rawPower instanceof Number) {
                        powerKw = ((Number) rawPower).doubleValue();
                        if (Math.abs(powerKw) > 300) {
                            logger.warn("Power garbage: " + powerKw + " kW, omitting");
                        } else {
                            gotEnginePower = true;
                        }
                    }
                }

                if (gotEnginePower) {
                    payload.put("power", powerKw);
                } else {
                    // Garbage value or unavailable — send 0 (ABRP needs this field)
                    ChargingStateData chargingData = vehicleDataMonitor.getChargingState();
                    boolean isCharging = chargingData != null &&
                        chargingData.status == ChargingStateData.ChargingStatus.CHARGING;
                    double monitorPower = chargingData != null ? chargingData.chargingPowerKW : 0;
                    if (isCharging && monitorPower > 0.1) {
                        payload.put("power", -monitorPower);
                    } else {
                        payload.put("power", 0);
                    }
                }
            } catch (Exception e) {
                logger.debug("Failed to get power: " + e.getMessage());
            }

            // speed — prefer BYDAutoSpeedDevice, fallback to GPS
            try {
                boolean speedSet = false;
                if (speedDevice != null && getCurrentSpeedMethod != null) {
                    Object speedResult = getCurrentSpeedMethod.invoke(speedDevice);
                    double speedKmh;
                    if (speedResult instanceof Integer) {
                        speedKmh = ((Integer) speedResult).doubleValue();
                    } else if (speedResult instanceof Double) {
                        speedKmh = (Double) speedResult;
                    } else if (speedResult instanceof Number) {
                        speedKmh = ((Number) speedResult).doubleValue();
                    } else {
                        speedKmh = 0;
                    }
                    payload.put("speed", speedKmh);
                    speedSet = true;
                }
                if (!speedSet && gpsMonitor.hasLocation()) {
                    // GpsMonitor.getSpeed() returns m/s, convert to km/h
                    double speedKmh = gpsMonitor.getSpeed() * 3.6;
                    payload.put("speed", speedKmh);
                }
            } catch (Exception e) {
                logger.debug("Failed to get speed: " + e.getMessage());
            }

            // lat, lon — GPS coordinates (only if valid location)
            if (gpsMonitor.hasLocation()) {
                payload.put("lat", gpsMonitor.getLatitude());
                payload.put("lon", gpsMonitor.getLongitude());
            }

            // is_charging — 1 if charging, 0 otherwise
            ChargingStateData chargingState = vehicleDataMonitor.getChargingState();
            boolean isCharging = false;
            if (chargingState != null) {
                isCharging = (chargingState.status == ChargingStateData.ChargingStatus.CHARGING);
                payload.put("is_charging", isCharging ? 1 : 0);
            }

            // is_dcfc — 1 if DC fast charging (gun state == 3), 0 otherwise
            // Gun states: 1=AC slow, 2=AC fast, 3=DC, 4=V2L discharge
            try {
                if (chargingDevice != null && getChargingGunStateMethod != null) {
                    int gunState = (Integer) getChargingGunStateMethod.invoke(chargingDevice);
                    payload.put("is_dcfc", gunState == 3 ? 1 : 0);
                    // V2L discharge — override is_charging to 0
                    if (gunState == 4) {
                        payload.put("is_charging", 0);
                    }
                }
            } catch (Exception e) {
                logger.debug("Failed to get charging gun state: " + e.getMessage());
            }

            // is_parked — 1 if gear is P (value 1), 0 otherwise
            boolean isParked = false;
            try {
                if (gearboxDevice != null && getGearboxAutoModeTypeMethod != null) {
                    int gear = (Integer) getGearboxAutoModeTypeMethod.invoke(gearboxDevice);
                    isParked = (gear == GearMonitor.GEAR_P);
                    payload.put("is_parked", isParked ? 1 : 0);
                } else {
                    // Fallback to GearMonitor
                    int gear = gearMonitor.getCurrentGear();
                    isParked = (gear == GearMonitor.GEAR_P);
                    payload.put("is_parked", isParked ? 1 : 0);
                }
            } catch (Exception e) {
                logger.debug("Failed to get gear state: " + e.getMessage());
                // Fallback to GearMonitor
                int gear = gearMonitor.getCurrentGear();
                isParked = (gear == GearMonitor.GEAR_P);
                payload.put("is_parked", isParked ? 1 : 0);
            }

            // elevation — GPS altitude (only if > 0)
            if (gpsMonitor.hasLocation()) {
                double altitude = gpsMonitor.getAltitude();
                if (altitude > 0) {
                    payload.put("elevation", altitude);
                }
            }

            // heading — GPS heading in degrees
            if (gpsMonitor.hasLocation()) {
                payload.put("heading", gpsMonitor.getHeading());
            }

            // ext_temp — external temperature in °C
            // Primary: BYD sensor (only if raw value is reasonable, i.e. -50 to 60)
            // Fallback: Open-Meteo weather API (GPS-based, cached 10 min)
            try {
                boolean tempSet = false;
                
                // Try BYD sensor first
                if (instrumentDevice != null && getOutCarTemperatureMethod != null) {
                    int rawTemp = (Integer) getOutCarTemperatureMethod.invoke(instrumentDevice);
                    if (rawTemp >= -50 && rawTemp <= 60) {
                        payload.put("ext_temp", rawTemp);
                        tempSet = true;
                        logger.debug("ext_temp: BYD sensor = " + rawTemp + "°C");
                    } else {
                        logger.debug("ext_temp: BYD sensor garbage (raw=" + rawTemp + "), trying weather API");
                    }
                }
                
                // Fallback: weather API if sensor gave garbage
                if (!tempSet && gpsMonitor.hasLocation()) {
                    double weatherTemp = getWeatherTemperature(
                        gpsMonitor.getLatitude(), gpsMonitor.getLongitude());
                    if (!Double.isNaN(weatherTemp)) {
                        payload.put("ext_temp", weatherTemp);
                        tempSet = true;
                    }
                }
            } catch (Exception e) {
                logger.debug("Failed to get external temperature: " + e.getMessage());
            }

            // odometer — total mileage in km
            // BYD getTotalMileageValue() returns int, typically in km
            // Some models return in 0.1 km — auto-detect based on magnitude
            try {
                if (statisticDevice != null && getTotalMileageValueMethod != null) {
                    int rawOdometer = (Integer) getTotalMileageValueMethod.invoke(statisticDevice);
                    double odometerKm;
                    if (rawOdometer > 1_000_000) {
                        // Likely in 0.1 km (e.g. 75800 = 7580.0 km)
                        odometerKm = rawOdometer / 10.0;
                    } else {
                        odometerKm = rawOdometer;
                    }
                    payload.put("odometer", odometerKm);
                }
            } catch (Exception e) {
                logger.debug("Failed to get odometer: " + e.getMessage());
            }

            // soh — State of Health percentage
            if (sohEstimator.hasEstimate()) {
                payload.put("soh", sohEstimator.getCurrentSoh());
            }

            // capacity — estimated full battery capacity: remainingKwh / (soc / 100)
            // Also feed SohEstimator with instantaneous readings
            double remainingKwh = vehicleDataMonitor.getBatteryRemainPowerKwh();
            if (remainingKwh > 0 && soc > 0) {
                double capacity = remainingKwh / (soc / 100.0);
                payload.put("capacity", capacity);

                // Feed SohEstimator
                sohEstimator.updateFromInstantaneous(remainingKwh, soc);
            }

        } catch (Exception e) {
            logger.error("Error collecting telemetry: " + e.getMessage());
        }

        lastTelemetrySnapshot = payload;
        return payload;
    }

    // ==================== UPLOAD LOGIC ====================

    /**
     * Upload telemetry payload to ABRP API.
     * POST as form-urlencoded with token and tlm fields.
     *
     * @return true if upload succeeded, false otherwise
     */
    public boolean uploadTelemetry(JSONObject payload) {
        String token = config.getUserToken();
        if (token == null || token.isEmpty()) {
            logger.warn("No user token configured, skipping upload");
            return false;
        }

        try {
            // ABRP API: token and api_key as query params, tlm as POST form body
            // api_key = hardcoded public key (identifies the app)
            // token = user's personal token (identifies the car)
            String apiKey = config.getApiKey();
            if (apiKey == null || apiKey.isEmpty()) {
                apiKey = PUBLIC_API_KEY;
            }
            
            okhttp3.HttpUrl url = okhttp3.HttpUrl.parse(ABRP_API_URL).newBuilder()
                    .addQueryParameter("token", token)
                    .addQueryParameter("api_key", apiKey)
                    .build();

            RequestBody formBody = new FormBody.Builder()
                    .add("tlm", payload.toString())
                    .build();

            Request request = new Request.Builder()
                    .url(url)
                    .post(formBody)
                    .build();

            try (Response response = getProxiedClient().newCall(request).execute()) {
                totalUploads++;
                String responseBody = response.body() != null ? response.body().string() : "";

                if (response.isSuccessful()) {
                    consecutiveFailures = 0;
                    lastUploadTime = System.currentTimeMillis();
                    logger.info("Upload OK (HTTP " + response.code() + "): " + responseBody);
                    return true;
                } else {
                    failedUploads++;
                    consecutiveFailures++;
                    // Invalidate proxy cache on HTTP error — may need to switch proxy mode
                    proxyChecked = false;
                    logger.warn("Upload failed: HTTP " + response.code() + " - " + responseBody);
                    return false;
                }
            }
        } catch (Exception e) {
            totalUploads++;
            failedUploads++;
            consecutiveFailures++;
            // Invalidate proxy cache on connection error — proxy state may have changed
            // (e.g., singbox started after we cached a direct connection)
            proxyChecked = false;
            logger.error("Upload error: " + e.getMessage());
            return false;
        }
    }

    // ==================== SCHEDULER ====================

    /**
     * Start the telemetry upload scheduler with adaptive interval.
     */
    public void start() {
        if (running) {
            logger.warn("Already running");
            return;
        }

        if (!config.isConfigured()) {
            logger.warn("Cannot start: no user token configured");
            return;
        }

        if (!config.isEnabled()) {
            logger.warn("Cannot start: ABRP telemetry is disabled");
            return;
        }

        logger.info("Starting ABRP telemetry service...");
        running = true;
        consecutiveFailures = 0;
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "AbrpTelemetry");
            t.setDaemon(true);
            return t;
        });

        scheduleNext(0);
        logger.info("ABRP telemetry service started");
    }

    /**
     * Stop the telemetry upload scheduler gracefully.
     */
    public void stop() {
        if (!running) {
            return;
        }

        logger.info("Stopping ABRP telemetry service...");
        running = false;

        if (scheduledTask != null) {
            scheduledTask.cancel(false);
            scheduledTask = null;
        }

        if (scheduler != null) {
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
            scheduler = null;
        }

        logger.info("ABRP telemetry service stopped");
    }

    /**
     * Schedule the next telemetry cycle after the given delay.
     */
    private void scheduleNext(long delaySeconds) {
        if (!running || scheduler == null || scheduler.isShutdown()) {
            return;
        }

        scheduledTask = scheduler.schedule(this::runCycle, delaySeconds, TimeUnit.SECONDS);
    }

    /**
     * Execute one telemetry cycle: collect → upload → schedule next.
     */
    private void runCycle() {
        if (!running) {
            return;
        }

        try {
            JSONObject payload = collectTelemetry();
            boolean success = uploadTelemetry(payload);

            long nextDelay;
            if (!success && consecutiveFailures > 0) {
                nextDelay = calculateBackoff(consecutiveFailures);
                logger.debug("Backoff: next upload in " + nextDelay + "s (failures: " + consecutiveFailures + ")");
            } else {
                nextDelay = getAdaptiveInterval();
            }

            scheduleNext(nextDelay);

        } catch (Exception e) {
            logger.error("Telemetry cycle error: " + e.getMessage());
            // Schedule retry even on unexpected errors
            scheduleNext(calculateBackoff(Math.max(1, consecutiveFailures)));
        }
    }

    /**
     * Get adaptive upload interval based on vehicle state.
     * 5s when driving (not parked AND not charging), 30s when parked or charging.
     */
    int getAdaptiveInterval() {
        boolean isParked = (gearMonitor.getCurrentGear() == GearMonitor.GEAR_P);
        boolean isCharging = false;

        ChargingStateData chargingState = vehicleDataMonitor.getChargingState();
        if (chargingState != null) {
            isCharging = (chargingState.status == ChargingStateData.ChargingStatus.CHARGING);
        }

        if (!isParked && !isCharging) {
            return DRIVING_INTERVAL_SECONDS;
        }
        return PARKED_INTERVAL_SECONDS;
    }

    /**
     * Calculate exponential backoff delay: min(5 * 2^(N-1), 300) seconds.
     */
    static long calculateBackoff(int consecutiveFailures) {
        if (consecutiveFailures <= 0) {
            return BACKOFF_BASE_SECONDS;
        }
        long delay = BACKOFF_BASE_SECONDS * (1L << (consecutiveFailures - 1));
        return Math.min(delay, BACKOFF_CAP_SECONDS);
    }

    // ==================== STATUS ====================

    /**
     * Get service status as JSON for IPC responses.
     */
    public JSONObject getStatus() {
        JSONObject status = new JSONObject();
        try {
            status.put("running", running);
            status.put("totalUploads", totalUploads);
            status.put("failedUploads", failedUploads);
            status.put("lastUploadTime", lastUploadTime);
            status.put("consecutiveFailures", consecutiveFailures);
            status.put("currentInterval", getAdaptiveInterval());
            if (lastTelemetrySnapshot != null) {
                status.put("lastTelemetry", lastTelemetrySnapshot);
            }
        } catch (Exception e) {
            logger.error("Error building status: " + e.getMessage());
        }
        return status;
    }

    // ==================== WEATHER API ====================

    /**
     * Get current temperature from Open-Meteo API using GPS coordinates.
     * Free, no API key required. Results cached for 10 minutes.
     * https://open-meteo.com/en/docs
     * 
     * @return temperature in °C, or NaN if unavailable
     */
    private double getWeatherTemperature(double lat, double lon) {
        long now = System.currentTimeMillis();
        
        // Return cached value if fresh
        if (!Double.isNaN(cachedWeatherTemp) && (now - lastWeatherFetchTime) < WEATHER_CACHE_MS) {
            return cachedWeatherTemp;
        }
        
        try {
            String url = String.format(java.util.Locale.US,
                "https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m",
                lat, lon);
            
            Request request = new Request.Builder()
                .url(url)
                .header("User-Agent", "OverDrive-ABRP/1.0")
                .build();
            
            // Use short timeout, same proxy logic as ABRP uploads
            OkHttpClient weatherClient = getProxiedClient().newBuilder()
                .connectTimeout(3, TimeUnit.SECONDS)
                .readTimeout(3, TimeUnit.SECONDS)
                .build();
            
            Response response = weatherClient.newCall(request).execute();
            if (response.isSuccessful() && response.body() != null) {
                String body = response.body().string();
                JSONObject json = new JSONObject(body);
                JSONObject current = json.optJSONObject("current");
                if (current != null) {
                    double temp = current.getDouble("temperature_2m");
                    cachedWeatherTemp = temp;
                    lastWeatherFetchTime = now;
                    logger.debug("ext_temp: weather API = " + String.format("%.1f", temp) + "°C");
                    return temp;
                }
            }
            response.close();
        } catch (Exception e) {
            logger.debug("Weather API failed: " + e.getMessage());
        }
        
        // Return stale cache if available, otherwise NaN
        return cachedWeatherTemp;
    }

    /**
     * Check if the service is currently running.
     */
    public boolean isRunning() {
        return running;
    }

    // ==================== HELPERS ====================

    /**
     * Create a PermissionBypassContext for BYD device access.
     * Follows the same pattern as AccSentryDaemon and CameraDaemon.
     */
    private Context createPermissiveContext(Context context) {
        try {
            return new PermissionBypassContext(context);
        } catch (Exception e) {
            logger.error("Failed to create PermissionBypassContext: " + e.getMessage());
            return null;
        }
    }

    /**
     * Context wrapper that bypasses BYD permission checks.
     * Required for accessing BYD hardware services without signature permissions.
     */
    private static class PermissionBypassContext extends android.content.ContextWrapper {
        public PermissionBypassContext(Context base) {
            super(base);
        }

        @Override
        public void enforceCallingOrSelfPermission(String permission, String message) {}

        @Override
        public void enforcePermission(String permission, int pid, int uid, String message) {}

        @Override
        public void enforceCallingPermission(String permission, String message) {}

        @Override
        public int checkCallingOrSelfPermission(String permission) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }

        @Override
        public int checkPermission(String permission, int pid, int uid) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }

        @Override
        public int checkSelfPermission(String permission) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }
    }
}
