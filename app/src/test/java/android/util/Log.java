package android.util;

/**
 * No-op android.util.Log for JVM unit tests (BladeWatch-17l7).
 *
 * The mockable android.jar THROWS from every Log method ("Method ... not mocked"), which made any
 * class that logs -- UnifiedConfigManager above all -- untestable here, so its cross-process file
 * I/O had never run under a test. Test classes precede that jar on the classpath, so this wins.
 * Logging is the only thing it fakes: every other Android call still throws as before.
 */
public final class Log {
    public static final int VERBOSE = 2;
    public static final int DEBUG = 3;
    public static final int INFO = 4;
    public static final int WARN = 5;
    public static final int ERROR = 6;
    public static final int ASSERT = 7;

    private Log() {}

    public static int v(String tag, String msg) { return 0; }
    public static int v(String tag, String msg, Throwable tr) { return 0; }
    public static int d(String tag, String msg) { return 0; }
    public static int d(String tag, String msg, Throwable tr) { return 0; }
    public static int i(String tag, String msg) { return 0; }
    public static int i(String tag, String msg, Throwable tr) { return 0; }
    public static int w(String tag, String msg) { return 0; }
    public static int w(String tag, String msg, Throwable tr) { return 0; }
    public static int w(String tag, Throwable tr) { return 0; }
    public static int e(String tag, String msg) { return 0; }
    public static int e(String tag, String msg, Throwable tr) { return 0; }
    public static int wtf(String tag, String msg) { return 0; }
    public static int wtf(String tag, String msg, Throwable tr) { return 0; }
    public static int println(int priority, String tag, String msg) { return 0; }
    public static boolean isLoggable(String tag, int level) { return false; }
    public static String getStackTraceString(Throwable tr) { return ""; }
}
