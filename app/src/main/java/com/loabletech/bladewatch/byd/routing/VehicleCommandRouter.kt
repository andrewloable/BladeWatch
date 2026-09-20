package net.bladewatch.app.byd.routing

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.server.Messages

/**
 * Routes vehicle control commands to the local BYD SDK ([BydDataCollector]).
 *
 * Each [VehicleCommand] declares whether it has a local SDK path and
 * provides the per-command execution. Commands with no local primitive on this
 * platform (e.g. remote lock/unlock, find-car, flash, battery heat, smart
 * charging — no local primitive on this generation) resolve to
 * [Outcome.NOT_SUPPORTED]. Every dispatch returns a structured
 * [CommandResult] so callers can render a "sent via direct connection"
 * badge to the UI.
 */
class VehicleCommandRouter private constructor() {

    // ── Public types ────────────────────────────────────────────────────

    enum class Outcome { SUCCESS, FAILED, NOT_SUPPORTED, RATE_LIMITED, AUTH_REQUIRED, BLOCKED_UNSAFE }

    /** Path actually executed. */
    enum class Path { SDK, NONE }

    class CommandResult private constructor(
        @JvmField val outcome: Outcome,
        @JvmField val path: Path,
        displayMessage: String?,
        @JvmField val latencyMs: Long,
        @JvmField val error: Throwable?
    ) {
        @JvmField
        val displayMessage: String = displayMessage ?: ""

        fun pathString(): String = when (path) {
            Path.SDK -> "local"
            else -> "none"
        }

        companion object {
            @JvmStatic
            fun success(path: Path, msg: String?, latencyMs: Long): CommandResult =
                CommandResult(Outcome.SUCCESS, path, msg, latencyMs, null)

            @JvmStatic
            fun failed(path: Path, msg: String?, latencyMs: Long, t: Throwable?): CommandResult =
                CommandResult(Outcome.FAILED, path, msg, latencyMs, t)

            @JvmStatic
            fun notSupported(msg: String?): CommandResult =
                CommandResult(Outcome.NOT_SUPPORTED, Path.NONE, msg, 0, null)

            @JvmStatic
            fun blockedUnsafe(msg: String?): CommandResult =
                CommandResult(Outcome.BLOCKED_UNSAFE, Path.NONE, msg, 0, null)
        }
    }

    // ── Command base ────────────────────────────────────────────────────

    /**
     * Base class for vehicle commands. Subclasses with a local primitive
     * override [hasSdkPath] to return true and implement
     * [executeViaSdk]. Commands without a local path
     * inherit the defaults and resolve to NOT_SUPPORTED.
     */
    abstract class VehicleCommand {
        abstract fun name(): String

        /** Whether this command has a local SDK primitive. */
        open fun hasSdkPath(): Boolean = false

        /** Run via SDK. Returns true on success, false on failure. */
        open fun executeViaSdk(collector: BydDataCollector): Boolean = false

        /**
         * True only for a command where giving control back to the driver is never the
         * unsafe direction, so a BLOCK_MOVING/BLOCK_UNKNOWN motion decision must not prevent
         * it from running (BladeWatch-2000.3 — screen ON specifically: "screen off" stays
         * gated normally). Default false. This does not skip the motion interlock
         * evaluation itself (see [execute]) — every command's decision is still
         * computed and logged, only the BLOCKING policy is directional for the one command
         * that opts in.
         */
        open fun allowedWhileUnsafe(): Boolean = false
    }

    // ── Concrete commands ───────────────────────────────────────────────
    // REMOVED with the BYD cloud path (BladeWatch-c2h1): Lock, Unlock, FindCar,
    // FlashLights, BatteryHeat, ChargeSchedule and TrunkOpen. Each had NO local SDK
    // primitive on this generation, so after 61b4d7f deleted the cloud they could
    // only ever return NOT_SUPPORTED. Keeping them was dead surface that read like a
    // capability. Do not reintroduce them without a real local primitive.

    class ClimateOnCommand(@JvmField val tempCelsius: Double) : VehicleCommand() {
        override fun name(): String = "climate-on"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcPower(true)
    }

    class ClimateOffCommand : VehicleCommand() {
        override fun name(): String = "climate-off"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcPower(false)
    }

    class CloseAllWindowsCommand : VehicleCommand() {
        override fun name(): String = "windows-close-all"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAllWindowsCommand(2) // 2 = close
    }

    // ── Trunk ───────────────────────────────────────────────────────────

    // NO TrunkOpenCommand. Opening used to be cloud unlock followed by the SDK
    // tailgate motor, with the router firing the motor ONLY on unlock SUCCESS. The
    // cloud unlock died in 61b4d7f, leaving an UNGATED openTailgate() that could be
    // declined by the body controller or trip the alarm on a locked car. Removed in
    // BladeWatch-c2h1 rather than shipped ungated. Close and stop stay: both are
    // real local primitives and neither opens anything.

    class TrunkCloseCommand : VehicleCommand() {
        override fun name(): String = "trunk-close"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.closeTailgate()
    }

    class TrunkStopCommand : VehicleCommand() {
        override fun name(): String = "trunk-stop"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.stopTailgate()
    }

    // ── SDK commands ────────────────────────────────────────────────────

    class WindowMoveCommand(
        @JvmField val area: Int,
        @JvmField val action: Int,
        @JvmField val targetPercent: Int?
    ) : VehicleCommand() {
        override fun name(): String = "window-move"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean {
            val pct = targetPercent
            if (pct != null && area == 0) return collector.moveSideWindowsToPercent(pct)
            if (pct != null) return collector.moveWindowToPercent(area, pct)
            if (area == 0) return collector.setAllWindowsCommand(action)
            return collector.setWindowCommand(area, action)
        }
    }

    class ClimateSetTempCommand(
        @JvmField val zone: Int,
        @JvmField val tempCelsius: Double
    ) : VehicleCommand() {
        override fun name(): String = "climate-temp"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcTemperature(zone, tempCelsius)
    }

    class ClimateSetFanCommand(@JvmField val level: Int) : VehicleCommand() {
        override fun name(): String = "climate-fan"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcFanLevel(level)
    }

    /** BladeWatch-2000.1. */
    class FrontDefrostCommand(@JvmField val on: Boolean) : VehicleCommand() {
        override fun name(): String = "climate-front-defrost"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setFrontDefrost(on)
    }

    /** BladeWatch-2000.1. */
    class RearDefrostCommand(@JvmField val on: Boolean) : VehicleCommand() {
        override fun name(): String = "climate-rear-defrost"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setRearDefrost(on)
    }

    /**
     * BladeWatch-2000.1. Raw SDK value, carried through unlabeled -- its meaning is not
     * established in source (see docs/byd-integrations.md); no UI offers a labelled picker.
     */
    class ClimateSetWindModeCommand(@JvmField val mode: Int) : VehicleCommand() {
        override fun name(): String = "climate-wind-mode"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcWindMode(mode)
    }

    /**
     * BladeWatch-2000.1. Raw SDK value -- same "unlabeled" reasoning as
     * [ClimateSetWindModeCommand].
     */
    class ClimateSetCycleModeCommand(@JvmField val mode: Int) : VehicleCommand() {
        override fun name(): String = "climate-cycle-mode"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setAcCycleMode(mode)
    }

    class ClimateMaxCoolingCommand(
        @JvmField val enabled: Boolean,
        @JvmField val hasRestore: Boolean,
        @JvmField val restoreTempCelsius: Double,
        @JvmField val restoreFanLevel: Int,
        @JvmField val restorePowerOn: Boolean
    ) : VehicleCommand() {
        override fun name(): String = "climate-max-cooling"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setMaxCooling(
                enabled, hasRestore, restoreTempCelsius, restoreFanLevel, restorePowerOn
            )
    }

    /** Seat heat — local SDK primitive (position + level). */
    class SeatHeatCommand(
        @JvmField val position: Int,
        @JvmField val level: Int,
        @JvmField val driverHeat: Int,
        @JvmField val driverVent: Int,
        @JvmField val passengerHeat: Int,
        @JvmField val passengerVent: Int
    ) : VehicleCommand() {
        override fun name(): String = "seat-heat"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setSeatHeating(position, level)
    }

    /** Seat ventilation — local SDK primitive (position + level). */
    class SeatVentCommand(
        @JvmField val position: Int,
        @JvmField val level: Int,
        @JvmField val driverHeat: Int,
        @JvmField val driverVent: Int,
        @JvmField val passengerHeat: Int,
        @JvmField val passengerVent: Int
    ) : VehicleCommand() {
        override fun name(): String = "seat-vent"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setSeatVentilation(position, level)
    }

    class SeatMemoryCommand(@JvmField val position: Int) : VehicleCommand() {
        override fun name(): String = "seat-memory"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setSeatMemoryPosition(position)
    }

    class LightsCommand(@JvmField val drlOn: Boolean) : VehicleCommand() {
        override fun name(): String = "lights"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setDayTimeLight(drlOn)
    }

    class AdasSpeedLimitWarningCommand(@JvmField val enabled: Boolean) : VehicleCommand() {
        override fun name(): String = "adas-slw"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setSpeedLimitWarning(enabled)
    }

    /**
     * BEV charge cap — BYDAutoChargingDevice.setChargeStopCapacityState (50..100%).
     * Collector probes the framework on first write and reports false if the
     * value didn't stick (the documented Seal HAL behavior).
     */
    class ChargeCapPercentCommand(@JvmField val percent: Int) : VehicleCommand() {
        override fun name(): String = "charge-cap-percent"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setChargeCapPercent(percent)
    }

    /** BEV charge cap on/off — BYDAutoChargingDevice.setChargeStopSwitchState. */
    class ChargeCapToggleCommand(@JvmField val enabled: Boolean) : VehicleCommand() {
        override fun name(): String = "charge-cap-toggle"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setChargeCapEnabled(enabled)
    }

    /** Smart-charge master switch was a cloud-only feature — no local primitive. */
    class SmartChargingToggleCommand(@JvmField val enabled: Boolean) : VehicleCommand() {
        override fun name(): String = "smart-charging-toggle"
    }

    // ── Screen backlight (BladeWatch-2000.3) ───────────────────────────────
    // BYD vendor PowerManager.TurnBacklightOn/Off reflection, shared with the stealth-panel
    // path in AccSentryDaemon via BacklightController — see BydDataCollector.setScreenBacklight.

    /** Giving the driver their screen back is never the unsafe direction. */
    class ScreenOnCommand : VehicleCommand() {
        override fun name(): String = "screen-on"
        override fun hasSdkPath(): Boolean = true
        override fun allowedWhileUnsafe(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setScreenBacklight(true)
    }

    /**
     * Turning the panel off is only permitted while parked — normal (non-directional)
     * interlock gating applies, same as every other command.
     */
    class ScreenOffCommand : VehicleCommand() {
        override fun name(): String = "screen-off"
        override fun hasSdkPath(): Boolean = true
        override fun executeViaSdk(collector: BydDataCollector): Boolean =
            collector.setScreenBacklight(false)
    }

    // ── Motion interlock (BladeWatch-2pnn.2) ───────────────────────────────

    /**
     * Gear + speed as read at dispatch time. A test seam.
     *
     * Public rather than package-private because VehicleCommandRouterInterlockTest and
     * VehicleCommandRouterScreenTest are Java tests, and Kotlin has no package-private.
     */
    interface MotionState {
        fun gear(): Int
        fun speedKmh(): Double

        /**
         * A daemon that has never received a gear sample must not refuse every command
         * forever; one that HAS seen telemetry and then lost it must refuse. Live callers
         * derive this from whether GearMonitor has ever received a sample; test doubles set
         * it directly (BladeWatch-2000.3 — needed to exercise BLOCK_UNKNOWN deterministically,
         * which this router could not do before: it always read the live GearMonitor for this
         * flag, even when gear()/speedKmh() were injected for a test).
         */
        fun requireKnownState(): Boolean
    }

    /** Non-null only in tests; production reads the live singletons via [liveMotionState]. */
    @Volatile
    private var motionState: MotionState? = null

    /** Test seam — production code never calls this. Public for the same reason as [MotionState]. */
    fun setMotionStateForTest(state: MotionState?) {
        motionState = state
    }

    // ── Routing ─────────────────────────────────────────────────────────

    fun execute(cmd: VehicleCommand): CommandResult {
        val state = motionState ?: liveMotionState()
        val decision = DrivingSafetyGuard.evaluate(
            state.gear(), state.speedKmh(), state.requireKnownState()
        )
        if (decision != DrivingSafetyGuard.Decision.ALLOW && !cmd.allowedWhileUnsafe()) {
            logger.info("Blocked " + cmd.name() + " by motion interlock: " + decision)
            return CommandResult.blockedUnsafe(msg("blocked_moving"))
        }
        if (!cmd.hasSdkPath()) {
            return CommandResult.notSupported(msg("not_supported"))
        }
        val start = System.currentTimeMillis()
        val leg = invokeSdk(cmd)
        val elapsed = System.currentTimeMillis() - start
        if (leg.success) {
            // BladeWatch-2000.3: arm/disarm the auto-recovery watch here, at the single
            // chokepoint every screen command passes through, rather than in the REST/Connect
            // handler layer -- keeps handlers dumb JSON<->CommandResult translators.
            if (cmd is ScreenOffCommand) {
                ScreenAutoRecovery.getInstance().armed()
            } else if (cmd is ScreenOnCommand) {
                ScreenAutoRecovery.getInstance().disarm()
            }
            return CommandResult.success(Path.SDK, msg("local_sent"), elapsed)
        }
        return CommandResult.failed(Path.SDK, msg("not_supported"), elapsed, leg.error)
    }

    private class SdkLeg(@JvmField val success: Boolean, @JvmField val error: Throwable?)

    private fun invokeSdk(cmd: VehicleCommand): SdkLeg = try {
        SdkLeg(cmd.executeViaSdk(BydDataCollector.getInstance()), null)
    } catch (e: Exception) {
        logger.warn("SDK exec for " + cmd.name() + " threw: " + e.message)
        SdkLeg(false, e)
    }

    companion object {
        private const val TAG = "VehicleCommandRouter"
        private val logger = DaemonLogger.getInstance(TAG)

        @Volatile
        private var instance: VehicleCommandRouter? = null

        @JvmStatic
        fun getInstance(): VehicleCommandRouter =
            instance ?: synchronized(VehicleCommandRouter::class.java) {
                instance ?: VehicleCommandRouter().also { instance = it }
            }

        private fun liveMotionState(): MotionState {
            val gear = GearMonitor.getInstance().currentGear
            val data = BydDataCollector.getInstance().data
            val speedKmh = data?.speedKmh ?: Double.NaN
            val requireKnownState = GearMonitor.getInstance().lastUpdateTime != 0L
            return object : MotionState {
                override fun gear(): Int = gear
                override fun speedKmh(): Double = speedKmh
                override fun requireKnownState(): Boolean = requireKnownState
            }
        }

        // ── i18n key resolution ─────────────────────────────────────────

        private fun msg(key: String): String = Messages.get("vehicle_control.$key")

        /**
         * The localized "not supported" string, for callers that reject a command
         * before it ever reaches [execute] — e.g. trunk OPEN, which has no
         * command class at all since BladeWatch-c2h1. Keeps those responses worded
         * identically to the ones the router produces itself.
         */
        @JvmStatic
        fun notSupportedMessage(): String = msg("not_supported")
    }
}
