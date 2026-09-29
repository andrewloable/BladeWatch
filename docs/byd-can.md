# BYD Head Unit → CAN Bus Access

Investigates whether the DiLink3 head unit (and therefore anything running on
it, including BladeWatch) can reach the vehicle CAN bus directly, or only
through BYD's mediated APIs.

**Date:** 2026-09-25
**Device:** BYD AUTO, `DiLink3.0`, SoC `QCM6125` (`ro.board.platform=trinket`), Android 10, build `QKQ1.210910.001 release-keys`
**Branch:** `feature/v1.4.0.0`
**Method:** Read-only `adb shell` enumeration (`ls`, `ps`, `dumpsys`, `getprop`) plus static analysis of HAL/framework/APK files already present on the vendor system image. No vehicle command was sent and no device state was changed.

**Motivation:** prompted by public reporting on BYD security issues in other
markets (Australia); this document establishes what the Philippine-market unit
actually exposes on its own evidence. The Australian report's specific claims
were not reviewed and are not compared against here.

---

## Bottom line

**The head unit's application processor is not a CAN node.** A separate MCU is
the actual CAN transceiver/gateway. Android reaches it only over a private SPI
link that exclusively BYD's own closed HAL code can open, and every
Android-level API on top of that link is gated by permissions signed to BYD's
own certificate. BladeWatch — even with full ADB/shell access — cannot open
that SPI link and cannot be granted those permissions. Its vehicle integration
is limited to whatever decoded signals BYD's own framework API chooses to
expose, which is exactly the surface already documented in
[byd-integrations.md](byd-integrations.md).

---

## 1. No general-purpose CAN interface exists

- No `/proc/net/can`, no `can` protocol entry in `/proc/net/protocols`.
- No CAN-related kernel modules loaded (`/proc/modules` has no
  `can`/`mcp251x`/`flexcan`/`m_can`, and `/sys/module` has nothing beyond
  `spidev`/`spidev_full_duplex`).
- `/sys/class/net` lists only the usual Android interfaces (`wlan0`, `rmnet_*`,
  loopback, tunnels) — no `can0`/`vcan0`.

There is no SocketCAN, so nothing on this build can `socket(AF_CAN, ...)` its
way onto the bus, privileged or not.

## 2. The real bridge is a private SPI link to an MCU

- One SPI device on the bus: `/sys/bus/spi/devices/spi0.0`, driver
  `spidevfd`, node `/dev/spidev_ivi`.
- SELinux label `u:object_r:spi_device:s0`, owned `system:system`. Shell
  (`uid=2000`) gets `Permission denied` opening it directly.
- `/sys/qc_mcu/{qc_wakeup_mcu,qc_reset_mcu,mcu_status,test}` exist for
  waking/resetting the MCU, also `Permission denied` to shell
  (`chmod 0660` in `/vendor/etc/init/hw/init.target.rc`, owner `system`).
- `BYDAutoPowerDevice`'s `wakeUpMcu()` / MCU-status API (already used by
  `AccSentryDaemon` for peripheral power control — see
  [architecture.md](architecture.md)) is the only MCU control surface
  BladeWatch can reach, and it is a power/wake control, not a data path.

The MCU — not the Android SoC — is the actual CAN transceiver. Everything
Android-side is downstream of it.

## 3. BYD's closed HAL owns that link exclusively

- `libbydauto.so` (JNI bridge) + `libbydautoservice.so` (AIDL service) load a
  HAL module (`hw_get_module`) named `auto.default.so`
  (`/system/lib64/hw/auto.default.so`).
- `auto.default.so` is the only binary observed to reference
  `/dev/spidev_ivi` and `/sys/qc_mcu/qc_wakeup_mcu`. Internal strings describe
  a "dynamic CAN ID table" (`setTable`, `update-can`, `query_can_pro`,
  `FeatureListCan`/`FeatureListCanFD`) — i.e. the HAL subscribes to specific
  CAN IDs by ID/sub-ID/channel and the MCU pushes back only what was asked
  for, not a raw bus tap.
- No source in this repo, and nothing found on the vendor image, opens that
  device node from anywhere other than this HAL.

## 4. The Android-facing API surface (what BladeWatch actually uses)

Two layers, both in `framework.jar`, both already reflected into by
`BydDataCollector` (see [byd-integrations.md](byd-integrations.md)):

1. **`android.hardware.BYDAutoManager`** — a generic native
   get/set-buffer/int/double/array bus (`nativeGetBuffer`, `nativeSetInt`,
   etc.) backed by the HAL above.
2. **`android.hardware.bydauto.*`** — ~50 domain-specific device classes built
   on layer 1 (`ac`, `adas`, `bodywork`, `charging`, `doorlock`, `engine`,
   `gearbox`, `instrument`, `power`, `speed`, `tyre`, …). This is the entire
   surface BladeWatch's compile-time stubs mirror.

Both layers deliver **decoded, named signals** (speed, gear, door state, SoC,
climate setpoint, …), not CAN frames.

## 5. BYD's own system apps get closer, but are still gated

`com.byd.CanDataCollect` (`/system/priv-app`,
`android:sharedUserId="android.uid.system"`, runs as `system` UID, SELinux
domain `system_app`) is BYD's own telemetry collector and is the one app
observed handling CAN-frame-shaped data:

- It registers `BYDAutoPowerDevice` and `BYDAutoBigDataDevice` listeners and
  asks the MCU for specific CAN IDs via
  `sendRegisterTable({canId, subId, channel, mode, flag})`.
- Frames it asked for arrive through
  `AbsBYDAutoBigDataListener.onWholeFrameDataChanged(byte[])` and are parsed
  in `recv_can()` as: 4-byte big-endian CAN ID, 1-byte sub-ID, 1-byte channel,
  up to 64 bytes of payload — pre-framed by the HAL/MCU, never raw electrical
  signaling.
- This is a **subscribe-only** API (`sendRegisterTable`); no send/injection
  call was found anywhere in this class.

Two further root-owned native daemons exist —
`acquisitionsrv` (`android.gui.IBYDAcquisitionService`) and
`diagnosticsrv` (`android.gui.IBYDDiagnosticService`) — backing the
`BYDACQUISITION_SEND_BUFFER`/`BYDACQUISITION_SEND_FILE`/`BYDDIAGNOSTIC_SEND_BUFFER`
permissions BladeWatch's manifest already requests.

## 6. Confirmed: BladeWatch cannot cross this gate

- `com.android.shell` holds **zero** of `BYDDIAGNOSTIC_SEND_BUFFER` or
  `BYDACQUISITION_SEND_BUFFER` on this device (`dumpsys package
com.android.shell`, checked directly this session).
- This matches the pre-existing finding for the wider `BYDAUTO_*` family
  (see the `bladewatch-adb-dependency-and-device-privileges` project memory):
  those permissions are `signature`-protected, owned by BYD's own
  `com.byd.auto.permission` certificate, and `pm grant` can never cross a
  different signing key — shell and BladeWatch's app UID are both on the
  wrong side of that boundary, regardless of ADB access.
- BladeWatch's manifest declarations for these permissions are therefore
  **dead**: requested, never grantable, because BladeWatch isn't signed with
  BYD's key.

Net result: BladeWatch's BYD integration is architecturally confined to the
decoded `bydauto.*` signal surface. It has no path to raw CAN frames, bus
sniffing, or write/injection — that all lives behind the SPI node and the
signature permissions, both confirmed closed on this exact unit.

---

## Scope — what this does *not* establish

- **MCU firmware security is untested.** Everything here characterizes the
  *Android-side* access boundary. Whether the MCU's own firmware or its SPI
  protocol has exploitable bugs is a different question needing different
  tooling (e.g. hardware access to the MCU itself), not attempted here.
- **No write/injection path was tested or attempted.** No frame was sent to
  the vehicle; no attempt was made to open `/dev/spidev_ivi` with elevated
  privilege, forge a BYD-signed permission grant, or reverse the MCU's SPI
  wire protocol for write access. This document is an attack-surface map, not
  a penetration test.
- **Physical/non-Android attack surfaces are out of scope** (e.g. an OBD-II
  port wired directly to the vehicle CAN bus bypasses the head unit
  entirely and is not evaluated here).
- **The Australian report's specific claims are not evaluated here** — they
  were not reviewed as part of this investigation.

## Relation to BladeWatch's own design

This confirms the existing design in
[byd-integrations.md](byd-integrations.md) is the only path available, not a
self-imposed limitation: raw CAN is architecturally unreachable from an app on
this unit, signed or not, rooted shell or not. BladeWatch's vehicle features
(state reads, climate, windows, lights, ADAS toggle, trunk, charge cap)
all go through the same `bydauto.*` device surface documented there, and that
remains the only surface that exists to use.
