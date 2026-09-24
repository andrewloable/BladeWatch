# Throughput harness

How BladeWatch measures a remote-access path, so that every path is measured the same way.
Defined by BladeWatch-rdtj.9 (the loopback and LAN TLS baselines) and reused unchanged by
BladeWatch-rdtj.18 (Pear live video) and rdtj.19 (Pear control and clips). Numbers taken any
other way cannot be compared with these, so change the harness only together with a re-run of
every baseline.

The harness is one dependency-free Java file, [tools/throughput/Throughput.java](../tools/throughput/Throughput.java).
It runs on a desktop JVM and, dexed, on the head unit under `app_process`, so the loopback run
and the remote runs use the same code. Every line it prints is one JSON object. It never prints
a secret: the JWT is read from a file (argv is visible in `ps`) and the certificate pin is only
compared.

## What is measured

| Mode | What it does | Reported |
|---|---|---|
| `video` | Holds the live view (`/ws`) open for `--seconds`; a second connection calls `StreamService/GetQuality` (`--probe`) every `--probe-every` seconds while the video runs | per 10 s: fps, Mbit/s, max gap; summary: frames, fps, Mbit/s, first IDR ms, IDR count, frame-gap p50/p95/p99/max, stalls over 500 ms, loaded RTT p50/p95/p99/max, probe errors |
| `rpc` | `--count` `SystemService/GetStatus` calls (`--call`) on one kept-alive connection, back to back or one every `--every` s | connect ms, calls/s, RTT p50/p95/p99/max, errors |
| `clip` | Downloads the first `--bytes` of the newest recording `--count` times (a Range request) | Mbit/s p50/p95/max |
| `sample` | ON THE CAR, every `--every` s | whole-machine CPU busy %, each named process's CPU as % of ONE core, hottest thermal zone °C, lowest current/max CPU frequency ratio |

Definitions, because the stream dictates them:

- **A frame** is a WebSocket message carrying an H.264 slice (NAL type 1 or 5). SPS/PPS arrive as
  messages of their own; they count toward bytes, not frames. The car sends each encoder output
  as one message (fragmented into continuation frames when large).
- **Dropped frames.** The car drops frames when its per-viewer queue of 60 is full, and the stream
  carries no sequence numbers. So a path's dropped-frame rate is `1 - fps(path) / fps(loopback)`
  over the same 10-minute window at the same quality: loopback is the car's production rate.
- **Latency.** The stream carries no timestamps, so there is no in-band frame age. Reported
  instead: `loaded_rtt_ms` -- a trivial RPC's round trip WHILE the video runs, which is what
  queueing on the path adds to every frame -- against the unloaded `rpc` round trip, plus
  `first_idr_ms` (connect to the first decodable frame, the viewer's "time to picture").
  A path that cannot carry the stream shows up as fps below loopback and growing gaps, not as a
  latency number.
- **Stalls**: gaps between frames over 500 ms.
- **Why the probe is not `GetStatus`.** A probe must cost nothing on the car, or a handler's own
  time hides the path's. `GetStatus` used to stall about 700 ms whenever its battery refresh --
  an IPC round trip to the surveillance daemon -- landed on the request (loopback, no video:
  p50 5.7 ms, p99 703 ms over 120 calls paced 0.5 s apart; during live view it showed at p95).
  BladeWatch-1996 moved that refresh off the request -- and the network refresh, which ran
  `dumpsys wifi` inline every 10 s and stalled it 600-850 ms on the same schedule. After both
  (head unit, loopback, no video, 2026-09-24): p50 6.2 ms, p95 19.5 ms, p99 64 ms, max 68 ms
  over 120 calls paced 0.5 s apart; a 200-call burst ran at 583 calls/s, p50 1.4 ms. The probe
  still stays
  `StreamService/GetQuality`, which reads memory only (loopback during video: p50 4.8 ms, max
  18 ms), so baselines taken before and after compare.

There is no tor baseline, by the owner's decision (2026-09-24): tor is being removed
(rdtj.12), so Pear is compared against loopback and LAN TLS. The harness can still reach a
SOCKS proxy (`--socks HOST:PORT`, which resolves names remotely) should any other path ever
need measuring.

## Building

```bash
javac --release 11 -d /tmp/tp/classes tools/throughput/Throughput.java
"$ANDROID_HOME/build-tools/<version>/d8" --release --min-api 29 --output /tmp/tp/dex /tmp/tp/classes/*.class
adb -s $CAR_IP:5555 push /tmp/tp/dex/classes.dex /data/local/tmp/throughput.dex
```

On the car: `CLASSPATH=/data/local/tmp/throughput.dex app_process /system/bin Throughput <mode> ...`.
On the Mac: `java -cp /tmp/tp/classes Throughput <mode> ...`.

## Procedure (identical for every path)

1. Record the head unit build (`getprop ro.build.fingerprint`, BladeWatch `versionName`), the
   stream quality (`StreamService/GetQuality` -> `current`) and the network conditions. Do NOT
   change the quality during a run; if a lower one is needed to sustain the stream, that is a
   result -- re-run and record which.
2. Put a session JWT in a mode-600 file where the client runs. Delete it afterwards.
3. Start the car sampler for the whole window, detached on the car so it outlives adb:
   `setsid nohup sh -c "... Throughput sample --seconds 620 --every 10 --procs byd_cam_daemon[,pear_daemon] > FILE" &`.
   Name the path's own process too: `pear_daemon` for Pear.
4. `video --seconds 600 --probe-every 2` -- the full 10 minutes; a short burst hides buffer growth
   and thermal throttling, the two failure modes that matter.
5. Separately, not during the video: `rpc --count 200` (a burst: per-call cost on a warm
   connection), `rpc --count 120 --every 0.5` (paced over a minute, so it spans the car's cache
   refreshes, as a dashboard polling it does), and `clip --count 3 --bytes 16777216`.
6. Only one live-view client at a time: the encoder feeds one stream callback, so the in-car UI's
   live view and the harness cannot both run.

Per path:

| Path | Where the client runs | `--base` and extras |
|---|---|---|
| Loopback (in-car) | on the car | `http://127.0.0.1:8080` |
| LAN TLS | a machine on the car's network, LAN access on | `https://<car-ip>:8443 --pin <tlsFp from the pairing QR>` |
| Pear (.18/.19) | a companion on a DIFFERENT network | the companion `LocalGateway`'s `http://127.0.0.1:<port>`, route forced to Pear |

## Results

The numbers live in the close reasons of rdtj.9 (baselines), rdtj.18 and rdtj.19 (Pear), as
tables with the build, quality and network conditions.
