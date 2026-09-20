package net.bladewatch.app.surveillance

import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Surveillance time window scheduling.
 *
 * Lets the user define days and hours when surveillance should be active. When enabled,
 * surveillance only activates during the configured time windows. When disabled (the default),
 * surveillance follows the existing behaviour: always active when ACC is OFF, the user has enabled
 * it, and the car is not in a safe zone.
 *
 * Overnight windows are supported: startHour > endHour spans midnight (e.g. 22:00-06:00 means 10PM
 * to 6AM the next day).
 */
class SurveillanceSchedule {

    var isEnabled = false

    val rules: MutableList<Rule> = ArrayList()

    /** A single schedule rule: active on the specified days during the specified hours. */
    class Rule(
        /** 0=Sunday, 1=Monday, ..., 6=Saturday. */
        @JvmField val days: IntArray,
        /** 0-23. */
        @JvmField val startHour: Int,
        /** 0-59. */
        @JvmField val startMin: Int,
        /** 0-23. */
        @JvmField val endHour: Int,
        /** 0-59. */
        @JvmField val endMin: Int
    ) {

        /**
         * Whether the given day and time fall within this rule. Handles overnight windows
         * (startHour > endHour).
         */
        fun matches(dayOfWeek: Int, hour: Int, minute: Int): Boolean {
            if (!days.contains(dayOfWeek)) return false

            val nowMinutes = hour * 60 + minute
            val startMinutes = startHour * 60 + startMin
            val endMinutes = endHour * 60 + endMin

            return if (startMinutes <= endMinutes) {
                // Same-day window (e.g. 08:00-18:00)
                nowMinutes in startMinutes until endMinutes
            } else {
                // Overnight window (e.g. 22:00-06:00) — active if now >= start OR now < end
                nowMinutes >= startMinutes || nowMinutes < endMinutes
            }
        }

        fun toJson(): JSONObject = try {
            val obj = JSONObject()
            val daysArr = JSONArray()
            for (d in days) daysArr.put(d)
            obj.put("days", daysArr)
            obj.put("startHour", startHour)
            obj.put("startMin", startMin)
            obj.put("endHour", endHour)
            obj.put("endMin", endMin)
            obj
        } catch (e: Exception) {
            JSONObject()
        }

        companion object {
            @JvmStatic
            fun fromJson(obj: JSONObject?): Rule? = try {
                val daysArr = obj!!.getJSONArray("days")
                if (daysArr.length() == 0) {
                    null // No days selected
                } else {
                    var valid = true
                    val days = IntArray(daysArr.length())
                    for (i in 0 until daysArr.length()) {
                        val d = daysArr.getInt(i)
                        if (d < 0 || d > 6) {
                            valid = false // Invalid day
                            break
                        }
                        days[i] = d
                    }
                    val sh = obj.optInt("startHour", 0)
                    val sm = obj.optInt("startMin", 0)
                    val eh = obj.optInt("endHour", 23)
                    val em = obj.optInt("endMin", 59)
                    when {
                        !valid -> null
                        // Validate hour/minute ranges
                        sh < 0 || sh > 23 || eh < 0 || eh > 23 -> null
                        sm < 0 || sm > 59 || em < 0 || em > 59 -> null
                        // Reject zero-length windows
                        sh == eh && sm == em -> null
                        else -> Rule(days, sh, sm, eh, em)
                    }
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    // ==================== PUBLIC API ====================

    /**
     * Whether surveillance should be active right now based on the schedule. True if the schedule
     * is disabled (always active), if it is enabled but has no rules configured (treated as "no
     * restrictions"), or if the current day/time matches at least one rule.
     */
    val isActiveNow: Boolean
        get() {
            if (!isEnabled) return true // Schedule disabled = always active
            // Enabled but no rules = always active (no restrictions configured)
            if (rules.isEmpty()) return true

            val cal = Calendar.getInstance()
            val dayOfWeek = cal.get(Calendar.DAY_OF_WEEK) - 1 // Calendar.SUNDAY=1 → 0
            val hour = cal.get(Calendar.HOUR_OF_DAY)
            val minute = cal.get(Calendar.MINUTE)

            return rules.any { it.matches(dayOfWeek, hour, minute) }
        }

    // ==================== SERIALIZATION ====================

    fun toJson(): JSONObject = try {
        val obj = JSONObject()
        obj.put("scheduleEnabled", isEnabled)
        val rulesArr = JSONArray()
        for (rule in rules) {
            rulesArr.put(rule.toJson())
        }
        obj.put("scheduleRules", rulesArr)
        obj
    } catch (e: Exception) {
        JSONObject()
    }

    fun loadFromJson(obj: JSONObject?) {
        if (obj == null) return
        isEnabled = obj.optBoolean("scheduleEnabled", false)
        rules.clear()
        val rulesArr = obj.optJSONArray("scheduleRules") ?: return
        for (i in 0 until rulesArr.length()) {
            Rule.fromJson(rulesArr.optJSONObject(i))?.let { rules.add(it) }
        }
    }

    /** Human-readable summary, for logging and the UI. */
    val summary: String
        get() {
            if (!isEnabled) return "Disabled (always active)"
            if (rules.isEmpty()) return "Enabled, no restrictions (always active)"

            val dayNames = arrayOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
            val sb = StringBuilder()
            for (i in rules.indices) {
                if (i > 0) sb.append("; ")
                val r = rules[i]
                val days = StringBuilder()
                for (j in r.days.indices) {
                    if (j > 0) days.append(",")
                    if (r.days[j] in 0..6) days.append(dayNames[r.days[j]])
                }
                sb.append(days).append(" ")
                    .append(String.format("%02d:%02d", r.startHour, r.startMin))
                    .append("-")
                    .append(String.format("%02d:%02d", r.endHour, r.endMin))
            }
            return sb.toString()
        }
}
