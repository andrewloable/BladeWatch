package net.bladewatch.app.server;

import net.bladewatch.app.daemon.CameraDaemon;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Cross-process locale persistence for the BladeWatch daemon.
 *
 * <p>The HTTP server runs as UID 2000 (shell), which cannot read app-private
 * SharedPreferences. We use the same cross-UID-readable file pattern as
 * {@code ZrokLauncher}: a plain text file under {@code /data/local/tmp/.bladewatch/}
 * that both the daemon and the Kotlin settings UI can read and write.
 *
 * <p>The locale chosen here drives:
 * <ul>
 *   <li>The {@code locale} field in {@code /status} (so the WebView picks up
 *       changes made via the Android settings drawer on next poll).</li>
 *   <li>{@link Messages} catalog lookups for server-emitted JSON
 *       {@code "error"} / {@code "message"} fields.</li>
 *   <li>SRT sidecar generation language at recording close.</li>
 * </ul>
 */
public final class LocaleManager {

    /** All locales we ship translations for. en is the base. */
    public static final List<String> SUPPORTED = Arrays.asList(
            "en", "zh-CN", "zh-TW", "pt-BR", "es", "de", "fr", "it",
            "nb", "nl", "ja", "ko", "th", "vi", "hi", "tr", "ru"
    );

    private static final Set<String> SUPPORTED_SET = new HashSet<>(SUPPORTED);
    private static final String DEFAULT_LANG = "en";

    /**
     * Where the chosen locale lives (BladeWatch-vcur).
     *
     * <p>NOT {@code /data/local/tmp/.bladewatch/} any more. That directory is
     * {@code 0771 shell:shell}: the app UID gets {@code --x}, so it may traverse
     * in and read a world-readable file but may NOT create anything. The daemon
     * (uid 2000) could write there, the two in-car UIs could not, and the failure
     * was swallowed — so picking a language appeared to work and was silently
     * lost on the next launch.
     *
     * <p>This directory is created by {@code setupStorageDirectories()} and both
     * APKs already write {@code bladewatch_config.json} into it; the daemon can
     * read it because shell is in {@code sdcard_rw}. A locale tag is not a
     * secret, so the sdcardfs permission weakness tracked in BladeWatch-078u
     * does not apply.
     */
    private static final String STATE_DIR = "/storage/emulated/0/BladeWatch/data";
    private static final String STATE_FILE = STATE_DIR + "/locale";

    /**
     * The pre-BladeWatch-vcur location, still READ so a device whose web UI
     * already persisted a language keeps it. The web picker goes through the
     * daemon, which runs as shell and so could always write here.
     */
    private static final String LEGACY_STATE_FILE = "/data/local/tmp/.bladewatch/locale";

    /**
     * Whether the last {@link #set}/{@link #setAuto} actually reached disk.
     * Exposed so the picker can tell the user instead of reverting silently,
     * which is what made BladeWatch-vcur hard to notice.
     */
    private static volatile boolean lastPersistOk = true;

    /** In-memory cache so we don't disk-read on every request. */
    private static volatile String cachedLocale;
    private static volatile long cachedAt;
    private static final long CACHE_TTL_MS = 5_000L;


    /** The raw persisted tag, preferring the current path over the legacy one. */
    private static String readRawFile() {
        for (String path : new String[] { STATE_FILE, LEGACY_STATE_FILE }) {
            try {
                File f = new File(path);
                if (!f.exists() || !f.canRead()) continue;
                try (FileInputStream fis = new FileInputStream(f)) {
                    byte[] buf = new byte[16];
                    int n = fis.read(buf);
                    if (n > 0) {
                        String tag = new String(buf, 0, n, "UTF-8").trim();
                        if (!tag.isEmpty()) return tag;
                    }
                }
            } catch (Exception e) {
                CameraDaemon.log("LocaleManager.readRawFile(" + path + "): " + e.getMessage());
            }
        }
        return null;
    }

    /**
     * Write the tag, returning whether it reached disk. Callers must not assume
     * success: the whole point of BladeWatch-vcur is that this can fail.
     */
    private static boolean writeRawFile(String tag) {
        try {
            File dir = new File(STATE_DIR);
            if (!dir.exists() && !dir.mkdirs()) {
                CameraDaemon.log("LocaleManager: cannot create " + STATE_DIR);
                return false;
            }
            try (FileOutputStream fos = new FileOutputStream(STATE_FILE)) {
                fos.write(tag.getBytes("UTF-8"));
            }
            // Readable by the other process too — daemon and both UIs share it.
            new File(STATE_FILE).setReadable(true, false);
            return true;
        } catch (Exception e) {
            CameraDaemon.log("LocaleManager.writeRawFile: " + e.getMessage());
            return false;
        }
    }

    /** True when the last persist attempt reached disk. */
    public static boolean lastPersistSucceeded() {
        return lastPersistOk;
    }

    private LocaleManager() {}

    /**
     * Resolve any tag (e.g. "zh-Hans-CN", "pt", "no") to one of {@link #SUPPORTED}.
     * Mirrors the JS-side {@code resolveLang} so server and client agree.
     */
    public static String resolve(String raw) {
        if (raw == null || raw.isEmpty()) return DEFAULT_LANG;
        String lower = raw.toLowerCase();
        // Exact match first
        for (String s : SUPPORTED) {
            if (s.toLowerCase().equals(lower)) return s;
        }
        // Common region/script aliases
        if (lower.startsWith("zh-hans") || lower.equals("zh-cn") || lower.equals("zh")) return "zh-CN";
        if (lower.startsWith("zh-hant") || lower.equals("zh-tw") || lower.equals("zh-hk")) return "zh-TW";
        if (lower.startsWith("pt")) return "pt-BR";
        if (lower.startsWith("no") || lower.startsWith("nn")) return "nb";
        // Bare-language fallback
        int dash = lower.indexOf('-');
        String bare = dash > 0 ? lower.substring(0, dash) : lower;
        for (String s : SUPPORTED) {
            String b = s.toLowerCase();
            int d = b.indexOf('-');
            if ((d > 0 ? b.substring(0, d) : b).equals(bare)) return s;
        }
        return DEFAULT_LANG;
    }

    public static boolean isSupported(String tag) {
        return tag != null && SUPPORTED_SET.contains(tag);
    }

    /**
     * Sentinel written to the state file when the user picks "Auto (follow
     * system)". Distinguishes "user explicitly wants system locale" from
     * "user has never chosen" (latter also resolves to system).
     */
    public static final String AUTO_TAG = "auto";

    /**
     * Raw persisted value: a supported tag, {@link #AUTO_TAG}, or {@code null}
     * if nothing has been written yet. Used by the picker UI so it can show
     * the "Auto" row as currently selected when appropriate. The HTTP server
     * and message catalogs should keep using {@link #get()}.
     */
    public static String getRaw() {
        synchronized (LocaleManager.class) {
            String tag = readRawFile();
            if (tag != null && (AUTO_TAG.equals(tag) || isSupported(tag))) return tag;
            return null;
        }
    }

    /**
     * Returns true when the user has explicitly chosen "Auto", or when no
     * choice has ever been persisted. In both cases the active locale should
     * follow the device default (BCP-47 of {@code Locale.getDefault()}).
     */
    public static boolean isAuto() {
        String raw = getRaw();
        return raw == null || AUTO_TAG.equals(raw);
    }

    /**
     * Persist the "follow system" sentinel. After this, {@link #get()} will
     * resolve via the device default each call (cache invalidated on write).
     */
    public static void setAuto() {
        synchronized (LocaleManager.class) {
            lastPersistOk = writeRawFile(AUTO_TAG);
            cachedLocale = null;
            cachedAt = 0L;
            Messages.invalidate();
        }
    }

    /**
     * Parse an HTTP {@code Accept-Language} header (e.g.
     * {@code "fr-CA,fr;q=0.9,en;q=0.8"}) and return the first supported locale.
     * Used on first request only — once the user has explicitly chosen a
     * locale via the picker we honour {@link #get()} instead.
     */
    public static String fromAcceptLanguage(String header) {
        if (header == null || header.isEmpty()) return DEFAULT_LANG;
        String[] parts = header.split(",");
        for (String p : parts) {
            String tag = p.trim();
            int semi = tag.indexOf(';');
            if (semi > 0) tag = tag.substring(0, semi).trim();
            if (tag.isEmpty()) continue;
            String resolved = resolve(tag);
            // resolve() returns 'en' both for "I want English" and "I want
            // something we don't support"; only treat the latter as a miss.
            if (!resolved.equals(DEFAULT_LANG) || tag.toLowerCase().startsWith("en")) {
                return resolved;
            }
        }
        return DEFAULT_LANG;
    }

    /**
     * Resolve the active locale. Returns one of {@link #SUPPORTED}.
     *
     * <p>Resolution order:
     * <ol>
     *   <li>Persisted user pick (specific tag) → that tag.</li>
     *   <li>Persisted "Auto" sentinel OR no file → resolve {@link
     *       java.util.Locale#getDefault()} via {@link #resolve(String)}.</li>
     * </ol>
     *
     * <p>This way the HTTP server and {@link Messages} always see a real,
     * supported tag without having to know about Auto.
     */
    public static String get() {
        long now = System.currentTimeMillis();
        if (cachedLocale != null && now - cachedAt < CACHE_TTL_MS) return cachedLocale;
        synchronized (LocaleManager.class) {
            String resolved = DEFAULT_LANG;
            try {
                String raw = readRawFile();
                if (raw != null && !raw.isEmpty() && !AUTO_TAG.equals(raw) && isSupported(raw)) {
                    resolved = raw;
                } else {
                    // Auto / unset → resolve from Locale.getDefault(). The
                    // daemon process inherits the BYD system locale at fork.
                    java.util.Locale def = java.util.Locale.getDefault();
                    String tag = def.getLanguage();
                    String region = def.getCountry();
                    if (region != null && !region.isEmpty()) tag = tag + "-" + region;
                    resolved = resolve(tag);
                }
            } catch (Exception e) {
                CameraDaemon.log("LocaleManager.get: " + e.getMessage());
            }
            cachedLocale = resolved;
            cachedAt = now;
            return resolved;
        }
    }

    /**
     * Persist a new locale. Returns the resolved tag actually written
     * (so callers can echo it back even if the input was an alias).
     *
     * <p>The literal string {@code "auto"} writes the {@link #AUTO_TAG}
     * sentinel so subsequent {@link #get()} calls follow the system
     * locale; the returned tag is then the system-resolved language so
     * callers can show the right UI feedback.
     */
    public static String set(String tag) {
        if (tag != null && AUTO_TAG.equalsIgnoreCase(tag.trim())) {
            setAuto();
            return get();
        }
        String resolved = resolve(tag);
        synchronized (LocaleManager.class) {
            lastPersistOk = writeRawFile(resolved);
            cachedLocale = resolved;
            cachedAt = System.currentTimeMillis();
            // Drop any cached Messages catalog so the next server-side
            // i18n lookup loads the new locale's JSON.
            Messages.invalidate();
        }
        return resolved;
    }
}
