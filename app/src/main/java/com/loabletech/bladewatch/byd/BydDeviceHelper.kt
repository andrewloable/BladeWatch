package net.bladewatch.app.byd

import android.content.Context
import android.hardware.bydauto.BYDAutoEventValue
import android.hardware.bydauto.bodywork.AbsBYDAutoBodyworkListener
import android.hardware.bydauto.charging.AbsBYDAutoChargingListener
import android.hardware.bydauto.doorlock.AbsBYDAutoDoorLockListener
import android.hardware.bydauto.engine.AbsBYDAutoEngineListener
import android.hardware.bydauto.tyre.AbsBYDAutoTyreListener

import net.bladewatch.app.logging.DaemonLogger

import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method
import java.lang.reflect.Proxy

/**
 * Reflection utilities for safely accessing BYD SDK devices.
 * Every method is null-safe and exception-safe — never crashes.
 */
object BydDeviceHelper {

    private val logger = DaemonLogger.getInstance("BydDeviceHelper")

    /** Callback interface for listener proxies */
    fun interface ListenerCallback {
        fun onCallback(methodName: String, args: Array<Any?>?)
    }

    /**
     * Get a BYD device singleton via reflection.
     * Returns null if the device class doesn't exist or getInstance fails.
     */
    @JvmStatic
    fun getDevice(className: String, context: Context?): Any? {
        try {
            val cls = Class.forName(className)
            val device = cls.getMethod("getInstance", Context::class.java).invoke(null, context)
            if (device != null) {
                logger.info("Device OK: " + cls.simpleName)
            } else {
                logger.info("Device NULL: " + cls.simpleName)
            }
            return device
        } catch (e: ClassNotFoundException) {
            // Different BYD trims ship different SDK device classes, so absence is expected.
            logger.debug("Optional device class absent: $className")
        } catch (e: Exception) {
            logger.debug("Optional device unavailable: " + className + " — " + e.message)
        }
        return null
    }

    /** Call a no-arg getter method on a device. Returns null on failure. */
    @JvmStatic
    fun callGetter(device: Any?, methodName: String): Any? {
        if (device == null) return null
        try {
            return device.javaClass.getMethod(methodName).invoke(device)
        } catch (e: NoSuchMethodException) {
            return callGetterDeclared(device, methodName)
        } catch (e: InvocationTargetException) {
            // The method itself threw — log the root cause
            logger.debug("Getter $methodName threw: " + causeOf(e))
        } catch (e: Exception) {
            logger.debug(
                "Getter " + methodName + " failed: " + e.javaClass.simpleName + ": " + e.message
            )
        }
        return null
    }

    /** Call a getter with one int parameter. */
    @JvmStatic
    fun callGetter(device: Any?, methodName: String, param: Int): Any? {
        if (device == null) return null
        try {
            return device.javaClass
                .getMethod(methodName, Int::class.javaPrimitiveType)
                .invoke(device, param)
        } catch (e: InvocationTargetException) {
            logger.debug("Getter $methodName($param) threw: " + causeOf(e))
        } catch (e: Exception) {
            logger.debug(
                "Getter " + methodName + "(" + param + ") failed: " +
                    e.javaClass.simpleName + ": " + e.message
            )
        }
        return null
    }

    /**
     * Call a method with N int parameters — used for SDK methods like
     * `voiceCtlMoonRoof(int)`, `setAcWindLevel(int, int)` and
     * `setAcTemperature(int, int, int, int)`. Vararg, so it compiles to `int...` and the
     * existing 1/2/4-arg Java call sites bind to it unchanged; the four hand-written
     * arity overloads it replaces differed only in how many ints they forwarded.
     */
    @JvmStatic
    fun callMethod(device: Any?, methodName: String, vararg params: Int): Any? {
        if (device == null) return null
        val shown = params.joinToString(", ")
        try {
            val paramTypes = Array<Class<*>>(params.size) { Int::class.javaPrimitiveType!! }
            val boxed = Array<Any>(params.size) { params[it] }
            return device.javaClass.getMethod(methodName, *paramTypes).invoke(device, *boxed)
        } catch (e: InvocationTargetException) {
            logger.debug("$methodName($shown) threw: " + causeOf(e))
        } catch (e: Exception) {
            logger.debug(
                methodName + "(" + shown + ") failed: " +
                    e.javaClass.simpleName + ": " + e.message
            )
        }
        return null
    }

    /** `SimpleName: message` of what an InvocationTargetException wrapped, for the debug logs. */
    private fun causeOf(e: InvocationTargetException): String {
        val cause = e.cause ?: return "unknown"
        return cause.javaClass.simpleName + ": " + cause.message
    }

    private fun callGetterDeclared(device: Any, methodName: String): Any? {
        var cls: Class<*>? = device.javaClass
        while (cls != null && cls != Any::class.java) {
            try {
                val m = cls.getDeclaredMethod(methodName)
                m.isAccessible = true
                return m.invoke(device)
            } catch (e: NoSuchMethodException) {
                cls = cls.superclass
            } catch (e: InvocationTargetException) {
                logger.debug("DeclaredGetter $methodName threw: " + causeOf(e))
                return null
            } catch (e: Exception) {
                logger.debug(
                    "DeclaredGetter " + methodName + " failed: " +
                        e.javaClass.simpleName + ": " + e.message
                )
                return null
            }
        }
        return null
    }

    /**
     * Call the generic get(int[], Class) method on a BYD device.
     * This is the correct SDK signature for reading feature ID values.
     * Falls back to get(int, int) if the array signature isn't found.
     */
    @JvmStatic
    fun callGet(device: Any?, featureId: Int, returnType: Class<*>): Any? {
        if (device == null) return null
        try {
            val m = findGetMethod(device)
            if (m != null) {
                val params = m.parameterTypes
                if (params.size == 2 && params[0] == IntArray::class.java) {
                    return m.invoke(
                        device, intArrayOf(featureId), normalizeFeatureReturnType(returnType)
                    )
                } else if (params.size == 2 && params[0] == Int::class.javaPrimitiveType) {
                    return m.invoke(device, featureId, 0)
                }
            }
        } catch (e: Exception) {
            logger.debug("callGet failed for id=" + featureId + " — " + e.message)
        }
        return null
    }

    private fun normalizeFeatureReturnType(returnType: Class<*>): Class<*> {
        // BYD's get(int[], Class) expects primitive class tokens
        // (Integer.TYPE/Double.TYPE). Passing boxed classes works on some
        // firmware but logs "Param type is invalid:Integer!" on this head unit.
        return when (returnType) {
            Integer::class.java -> Integer.TYPE
            java.lang.Double::class.java -> java.lang.Double.TYPE
            java.lang.Float::class.java -> java.lang.Float.TYPE
            java.lang.Boolean::class.java -> java.lang.Boolean.TYPE
            else -> returnType
        }
    }

    /** Extract intValue from a BYDAutoEventValue object. */
    @JvmStatic
    fun getIntValue(eventValue: Any?): Int {
        if (eventValue == null) return Int.MIN_VALUE
        try {
            // Direct field access — BYDAutoEventValue.intValue is public
            return eventValue.javaClass.getField("intValue").getInt(eventValue)
        } catch (e: Exception) {
            // Try as Integer directly (some get() calls return boxed primitives)
            if (eventValue is Int) return eventValue
            if (eventValue is Number) return eventValue.toInt()
        }
        return Int.MIN_VALUE
    }

    /** Extract doubleValue from a BYDAutoEventValue object. */
    @JvmStatic
    fun getDoubleValue(eventValue: Any?): Double {
        if (eventValue == null) return Double.NaN
        try {
            return eventValue.javaClass.getField("doubleValue").getDouble(eventValue)
        } catch (e: Exception) {
            if (eventValue is Double) return eventValue
            if (eventValue is Number) return eventValue.toDouble()
        }
        return Double.NaN
    }

    /** Extract stringValue from a BYDAutoEventValue object. */
    @JvmStatic
    fun getStringValue(eventValue: Any?): String? {
        if (eventValue == null) return null
        try {
            return eventValue.javaClass.getField("stringValue").get(eventValue) as String?
        } catch (e: Exception) {
            if (eventValue is String) return eventValue
        }
        return null
    }

    /**
     * Resolve the IBYDAutoListener-derived interface for a given device class
     * by inspecting registerListener parameter types. Some devices (e.g. ADAS)
     * declare a derived interface (IBYDAutoADASListener) instead of the base
     * IBYDAutoListener — Class.forName on the base name would still find a
     * class, but the proxy must implement the device-specific subtype or
     * registerListener.invoke fails with IllegalArgumentException.
     */
    private fun getListenerInterface(cls: Class<*>?, listenerInterfaceName: String): Class<*>? {
        if (cls != null) {
            for (method in cls.declaredMethods) {
                if (method.name == "registerListener") {
                    val parameterTypes = method.parameterTypes
                    if (parameterTypes.size == 1) {
                        val interfaces = parameterTypes[0].interfaces
                        if (interfaces.size == 1 &&
                            interfaces[0].name == listenerInterfaceName
                        ) {
                            return interfaces[0]
                        }
                    }
                }
            }
        }
        return null
    }

    /**
     * The dynamic proxy both registerListener overloads hand to the HAL: forwards every
     * non-Object method to [callback].
     */
    private fun newListenerProxy(iListener: Class<*>, callback: ListenerCallback): Any =
        Proxy.newProxyInstance(
            iListener.classLoader,
            arrayOf(iListener)
        ) { p, method, args ->
            when (method.name) {
                "hashCode" -> System.identityHashCode(p)
                "equals" -> p === args?.get(0)
                "toString" -> "BydListener"
                else -> {
                    try {
                        callback.onCallback(method.name, args)
                    } catch (e: Exception) {
                        logger.debug("Listener callback error: " + method.name + " — " + e.message)
                    }
                    null
                }
            }
        }

    /** The IBYDAutoListener subtype this device's registerListener expects. */
    private fun resolveBaseListener(device: Any): Class<*> {
        val name = "android.hardware.IBYDAutoListener"
        return getListenerInterface(device.javaClass, name) ?: Class.forName(name)
    }

    /**
     * Register a listener on a device using IBYDAutoListener interface.
     * Creates a dynamic proxy that forwards all calls to the callback.
     */
    @JvmStatic
    fun registerListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val iListener = resolveBaseListener(device)
            val proxy = newListenerProxy(iListener, callback)

            // Try registerListener(IBYDAutoListener)
            val register = findRegisterMethod(device.javaClass, iListener)
            if (register != null) {
                register.invoke(device, proxy)
                return true
            }
        } catch (e: Exception) {
            logger.debug("registerListener failed: " + e.message)
        }
        return false
    }

    /** Register a listener with specific feature IDs. */
    @JvmStatic
    fun registerListener(
        device: Any?,
        featureIds: IntArray,
        callback: ListenerCallback
    ): Boolean {
        if (device == null) return false
        try {
            val iListener = resolveBaseListener(device)
            val proxy = newListenerProxy(iListener, callback)

            // Try registerListener(IBYDAutoListener, int[])
            val register = findRegisterMethodWithIds(device.javaClass, iListener)
            if (register != null) {
                register.invoke(device, proxy, featureIds)
                return true
            }
            // Fallback to no-filter registration
            return registerListener(device, callback)
        } catch (e: Exception) {
            logger.debug("registerListener(ids) failed: " + e.message)
        }
        return false
    }

    // Typed (device-specific) listeners use a hand-rolled concrete subclass of an abstract
    // listener class. The BYD framework provides the actual abstract class at runtime via the
    // system classloader, and our subclass extends it transparently.
    //
    // Why not Proxy.newProxyInstance: java.lang.reflect.Proxy only works with interfaces, but
    // AbsBYDAutoBodyworkListener / AbsBYDAutoDoorLockListener are abstract CLASSES — Proxy
    // throws "is not an interface" at runtime.

    /**
     * Register a typed bodywork listener. Captures door state, window state,
     * and window-open percent callbacks.
     */
    @JvmStatic
    fun registerBodyworkListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val listener = object : AbsBYDAutoBodyworkListener() {
                override fun onDoorStateChanged(area: Int, state: Int) {
                    invokeCallback(callback, "onDoorStateChanged", arrayOf(area, state))
                }

                override fun onWindowStateChanged(area: Int, state: Int) {
                    invokeCallback(callback, "onWindowStateChanged", arrayOf(area, state))
                }

                override fun onWindowOpenPercentChanged(area: Int, percent: Int) {
                    invokeCallback(
                        callback, "onWindowOpenPercentChanged", arrayOf(area, percent)
                    )
                }

                override fun onPowerLevelChanged(level: Int) {
                    invokeCallback(callback, "onPowerLevelChanged", arrayOf(level))
                }
            }
            val register =
                findRegisterMethod(device.javaClass, AbsBYDAutoBodyworkListener::class.java)
            if (register != null) {
                register.invoke(device, listener)
                return true
            }
            logger.debug(
                "registerBodyworkListener: no registerListener method on " +
                    device.javaClass.name
            )
        } catch (e: NoClassDefFoundError) {
            logger.debug("registerBodyworkListener: class not available on this firmware")
        } catch (e: Exception) {
            logger.debug("registerBodyworkListener failed: " + e.message)
        }
        return false
    }

    @JvmStatic
    fun registerTyreListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val listener = object : AbsBYDAutoTyreListener() {
                override fun onTyrePressureValueChanged(wheel: Int, value: Int) {
                    invokeCallback(callback, "onTyrePressureValueChanged", arrayOf(wheel, value))
                }

                override fun onTyrePressureStateChanged(wheel: Int, state: Int) {
                    invokeCallback(callback, "onTyrePressureStateChanged", arrayOf(wheel, state))
                }

                override fun onTyreBatteryValueChanged(wheel: Int, value: Double) {
                    invokeCallback(callback, "onTyreBatteryValueChanged", arrayOf(wheel, value))
                }

                override fun onTyreBatteryStateChanged(state: Int) {
                    invokeCallback(callback, "onTyreBatteryStateChanged", arrayOf(state))
                }

                override fun onTyreTemperatureStateChanged(state: Int) {
                    invokeCallback(callback, "onTyreTemperatureStateChanged", arrayOf(state))
                }

                override fun onTyreAirLeakStateChanged(wheel: Int, state: Int) {
                    invokeCallback(callback, "onTyreAirLeakStateChanged", arrayOf(wheel, state))
                }

                override fun onTyreSignalStateChanged(wheel: Int, state: Int) {
                    invokeCallback(callback, "onTyreSignalStateChanged", arrayOf(wheel, state))
                }

                override fun onTyreSystemStateChanged(state: Int) {
                    invokeCallback(callback, "onTyreSystemStateChanged", arrayOf(state))
                }

                override fun onIndirectTyreSystemStateChanged(state: Int) {
                    invokeCallback(
                        callback, "onIndirectTyreSystemStateChanged", arrayOf(state)
                    )
                }

                // Generic feature-ID event channel. When the listener is
                // registered via the 2-arg overload with an int[] filter,
                // the HAL fires this for each subscribed feature ID
                // instead of (or alongside) the typed callbacks above.
                // The Tyre device delegates per-wheel temperature reads
                // through Instrument-class feature IDs (LF/RF/LB/RB).
                //
                // Not `override`: the compile-time stub does not declare it. The real
                // runtime class does, and JVM dispatch is by name+descriptor, so this
                // still overrides there.
                fun onDataEventChanged(eventId: Int, value: BYDAutoEventValue?) {
                    invokeCallback(callback, "onDataEventChanged", arrayOf(eventId, value))
                }
            }

            // Log available registerListener overloads for diagnostics
            logRegisterOverloads("TyreDevice", device)

            // Strategy 1: 2-arg registration with the per-wheel temperature
            // feature IDs. BYDAutoFeatureIds.Instrument exposes the LF/RF/LB/
            // RB tyre temperature property IDs — those are the ones the Tyre
            // device's underlying property tree actually keys on, regardless
            // of which device class hosts the registerListener overload.
            // Filtering on this exact set is what wakes up the temperature
            // event channel on firmwares where the bare typed callbacks
            // (onTyreBatteryValueChanged) stay dormant.
            val registerWithIds =
                findRegisterMethodWithIds(device.javaClass, AbsBYDAutoTyreListener::class.java)
            var twoArgRegistered = false
            if (registerWithIds != null) {
                try {
                    registerWithIds.invoke(
                        device, listener, BydFeatureIds.INSTRUMENT_TYRE_TEMP_IDS
                    )
                    logger.info(
                        "Tyre listener registered via 2-arg overload with LF/RF/LB/RB feature IDs"
                    )
                    twoArgRegistered = true
                } catch (e: Exception) {
                    logger.info(
                        "Tyre 2-arg registration with LF/RF/LB/RB IDs failed: " + e.message
                    )
                }
                // Fallback: empty int[]. Some HAL implementations interpret
                // this as "subscribe to all features"; others reject it.
                // We only attempt this if the typed-ID registration above
                // failed outright (e.g. method threw on invoke).
                if (!twoArgRegistered) {
                    try {
                        registerWithIds.invoke(device, listener, IntArray(0))
                        logger.info(
                            "Tyre listener registered via 2-arg overload with empty int[] " +
                                "(subscribe-all fallback)"
                        )
                        twoArgRegistered = true
                    } catch (e: Exception) {
                        logger.info(
                            "Tyre 2-arg registration with empty int[] failed: " + e.message
                        )
                    }
                }
            }

            // Strategy 2: Also register via single-arg (ensures pressure/leak/signal
            // events still arrive even if the two-arg only subscribes to temp events).
            // If two-arg already succeeded, this is additive — BYD HAL allows multiple
            // registrations. If two-arg wasn't available, this is the only path.
            val register =
                findRegisterMethod(device.javaClass, AbsBYDAutoTyreListener::class.java)
            if (register != null) {
                register.invoke(device, listener)
                logger.info(
                    if (twoArgRegistered) {
                        "Tyre listener also registered via 1-arg overload (pressure/state events)"
                    } else {
                        "Tyre listener registered via 1-arg overload only"
                    }
                )
                return true
            }
            // If single-arg failed but two-arg succeeded, still report success
            if (twoArgRegistered) return true
            logger.debug(
                "registerTyreListener: no registerListener method on " + device.javaClass.name
            )
        } catch (e: NoClassDefFoundError) {
            logger.debug("registerTyreListener: class not available on this firmware")
        } catch (e: Exception) {
            logger.debug("registerTyreListener failed: " + e.message)
        }
        return false
    }

    /**
     * Register a typed engine listener so onEngineCoolantLevelChanged and
     * onOilLevelChanged actually dispatch (the bare 1-arg
     * registerListener(IBYDAutoListener) registration succeeds but the HAL
     * never invokes the device-specific callbacks on AbsBYDAutoEngineListener
     * subclasses on most firmware).
     *
     * Mirrors the tyre approach: try the 2-arg overload first (HAL only fires
     * onDataEventChanged with feature-IDs when registered with int[] filter),
     * then 1-arg as a baseline. Both succeed additively where supported.
     */
    @JvmStatic
    fun registerEngineListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val listener = object : AbsBYDAutoEngineListener() {
                override fun onEngineSpeedChanged(value: Int) {
                    invokeCallback(callback, "onEngineSpeedChanged", arrayOf(value))
                }

                override fun onEngineCoolantLevelChanged(state: Int) {
                    invokeCallback(callback, "onEngineCoolantLevelChanged", arrayOf(state))
                }

                override fun onOilLevelChanged(value: Int) {
                    invokeCallback(callback, "onOilLevelChanged", arrayOf(value))
                }

                // Generic feature-ID event channel, same pattern as the
                // tyre listener. Engine extras (coolant temp, oil temp on
                // PHEV firmware) tend to land here keyed on feature IDs
                // we may not have in BYDAutoFeatureIds.Engine.
                fun onDataEventChanged(eventId: Int, value: BYDAutoEventValue?) {
                    invokeCallback(callback, "onDataEventChanged", arrayOf(eventId, value))
                }
            }

            // Diagnostic: dump all registerListener overloads so we know what
            // shapes the HAL exposes on this firmware.
            logRegisterOverloads("EngineDevice", device)

            // Strategy 1: 2-arg with empty int[]. We don't have engine fluid
            // feature IDs in BYDAutoFeatureIds.Engine, so empty-array
            // (subscribe-all) is the only option for the filtered overload.
            val registerWithIds =
                findRegisterMethodWithIds(device.javaClass, AbsBYDAutoEngineListener::class.java)
            var twoArgRegistered = false
            if (registerWithIds != null) {
                try {
                    registerWithIds.invoke(device, listener, IntArray(0))
                    logger.info("Engine listener registered via 2-arg overload with empty int[]")
                    twoArgRegistered = true
                } catch (e: Exception) {
                    logger.info("Engine 2-arg registration failed: " + e.message)
                }
            }

            // Strategy 2: 1-arg typed. Even when the HAL never fires the
            // typed callbacks, this one is harmless and gives us the
            // baseline that several other devices rely on.
            val register =
                findRegisterMethod(device.javaClass, AbsBYDAutoEngineListener::class.java)
            if (register != null) {
                register.invoke(device, listener)
                logger.info(
                    if (twoArgRegistered) {
                        "Engine listener also registered via 1-arg overload"
                    } else {
                        "Engine listener registered via 1-arg overload only"
                    }
                )
                return true
            }
            if (twoArgRegistered) return true
            logger.debug(
                "registerEngineListener: no registerListener method on " + device.javaClass.name
            )
        } catch (e: NoClassDefFoundError) {
            logger.debug("registerEngineListener: class not available on this firmware")
        } catch (e: Exception) {
            logger.debug("registerEngineListener failed: " + e.message)
        }
        return false
    }

    /**
     * Register a typed door-lock listener. Captures the canonical
     * onDoorLockStatusChanged(area, state) event emitted by the BYD door-lock
     * HAL when a lock state transitions.
     */
    @JvmStatic
    fun registerDoorLockListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val listener = object : AbsBYDAutoDoorLockListener() {
                override fun onDoorLockStatusChanged(area: Int, state: Int) {
                    invokeCallback(callback, "onDoorLockStatusChanged", arrayOf(area, state))
                }
            }
            val register =
                findRegisterMethod(device.javaClass, AbsBYDAutoDoorLockListener::class.java)
            if (register != null) {
                register.invoke(device, listener)
                return true
            }
            logger.debug(
                "registerDoorLockListener: no registerListener method on " +
                    device.javaClass.name
            )
        } catch (e: NoClassDefFoundError) {
            logger.debug("registerDoorLockListener: class not available on this firmware")
        } catch (e: Exception) {
            logger.debug("registerDoorLockListener failed: " + e.message)
        }
        return false
    }

    /**
     * Register a typed charging listener. The bare 1-arg
     * registerListener(IBYDAutoListener) registration succeeds on most
     * firmware but the HAL never invokes the device-specific callbacks
     * on AbsBYDAutoChargingListener subclasses through that path —
     * onBatteryManagementDeviceStateChanged in particular has been
     * observed to silently drop on PHEV builds, which is the root cause
     * of charging-detection lag during AC charging start.
     *
     * Registers both the 2-arg (with empty int[] for subscribe-all) and
     * 1-arg overloads where present. Both succeed additively where supported.
     */
    @JvmStatic
    fun registerChargingListener(device: Any?, callback: ListenerCallback): Boolean {
        if (device == null) return false
        try {
            val listener = object : AbsBYDAutoChargingListener() {
                override fun onBatteryManagementDeviceStateChanged(state: Int) {
                    invokeCallback(
                        callback, "onBatteryManagementDeviceStateChanged", arrayOf(state)
                    )
                }

                override fun onChargerStateChanged(state: Int) {
                    invokeCallback(callback, "onChargerStateChanged", arrayOf(state))
                }

                override fun onChargingGunStateChanged(state: Int) {
                    invokeCallback(callback, "onChargingGunStateChanged", arrayOf(state))
                }

                override fun onChargingPowerChanged(power: Double) {
                    invokeCallback(callback, "onChargingPowerChanged", arrayOf(power))
                }

                override fun onChargingCapacityChanged(capacity: Double) {
                    invokeCallback(callback, "onChargingCapacityChanged", arrayOf(capacity))
                }
            }

            // Strategy 1: 2-arg with empty int[] (subscribe-all). Some firmware
            // only delivers events through the filtered overload.
            val registerWithIds = findRegisterMethodWithIds(
                device.javaClass, AbsBYDAutoChargingListener::class.java
            )
            var twoArgRegistered = false
            if (registerWithIds != null) {
                try {
                    registerWithIds.invoke(device, listener, IntArray(0))
                    twoArgRegistered = true
                } catch (e: Exception) {
                    logger.debug("Charging 2-arg registration failed: " + e.message)
                }
            }

            // Strategy 2: 1-arg typed.
            val register =
                findRegisterMethod(device.javaClass, AbsBYDAutoChargingListener::class.java)
            if (register != null) {
                register.invoke(device, listener)
                return true
            }
            if (twoArgRegistered) return true
            logger.debug(
                "registerChargingListener: no registerListener method on " +
                    device.javaClass.name
            )
        } catch (e: NoClassDefFoundError) {
            logger.debug("registerChargingListener: class not available on this firmware")
        } catch (e: Exception) {
            logger.debug("registerChargingListener failed: " + e.message)
        }
        return false
    }

    /** Dump every registerListener overload the HAL exposes for this device, for diagnostics. */
    private fun logRegisterOverloads(label: String, device: Any) {
        val overloads = StringBuilder()
        for (m in device.javaClass.methods) {
            if ("registerListener" == m.name) {
                overloads.append("  registerListener(")
                overloads.append(m.parameterTypes.joinToString(", ") { it.simpleName })
                overloads.append(")\n")
            }
        }
        if (overloads.isNotEmpty()) {
            logger.info("$label registerListener overloads:\n$overloads")
        }
    }

    private fun invokeCallback(
        callback: ListenerCallback,
        method: String,
        args: Array<Any?>
    ) {
        try {
            callback.onCallback(method, args)
        } catch (e: Exception) {
            logger.debug("Typed listener callback error: " + method + " — " + e.message)
        }
    }

    // ==================== EXTENDED GETTER METHODS ====================

    /**
     * Call get(int deviceType, int featureId) on a BYD device.
     * Returns the SDK result code, or -1 on any failure.
     */
    @JvmStatic
    fun callGetSingle(device: Any?, featureId: Int): Int {
        if (device == null) return -1
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return -1
            val m = findMethodCached(
                device, "get", getSingleMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId)
                if (result is Number) return result.toInt()
            }
        } catch (e: SecurityException) {
            logger.debug(
                "callGetSingle permission denied for id=" + featureId + " — " + e.message
            )
        } catch (e: Exception) {
            logger.debug("callGetSingle failed for id=" + featureId + " — " + e.message)
        }
        return -1
    }

    /** Outcome of [callGetSingleWithStatus], distinguishing why a read produced no value. */
    enum class ReadStatus { OK, PERMISSION_DENIED, FAILED, NO_DEVICE }

    /** Read result carrying both the value and [ReadStatus] — see [callGetSingleWithStatus]. */
    class GetResult(@JvmField val value: Int, @JvmField val status: ReadStatus)

    /**
     * Pure mapping from a `get()` failure to a caller-facing status. Extracted so
     * PERMISSION_DENIED vs FAILED is unit-testable without a real device to throw a genuine
     * [SecurityException] through reflection (BladeWatch-2pnn.3).
     *
     * Unwraps first (BladeWatch-t87k): the only caller classifies what
     * [Method.invoke] threw, and reflection wraps anything the target method raised in an
     * [InvocationTargetException]. Testing the bare `SecurityException` shape alone passed
     * while production, which only ever sees the wrapped one, reported every permission
     * refusal as a generic FAILED — the one distinction this status exists to draw.
     *
     * Public rather than package-private because AdasFieldInventoryTest is a Java test and
     * Kotlin mangles `internal` member names, which Java cannot spell.
     */
    @JvmStatic
    fun statusForFailure(e: Exception): ReadStatus {
        var t: Throwable = e
        while (t is InvocationTargetException && t.cause != null) {
            t = t.cause!!
        }
        return if (t is SecurityException) ReadStatus.PERMISSION_DENIED else ReadStatus.FAILED
    }

    /**
     * Same primitive as [callGetSingle], but reports WHY a read failed instead of
     * collapsing every non-success case to `-1`. Added for BladeWatch-2pnn.3's ADAS
     * field inventory, which needs to tell "the SDK refused" apart from "the call broke" apart
     * from "there is no device at all" — [callGetSingle]'s signature is unchanged and
     * every existing caller is unaffected.
     */
    @JvmStatic
    fun callGetSingleWithStatus(device: Any?, featureId: Int): GetResult {
        if (device == null) return GetResult(-1, ReadStatus.NO_DEVICE)
        return try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return GetResult(-1, ReadStatus.FAILED)
            val m = findMethodCached(
                device, "get", getSingleMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId)
                if (result is Number) {
                    return GetResult(result.toInt(), ReadStatus.OK)
                }
            }
            GetResult(-1, ReadStatus.FAILED)
        } catch (e: Exception) {
            val status = statusForFailure(e)
            logger.debug(
                "callGetSingleWithStatus " + status + " for id=" + featureId + " — " + e.message
            )
            GetResult(-1, status)
        }
    }

    /**
     * Call getDouble(int deviceType, int featureId) on a BYD device.
     * Returns Double.NaN on any failure.
     */
    @JvmStatic
    fun callGetDouble(device: Any?, featureId: Int): Double {
        if (device == null) return Double.NaN
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return Double.NaN
            val m = findMethodCached(
                device, "getDouble", getDoubleMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId)
                if (result is Number) return result.toDouble()
            }
        } catch (e: Exception) {
            logger.debug("callGetDouble failed for id=" + featureId + " — " + e.message)
        }
        return Double.NaN
    }

    /**
     * Call getIntArray(int deviceType, int[] featureIds) on a BYD device.
     * Returns null on any failure.
     */
    @JvmStatic
    fun callGetIntArray(device: Any?, featureIds: IntArray): IntArray? {
        if (device == null) return null
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return null
            val m = findMethodCached(
                device, "getIntArray", getIntArrayMethodCache,
                Int::class.javaPrimitiveType!!, IntArray::class.java
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureIds)
                if (result is IntArray) return result
            }
        } catch (e: Exception) {
            logger.debug("callGetIntArray failed — " + e.message)
        }
        return null
    }

    /**
     * Call getDoubleArray(int deviceType, int[] featureIds) on a BYD device.
     * The underlying SDK returns float[], so this method returns float[].
     * Returns null on any failure.
     */
    @JvmStatic
    fun callGetDoubleArray(device: Any?, featureIds: IntArray): FloatArray? {
        if (device == null) return null
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return null
            val m = findMethodCached(
                device, "getDoubleArray", getDoubleArrayMethodCache,
                Int::class.javaPrimitiveType!!, IntArray::class.java
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureIds)
                if (result is FloatArray) return result
            }
        } catch (e: Exception) {
            logger.debug("callGetDoubleArray failed — " + e.message)
        }
        return null
    }

    /**
     * Call getBuffer(int deviceType, int featureId) on a BYD device.
     * Returns null on any failure.
     */
    @JvmStatic
    fun callGetBuffer(device: Any?, featureId: Int): ByteArray? {
        if (device == null) return null
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return null
            val m = findMethodCached(
                device, "getBuffer", getBufferMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId)
                if (result is ByteArray) return result
            }
        } catch (e: Exception) {
            logger.debug("callGetBuffer failed for id=" + featureId + " — " + e.message)
        }
        return null
    }

    // ==================== SETTER METHODS ====================

    /**
     * Send a set command using the BYDAutoEventValue pattern.
     * Creates a BYDAutoEventValue, sets intValue, calls device.set(int[], BYDAutoEventValue).
     * Falls back to callSetSingle if BYDAutoEventValue is not available.
     */
    @JvmStatic
    fun sendSetCommand(device: Any?, featureId: Int, value: Int): Boolean {
        if (device == null) return false
        return try {
            val eventValueClass = Class.forName("android.hardware.bydauto.BYDAutoEventValue")
            val eventValue = eventValueClass.getConstructor().newInstance()
            eventValueClass.getField("intValue").setInt(eventValue, value)
            val setMethod =
                device.javaClass.getMethod("set", IntArray::class.java, eventValueClass)
            when (val result = setMethod.invoke(device, intArrayOf(featureId), eventValue)) {
                is Int -> result >= 0
                is Boolean -> result
                else -> true // non-null result, assume success
            }
        } catch (e: ClassNotFoundException) {
            // BYDAutoEventValue not available, fall back to base class set()
            logger.debug("BYDAutoEventValue not found, falling back to callSetSingle")
            callSetSingle(device, featureId, value) >= 0
        } catch (e: Exception) {
            logger.debug(
                "sendSetCommand failed for featureId=0x" + Integer.toHexString(featureId) +
                    ": " + e.message
            )
            false
        }
    }

    /**
     * Call set(int deviceType, int featureId, int value) on a BYD device.
     * Returns the SDK result code, or -1 on any failure.
     */
    @JvmStatic
    fun callSetSingle(device: Any?, featureId: Int, value: Int): Int {
        if (device == null) return -1
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return -1
            val m = findMethodCached(
                device, "set", setSingleMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!,
                Int::class.javaPrimitiveType!!
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId, value)
                if (result is Number) return result.toInt()
            }
        } catch (e: SecurityException) {
            logger.debug(
                "callSetSingle permission denied for id=" + featureId + " — " + e.message
            )
        } catch (e: Exception) {
            logger.debug(
                "callSetSingle failed for id=" + featureId + ", value=" + value +
                    " — " + e.message
            )
        }
        return -1
    }

    /**
     * Call set(int deviceType, int[] featureIds, int[] values) on a BYD device.
     * Returns the SDK result code, or -1 on any failure.
     */
    @JvmStatic
    fun callSetBatch(device: Any?, featureIds: IntArray, values: IntArray): Int {
        if (device == null) return -1
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return -1
            val m = findMethodCached(
                device, "set", setBatchMethodCache,
                Int::class.javaPrimitiveType!!, IntArray::class.java, IntArray::class.java
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureIds, values)
                if (result is Number) return result.toInt()
            }
        } catch (e: SecurityException) {
            logger.debug("callSetBatch permission denied — " + e.message)
        } catch (e: Exception) {
            logger.debug("callSetBatch failed — " + e.message)
        }
        return -1
    }

    /**
     * Call set(int deviceType, int featureId, byte[] buffer) on a BYD device.
     * Returns the SDK result code, or -1 on any failure.
     */
    @JvmStatic
    fun callSetBuffer(device: Any?, featureId: Int, buffer: ByteArray): Int {
        if (device == null) return -1
        try {
            val deviceType = resolveDeviceType(device)
            if (deviceType == Int.MIN_VALUE) return -1
            val m = findMethodCached(
                device, "set", setBufferMethodCache,
                Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!,
                ByteArray::class.java
            )
            if (m != null) {
                val result = m.invoke(device, deviceType, featureId, buffer)
                if (result is Number) return result.toInt()
            }
        } catch (e: SecurityException) {
            logger.debug(
                "callSetBuffer permission denied for id=" + featureId + " — " + e.message
            )
        } catch (e: Exception) {
            logger.debug("callSetBuffer failed for id=" + featureId + " — " + e.message)
        }
        return -1
    }

    // ==================== INTERNAL HELPERS ====================

    private val getMethodCache = HashMap<Class<*>, Method?>()
    private val getSingleMethodCache = HashMap<Class<*>, Method?>()
    private val getDoubleMethodCache = HashMap<Class<*>, Method?>()
    private val getIntArrayMethodCache = HashMap<Class<*>, Method?>()
    private val getDoubleArrayMethodCache = HashMap<Class<*>, Method?>()
    private val getBufferMethodCache = HashMap<Class<*>, Method?>()
    private val setSingleMethodCache = HashMap<Class<*>, Method?>()
    private val setBatchMethodCache = HashMap<Class<*>, Method?>()
    private val setBufferMethodCache = HashMap<Class<*>, Method?>()
    private val deviceTypeCache = HashMap<Class<*>, Int>()

    private fun findGetMethod(device: Any): Method? {
        val cls = device.javaClass
        if (getMethodCache.containsKey(cls)) return getMethodCache[cls]

        var walk: Class<*>? = cls
        while (walk != null && walk != Any::class.java) {
            try {
                val m = walk.getDeclaredMethod("get", IntArray::class.java, Class::class.java)
                m.isAccessible = true
                getMethodCache[cls] = m
                return m
            } catch (e: NoSuchMethodException) {
                logger.debug("findGetMethod: no get(int[], Class) on " + walk.simpleName)
            }
            try {
                val m = walk.getDeclaredMethod(
                    "get", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType
                )
                m.isAccessible = true
                getMethodCache[cls] = m
                return m
            } catch (e: NoSuchMethodException) {
                logger.debug("findGetMethod: no get(int, int) on " + walk.simpleName)
            }
            walk = walk.superclass
        }
        getMethodCache[cls] = null
        return null
    }

    /**
     * Resolve the deviceType from a BYD device object via getDevicetype() or getType().
     * Caches the result per device class. Returns Int.MIN_VALUE on failure.
     */
    private fun resolveDeviceType(device: Any): Int {
        val cls = device.javaClass
        deviceTypeCache[cls]?.let { return it }

        // Try getDevicetype() first (AbsBYDAutoDevice), then getType()
        for (name in arrayOf("getDevicetype", "getType")) {
            try {
                val result = cls.getMethod(name).invoke(device)
                if (result is Number) {
                    val type = result.toInt()
                    deviceTypeCache[cls] = type
                    return type
                }
            } catch (e: Exception) {
                logger.debug(
                    "resolveDeviceType: " + name + "() failed on " + cls.simpleName +
                        ": " + e.message
                )
            }
        }

        logger.debug("Could not resolve deviceType for " + cls.simpleName)
        deviceTypeCache[cls] = Int.MIN_VALUE
        return Int.MIN_VALUE
    }

    /**
     * Find a method by name and parameter types on a device, walking up the class hierarchy.
     * Caches the result per device class in the provided cache map.
     */
    private fun findMethodCached(
        device: Any,
        methodName: String,
        cache: MutableMap<Class<*>, Method?>,
        vararg paramTypes: Class<*>
    ): Method? {
        val cls = device.javaClass
        if (cache.containsKey(cls)) return cache[cls]

        var walk: Class<*>? = cls
        while (walk != null && walk != Any::class.java) {
            try {
                val m = walk.getDeclaredMethod(methodName, *paramTypes)
                m.isAccessible = true
                cache[cls] = m
                return m
            } catch (e: NoSuchMethodException) {
                logger.debug("findMethodCached($methodName) not on " + walk.simpleName)
            }
            walk = walk.superclass
        }
        cache[cls] = null
        return null
    }

    private fun findRegisterMethod(cls: Class<*>, listenerInterface: Class<*>): Method? =
        findDeclaredUpHierarchy(cls, "registerListener", listenerInterface)

    private fun findRegisterMethodWithIds(cls: Class<*>, listenerInterface: Class<*>): Method? =
        findDeclaredUpHierarchy(cls, "registerListener", listenerInterface, IntArray::class.java)

    /** Walk the class hierarchy for a declared method with these exact parameter types. */
    private fun findDeclaredUpHierarchy(
        cls: Class<*>,
        name: String,
        vararg paramTypes: Class<*>
    ): Method? {
        var walk: Class<*>? = cls
        while (walk != null && walk != Any::class.java) {
            try {
                val m = walk.getDeclaredMethod(name, *paramTypes)
                m.isAccessible = true
                return m
            } catch (e: NoSuchMethodException) {
                logger.debug("$name(${paramTypes.size} args) not on " + walk.simpleName)
            }
            walk = walk.superclass
        }
        return null
    }
}
