import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.Socket;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

/**
 * The BladeWatch throughput harness (BladeWatch-rdtj.9, reused unchanged by .18/.19): one method
 * for every path, so loopback, LAN TLS, tor and Pear numbers compare. See
 * docs/throughput-harness.md for the exact procedure. No dependencies: it runs on a desktop JVM
 * (`java Throughput.java ...`) and, dexed, on the head unit under app_process.
 *
 * Every line printed is one JSON object. Nothing secret is ever printed: the JWT is read from a
 * file (never argv, which `ps` shows) and the certificate pin is only compared.
 */
public class Throughput {

    public static void main(String[] args) throws Exception {
        if (args.length == 0) usage();
        Map<String, String> o = options(args);
        try {
            switch (args[0]) {
                case "video": video(o); break;
                case "rpc": rpc(o); break;
                case "clip": clip(o); break;
                case "sample": sample(o); break;
                default: usage();
            }
        } catch (Exception e) {
            // A JSON line, not a stack trace: under app_process an uncaught exception kills the
            // process before anything useful reaches stdout.
            System.out.println("{\"error\":\"" + String.valueOf(e.getMessage()).replace("\"", "'") + "\"}");
            System.exit(1);
        }
    }

    static void usage() {
        System.err.println(
            "video  --base URL --jwt-file F [--seconds 600] [--probe-every 2] [--probe StreamService/GetQuality] [--pin HEX] [--socks HOST:PORT]\n"
                + "rpc    --base URL --jwt-file F [--count 200] [--every 0] [--call SystemService/GetStatus] [--pin HEX] [--socks HOST:PORT]\n"
                + "clip   --base URL --jwt-file F [--count 3] [--bytes 16777216] [--pin HEX] [--socks HOST:PORT]\n"
                + "sample [--seconds 600] [--every 10] [--procs byd_cam_daemon,pear_daemon]   (on the car)");
        System.exit(2);
    }

    // ---------------------------------------------------------------- live video

    /**
     * Holds the live view (/ws) open for --seconds and reports, every 10 s and in total: frames
     * (messages carrying a slice -- SPS/PPS arrive as messages of their own and are not frames),
     * bytes, arrival gaps between frames, time to the first
     * IDR, and -- on a second connection -- a trivial call's round trips WHILE the video runs, which is
     * what queueing on the path adds. The stream has no timestamps, so there is no in-band frame
     * age; a frame dropped by the car's 60-frame queue shows up as delivered fps below loopback's.
     */
    static void video(Map<String, String> o) throws Exception {
        Target t = new Target(o);
        int seconds = Integer.parseInt(o.getOrDefault("seconds", "600"));
        double probeEvery = Double.parseDouble(o.getOrDefault("probe-every", "2"));
        // A trivial, in-memory call: the probe measures the PATH's queueing. GetStatus is not one --
        // it stalls ~700 ms whenever a cache refresh lands on the request (see docs), which would
        // swamp the tail this is meant to show.
        String probe = "/bladewatch.v1." + o.getOrDefault("probe", "StreamService/GetQuality");

        List<Double> probeMs = Collections.synchronizedList(new ArrayList<>());
        int[] probeErrors = {0};
        boolean[] stop = {false};
        Thread prober = new Thread(() -> {
            Http http = null;
            while (!stop[0]) {
                try {
                    if (http == null) http = new Http(t);
                    long s = System.nanoTime();
                    Http.Response r = http.post(probe, "{}");
                    if (r.status == 200) probeMs.add((System.nanoTime() - s) / 1e6);
                    else probeErrors[0]++;
                } catch (Exception e) {
                    probeErrors[0]++;
                    if (http != null) http.close();
                    http = null;
                }
                sleep((long) (probeEvery * 1000));
            }
            if (http != null) http.close();
        }, "probe");

        long t0 = System.nanoTime();
        Socket s = t.open();
        OutputStream out = s.getOutputStream();
        InputStream in = new BufferedInputStream(s.getInputStream(), 256 * 1024);
        byte[] key = new byte[16];
        new SecureRandom().nextBytes(key);
        out.write(("GET /ws?token=" + t.jwt + " HTTP/1.1\r\nHost: " + t.host + "\r\nUpgrade: websocket\r\n"
            + "Connection: Upgrade\r\nSec-WebSocket-Key: " + Base64.getEncoder().encodeToString(key)
            + "\r\nSec-WebSocket-Version: 13\r\n\r\n").getBytes(StandardCharsets.US_ASCII));
        out.flush();
        String status = readHeaders(in, new HashMap<>());
        if (!status.contains(" 101 ")) throw new IOException("no WebSocket upgrade: " + status);
        prober.start();

        long end = t0 + seconds * 1_000_000_000L;
        long lastArrival = 0, firstIdrNs = -1, bytes = 0, intervalBytes = 0;
        long intervalStart = System.nanoTime();
        int msgs = 0, frames = 0, intervalFrames = 0, idrs = 0, stalls = 0;
        double intervalMaxGap = 0;
        List<Double> gaps = new ArrayList<>();
        ByteArrayOutputStream msg = new ByteArrayOutputStream();
        s.setSoTimeout(15000);
        while (System.nanoTime() < end) {
            int b0 = in.read(), b1 = in.read();
            if (b0 < 0 || b1 < 0) throw new IOException("stream closed by the car after " + msgs + " messages");
            long len = b1 & 0x7F;
            if (len == 126) len = (in.read() << 8) | in.read();
            else if (len == 127) { len = 0; for (int i = 0; i < 8; i++) len = (len << 8) | in.read(); }
            if ((b1 & 0x80) != 0) readFully(in, new byte[4]); // servers do not mask; tolerate it
            byte[] payload = new byte[(int) len];
            readFully(in, payload);
            int opcode = b0 & 0x0F;
            if (opcode == 0x8) throw new IOException("the car closed the stream after " + msgs + " messages");
            if (opcode == 0x9 || opcode == 0xA) continue; // the car pings only when no frame came for 5 s
            msg.write(payload);
            if ((b0 & 0x80) == 0) continue; // more fragments follow
            long now = System.nanoTime();
            byte[] m = msg.toByteArray();
            msg.reset();
            msgs++;
            bytes += m.length; intervalBytes += m.length;
            int slice = sliceType(m);
            if (slice == 0) continue; // SPS/PPS only: counted in bytes, not a frame
            frames++; intervalFrames++;
            if (slice == 5) { idrs++; if (firstIdrNs < 0) firstIdrNs = now - t0; }
            if (lastArrival != 0) {
                double gap = (now - lastArrival) / 1e6;
                gaps.add(gap);
                if (gap > 500) stalls++;
                intervalMaxGap = Math.max(intervalMaxGap, gap);
            }
            lastArrival = now;
            if (now - intervalStart >= 10_000_000_000L) {
                double secs = (now - intervalStart) / 1e9;
                System.out.println(String.format(Locale.US,
                    "{\"t\":%.0f,\"fps\":%.1f,\"mbps\":%.3f,\"max_gap_ms\":%.0f}",
                    (now - t0) / 1e9, intervalFrames / secs, intervalBytes * 8 / secs / 1e6, intervalMaxGap));
                intervalStart = now; intervalFrames = 0; intervalBytes = 0; intervalMaxGap = 0;
            }
        }
        double secs = (System.nanoTime() - t0) / 1e9;
        stop[0] = true;
        try { out.write(new byte[] {(byte) 0x88, (byte) 0x80, 0, 0, 0, 0}); out.flush(); } catch (IOException ignored) { }
        s.close();
        prober.join(10000);
        System.out.println(String.format(Locale.US,
            "{\"summary\":\"video\",\"seconds\":%.0f,\"messages\":%d,\"frames\":%d,\"fps\":%.2f,\"mbps\":%.3f,"
                + "\"first_idr_ms\":%.0f,\"idrs\":%d,\"gap_ms\":%s,\"stalls_over_500ms\":%d,"
                + "\"loaded_rtt_ms\":%s,\"probe_errors\":%d}",
            secs, msgs, frames, frames / secs, bytes * 8 / secs / 1e6, firstIdrNs / 1e6, idrs,
            percentiles(gaps), stalls, percentiles(new ArrayList<>(probeMs)), probeErrors[0]));
    }

    /** 5 if the Annex-B message carries an IDR slice, 1 for a non-IDR slice, 0 for neither. */
    static int sliceType(byte[] m) {
        int found = 0;
        for (int i = 0; i + 3 < m.length; i++) {
            if (m[i] != 0 || m[i + 1] != 0 || m[i + 2] != 1) continue;
            int type = m[i + 3] & 0x1F;
            if (type == 5) return 5;
            if (type == 1) found = 1;
        }
        return found;
    }

    // ---------------------------------------------------------------- control RPC

    /**
     * --count calls on one kept-alive connection (connect time reported apart), back to back or
     * one every --every seconds -- paced, a run spans the car's periodic cache refreshes.
     */
    static void rpc(Map<String, String> o) throws Exception {
        Target t = new Target(o);
        int count = Integer.parseInt(o.getOrDefault("count", "200"));
        double every = Double.parseDouble(o.getOrDefault("every", "0"));
        String call = "/bladewatch.v1." + o.getOrDefault("call", "SystemService/GetStatus");
        List<Double> ms = new ArrayList<>();
        Map<Integer, Integer> statuses = new java.util.TreeMap<>();
        int errors = 0;
        long c0 = System.nanoTime();
        Http http = new Http(t);
        double connectMs = (System.nanoTime() - c0) / 1e6;
        long t0 = System.nanoTime();
        for (int i = 0; i < count; i++) {
            if (i > 0 && every > 0) sleep((long) (every * 1000));
            long s = System.nanoTime();
            try {
                int status = http.post(call, "{}").status;
                statuses.merge(status, 1, Integer::sum);
                if (status == 200) ms.add((System.nanoTime() - s) / 1e6);
                else errors++;
            } catch (IOException e) {
                errors++;
                http.close();
                http = new Http(t);
            }
        }
        double secs = (System.nanoTime() - t0) / 1e9;
        http.close();
        System.out.println(String.format(Locale.US,
            "{\"summary\":\"rpc\",\"calls\":%d,\"errors\":%d,\"statuses\":\"%s\",\"connect_ms\":%.0f,\"calls_per_s\":%.1f,\"rtt_ms\":%s}",
            count, errors, statuses, connectMs, count / secs, percentiles(ms)));
    }

    // ---------------------------------------------------------------- clip download

    /**
     * Downloads the first --bytes of the newest recording --count times, as a Range request, and
     * reports Mbit/s. A fixed size, not the whole file: recordings run to hundreds of MB, which
     * tor would need half an hour for, and every path must move the same amount to compare.
     */
    static void clip(Map<String, String> o) throws Exception {
        Target t = new Target(o);
        int count = Integer.parseInt(o.getOrDefault("count", "3"));
        long want = Long.parseLong(o.getOrDefault("bytes", "16777216"));
        Http http = new Http(t);
        Http.Response list = http.post("/bladewatch.v1.RecordingsService/ListRecordings", "{\"pageSize\":1}");
        Matcher m = Pattern.compile("\"videoUrl\"\\s*:\\s*\"([^\"]+)\"").matcher(new String(list.body, StandardCharsets.UTF_8));
        if (list.status != 200 || !m.find()) throw new IOException("no recording to download (ListRecordings " + list.status + ")");
        String path = m.group(1).replace("\\/", "/");
        http.close();
        List<Double> mbps = new ArrayList<>();
        long size = 0;
        for (int i = 0; i < count; i++) {
            Http h = new Http(t);
            long s = System.nanoTime();
            Http.Response r = h.get(path, "bytes=0-" + (want - 1));
            double secs = (System.nanoTime() - s) / 1e9;
            h.close();
            if (r.status != 206 && r.status != 200) throw new IOException("GET clip -> " + r.status);
            size = r.body.length;
            mbps.add(size * 8 / secs / 1e6);
        }
        System.out.println(String.format(Locale.US,
            "{\"summary\":\"clip\",\"bytes\":%d,\"downloads\":%d,\"mbps\":%s}", size, count, percentiles(mbps)));
    }

    // ---------------------------------------------------------------- car CPU and thermal

    /**
     * Run ON THE HEAD UNIT. Every --every seconds: whole-machine CPU busy %, each named process's
     * CPU as % of ONE core, the hottest thermal zone, and the lowest current/max CPU frequency
     * ratio across cores (below 1.0 under load = throttling or governor scaling).
     */
    static void sample(Map<String, String> o) throws Exception {
        int seconds = Integer.parseInt(o.getOrDefault("seconds", "600"));
        int every = Integer.parseInt(o.getOrDefault("every", "10"));
        String[] procs = o.getOrDefault("procs", "byd_cam_daemon").split(",");
        long hz = 100; // USER_HZ on Android/Linux
        long end = System.currentTimeMillis() + seconds * 1000L;
        long[] prevCpu = cpuTotals();
        Map<String, Long> prevProc = procTicks(procs);
        long prevWall = System.nanoTime();
        while (System.currentTimeMillis() < end) {
            sleep(every * 1000L);
            long[] cpu = cpuTotals();
            Map<String, Long> proc = procTicks(procs);
            double wall = (System.nanoTime() - prevWall) / 1e9;
            prevWall = System.nanoTime();
            double busy = 100.0 * ((cpu[0] - cpu[1]) - (prevCpu[0] - prevCpu[1])) / Math.max(1, cpu[0] - prevCpu[0]);
            StringBuilder p = new StringBuilder();
            for (String name : procs) {
                Long now = proc.get(name), before = prevProc.get(name);
                double pct = (now == null || before == null) ? -1 : 100.0 * (now - before) / hz / wall;
                if (p.length() > 0) p.append(',');
                p.append(String.format(Locale.US, "\"%s\":%.1f", name, pct));
            }
            System.out.println(String.format(Locale.US,
                "{\"cpu_busy_pct\":%.1f,\"proc_pct_of_core\":{%s},\"max_temp_c\":%.1f,\"min_freq_ratio\":%.2f}",
                busy, p, maxTempC(), minFreqRatio()));
            prevCpu = cpu;
            prevProc = proc;
        }
    }

    /** {total jiffies, idle+iowait jiffies} from /proc/stat's aggregate line. */
    static long[] cpuTotals() throws IOException {
        String[] f = firstLine(new File("/proc/stat")).trim().split("\\s+");
        long total = 0;
        for (int i = 1; i < f.length; i++) total += Long.parseLong(f[i]);
        return new long[] {total, Long.parseLong(f[4]) + Long.parseLong(f[5])};
    }

    /** utime+stime per process, matched on basename(argv[0]) -- the daemons' --nice-name. */
    static Map<String, Long> procTicks(String[] names) {
        Map<String, Long> out = new HashMap<>();
        File[] dirs = new File("/proc").listFiles();
        if (dirs == null) return out;
        for (File d : dirs) {
            if (!d.getName().matches("\\d+")) continue;
            try {
                String argv0 = new String(Files.readAllBytes(new File(d, "cmdline").toPath()), StandardCharsets.UTF_8).split("\0")[0];
                String base = argv0.substring(argv0.lastIndexOf('/') + 1);
                for (String n : names) {
                    if (!n.equals(base)) continue;
                    String stat = firstLine(new File(d, "stat"));
                    String[] f = stat.substring(stat.lastIndexOf(')') + 2).split(" ");
                    out.merge(n, Long.parseLong(f[11]) + Long.parseLong(f[12]), Long::sum);
                }
            } catch (Exception ignored) {
                // the process went away between listing and reading
            }
        }
        return out;
    }

    static double maxTempC() {
        double max = -1;
        File[] zones = new File("/sys/class/thermal").listFiles();
        if (zones == null) return max;
        for (File z : zones) {
            try {
                double v = Double.parseDouble(firstLine(new File(z, "temp")).trim());
                max = Math.max(max, v > 1000 ? v / 1000 : v);
            } catch (Exception ignored) {
                // not every entry is a zone with a readable temp
            }
        }
        return max;
    }

    static double minFreqRatio() {
        double min = -1;
        for (int i = 0; i < 16; i++) {
            File d = new File("/sys/devices/system/cpu/cpu" + i + "/cpufreq");
            try {
                double r = Double.parseDouble(firstLine(new File(d, "scaling_cur_freq")).trim())
                    / Double.parseDouble(firstLine(new File(d, "cpuinfo_max_freq")).trim());
                min = min < 0 ? r : Math.min(min, r);
            } catch (Exception ignored) {
                // offline core or no cpufreq
            }
        }
        return min;
    }

    // ---------------------------------------------------------------- transport

    /** Where to connect and how: plain HTTP, pinned TLS (https + --pin), optionally via SOCKS (tor). */
    static class Target {
        final String host;
        final int port;
        final boolean tls;
        final String pin;
        final InetSocketAddress socks;
        final String jwt;

        Target(Map<String, String> o) throws IOException {
            URI u = URI.create(req(o, "base"));
            tls = "https".equals(u.getScheme());
            host = u.getHost();
            port = u.getPort() > 0 ? u.getPort() : (tls ? 443 : 80);
            pin = o.get("pin");
            if (tls && pin == null) throw new IllegalArgumentException("https needs --pin: the car's certificate is self-signed");
            String s = o.get("socks");
            socks = s == null ? null : new InetSocketAddress(s.substring(0, s.lastIndexOf(':')), Integer.parseInt(s.substring(s.lastIndexOf(':') + 1)));
            jwt = new String(Files.readAllBytes(new File(req(o, "jwt-file")).toPath()), StandardCharsets.UTF_8).trim();
        }

        Socket open() throws Exception {
            Socket raw = socks == null ? new Socket() : new Socket(new Proxy(Proxy.Type.SOCKS, socks));
            // Unresolved: the proxy resolves the name, which the local resolver may not know.
            raw.connect(socks == null ? new InetSocketAddress(host, port) : InetSocketAddress.createUnresolved(host, port), 60000);
            raw.setTcpNoDelay(true);
            if (!tls) return raw;
            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, new TrustManager[] {new Pinned(pin)}, null);
            SSLSocket ssl = (SSLSocket) ctx.getSocketFactory().createSocket(raw, host, port, true);
            ssl.startHandshake();
            return ssl;
        }
    }

    /** Trusts exactly the certificate whose SHA-256 over the DER is --pin, as the companion does. */
    static class Pinned implements X509TrustManager {
        final String pin;

        Pinned(String pin) { this.pin = pin.toLowerCase(Locale.US); }

        public void checkServerTrusted(X509Certificate[] chain, String authType) throws java.security.cert.CertificateException {
            try {
                byte[] d = MessageDigest.getInstance("SHA-256").digest(chain[0].getEncoded());
                StringBuilder hex = new StringBuilder();
                for (byte b : d) hex.append(String.format("%02x", b));
                if (!hex.toString().equals(pin)) throw new java.security.cert.CertificateException("certificate does not match the pin");
            } catch (java.security.NoSuchAlgorithmException e) {
                throw new java.security.cert.CertificateException(e);
            }
        }

        public void checkClientTrusted(X509Certificate[] chain, String authType) { throw new UnsupportedOperationException(); }

        public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
    }

    /** Minimal HTTP/1.1 with keep-alive: Content-Length and chunked bodies. */
    static class Http {
        final Target t;
        final Socket s;
        final InputStream in;
        final OutputStream out;

        static class Response {
            int status;
            byte[] body;
        }

        Http(Target t) throws Exception {
            this.t = t;
            s = t.open();
            s.setSoTimeout(60000);
            in = new BufferedInputStream(s.getInputStream(), 256 * 1024);
            out = s.getOutputStream();
        }

        Response post(String path, String json) throws IOException {
            byte[] body = json.getBytes(StandardCharsets.UTF_8);
            return send("POST " + path + " HTTP/1.1\r\nHost: " + t.host + "\r\nAuthorization: Bearer " + t.jwt
                + "\r\nContent-Type: application/json\r\nConnect-Protocol-Version: 1\r\nContent-Length: " + body.length + "\r\n\r\n", body);
        }

        Response get(String path, String range) throws IOException {
            return send("GET " + path + " HTTP/1.1\r\nHost: " + t.host + "\r\nAuthorization: Bearer " + t.jwt
                + "\r\nRange: " + range + "\r\n\r\n", new byte[0]);
        }

        Response send(String head, byte[] body) throws IOException {
            out.write(head.getBytes(StandardCharsets.US_ASCII));
            out.write(body);
            out.flush();
            Map<String, String> h = new HashMap<>();
            String status = readHeaders(in, h);
            Response r = new Response();
            r.status = Integer.parseInt(status.split(" ")[1]);
            if ("chunked".equalsIgnoreCase(h.get("transfer-encoding"))) {
                ByteArrayOutputStream b = new ByteArrayOutputStream();
                while (true) {
                    int n = Integer.parseInt(readLine(in).split(";")[0].trim(), 16);
                    if (n == 0) { readLine(in); break; }
                    byte[] c = new byte[n];
                    readFully(in, c);
                    b.write(c);
                    readLine(in);
                }
                r.body = b.toByteArray();
            } else if (h.containsKey("content-length")) {
                r.body = new byte[Integer.parseInt(h.get("content-length"))];
                readFully(in, r.body);
            } else {
                r.body = readAll(in); // no length: the car closes the connection after the body
            }
            return r;
        }

        void close() {
            try { s.close(); } catch (IOException ignored) { }
        }
    }

    // ---------------------------------------------------------------- helpers

    static String readHeaders(InputStream in, Map<String, String> headers) throws IOException {
        String status = readLine(in);
        for (String l = readLine(in); !l.isEmpty(); l = readLine(in)) {
            int c = l.indexOf(':');
            if (c > 0) headers.put(l.substring(0, c).trim().toLowerCase(Locale.US), l.substring(c + 1).trim());
        }
        return status;
    }

    static String readLine(InputStream in) throws IOException {
        StringBuilder b = new StringBuilder();
        for (int c = in.read(); c != '\n'; c = in.read()) {
            if (c < 0) throw new IOException("connection closed");
            if (c != '\r') b.append((char) c);
        }
        return b.toString();
    }

    static void readFully(InputStream in, byte[] b) throws IOException {
        for (int off = 0; off < b.length; ) {
            int n = in.read(b, off, b.length - off);
            if (n < 0) throw new IOException("connection closed");
            off += n;
        }
    }

    static byte[] readAll(InputStream in) throws IOException {
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        byte[] buf = new byte[65536];
        for (int n; (n = in.read(buf)) > 0; ) b.write(buf, 0, n);
        return b.toByteArray();
    }

    static String firstLine(File f) throws IOException {
        String s = new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8);
        int nl = s.indexOf('\n');
        return nl < 0 ? s : s.substring(0, nl);
    }

    /** {"n":..,"p50":..,"p95":..,"p99":..,"max":..} over [v]. */
    static String percentiles(List<Double> v) {
        if (v.isEmpty()) return "{\"n\":0}";
        Collections.sort(v);
        return String.format(Locale.US, "{\"n\":%d,\"p50\":%.1f,\"p95\":%.1f,\"p99\":%.1f,\"max\":%.1f}",
            v.size(), pct(v, 50), pct(v, 95), pct(v, 99), v.get(v.size() - 1));
    }

    static double pct(List<Double> sorted, double p) {
        return sorted.get(Math.min(sorted.size() - 1, (int) Math.ceil(p / 100 * sorted.size()) - 1));
    }

    static Map<String, String> options(String[] a) {
        Map<String, String> o = new HashMap<>();
        for (int i = 1; i + 1 < a.length; i += 2) {
            if (!a[i].startsWith("--")) usage();
            o.put(a[i].substring(2), a[i + 1]);
        }
        return o;
    }

    static String req(Map<String, String> o, String k) {
        String v = o.get(k);
        if (v == null) throw new IllegalArgumentException("--" + k + " is required");
        return v;
    }

    static void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }
}
