package net.bladewatch.app.server

/**
 * Decides which ConnectRPC calls need the vehicle action token on top of the session JWT
 * (BladeWatch-jwko, restoring uy93.5).
 *
 * The original gate was `path.startsWith("/api/vehicle/")`. Every real command goes to
 * `/bladewatch.v1.VehicleService/<Method>`, so it never fired and the second factor had been inert for
 * every client since the Connect migration — over the tunnel a session JWT alone actuated the car.
 *
 * Pure and path-based so the decision is testable: `HttpServer` needs a bound socket and cannot be
 * exercised on the JVM, and the enforcement point needs the peer address, which only it has.
 *
 * **Read this before adding a VehicleService RPC.** A method that is in neither list is UNGATED,
 * which is the failure mode that made uy93.5 inert. `VehicleActionGateTest` fails on any
 * registered method that is not in exactly one of them, so the decision cannot be skipped by
 * omission.
 */
object VehicleActionGate {

    private const val VEHICLE_PREFIX = "/bladewatch.v1.VehicleService/"

    /**
     * Methods that ACTUATE the physical car. These need the second factor from a non-loopback
     * caller.
     */
    private val ACTUATING: Set<String> = hashSetOf(
        "SetClimate",
        "MoveWindow",
        "Trunk",
        "SetSeat",
        "SetLights",
        "SetAdas",
        "SetChargeCap",
        "SetScreen",
        "SetMediaVolume"
    )

    /**
     * Methods that do NOT actuate the car, listed explicitly rather than by omission.
     *
     * `StartGps`/`StopGps` drive the daemon's own GPS monitor, not the vehicle.
     * `IssueActionToken` must never be gated or the token would be unobtainable — you would need
     * a token to get a token.
     */
    private val READ_ONLY: Set<String> = hashSetOf(
        "GetState",
        "GetChargeCap",
        "GetAcDiagnostics",
        "GetSeatDiagnostics",
        "GetGpsLocation",
        "GetAdasInventory",
        "StartGps",
        "StopGps",
        "IssueActionToken"
    )

    /** Whether this Connect path actuates the car and so needs the action token. */
    @JvmStatic
    fun requiresActionToken(path: String?): Boolean = ACTUATING.contains(methodOf(path))

    /** Whether this VehicleService method is explicitly declared non-actuating. */
    @JvmStatic
    fun isDeclaredReadOnly(method: String?): Boolean = READ_ONLY.contains(method)

    /** The bare method name, or "" when the path is not a VehicleService call. */
    private fun methodOf(path: String?): String {
        if (path == null || !path.startsWith(VEHICLE_PREFIX)) return ""
        var method = path.substring(VEHICLE_PREFIX.length)
        // A query string must not let a command slip past the match.
        val q = method.indexOf('?')
        if (q >= 0) method = method.substring(0, q)
        val h = method.indexOf('#')
        if (h >= 0) method = method.substring(0, h)
        return method
    }
}
