package net.bladewatch.app.notifications

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.nio.file.attribute.PosixFilePermission
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.impl.NotificationsServiceImpl
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.14: the car holds its alerts and a companion collects the unseen ones whenever it
 * connects. The cursor contract is what matters -- ids strictly increase and are never reused, so
 * "everything after the last id I saw" can neither skip nor repeat an alert.
 */
class CompanionInboxTest {

    private val file = File(Files.createTempDirectory("inbox").toFile(), "inbox.json")
    private var now = System.currentTimeMillis()

    private fun inbox(max: Int = 200, maxAge: Long = CompanionInbox.MAX_AGE_MS) =
        CompanionInbox(file, max, maxAge) { now }

    private fun event(title: String, tag: String? = null, sev: NotificationEvent.Severity = NotificationEvent.Severity.WARN) =
        NotificationEvent("surveillance.motion", sev, title, "body of $title", tag, null, JSONObject().put("file", "secret.mp4"))

    private fun ids(r: JSONObject) = (0 until r.getJSONArray("entries").length()).map { r.getJSONArray("entries").getJSONObject(it).getLong("id") }

    private fun titles(r: JSONObject) = (0 until r.getJSONArray("entries").length()).map { r.getJSONArray("entries").getJSONObject(it).getString("title") }

    @Test
    fun `entries come back oldest first after the cursor, with the proto's field names`() {
        val box = inbox()
        listOf("a", "b", "c").forEach { box.onNotification(event(it)) }

        val all = box.list(0, 0)
        assertEquals(listOf(1L, 2L, 3L), ids(all))
        assertEquals(3L, all.getLong("latestId"))
        assertEquals(1L, all.getLong("oldestId"))
        assertEquals(listOf("c"), titles(box.list(2, 0)))
        assertEquals(emptyList<Long>(), ids(box.list(3, 0)))

        val e = all.getJSONArray("entries").getJSONObject(0)
        assertEquals(
            setOf("id", "timestampMs", "category", "severity", "title", "body", "clickUrl", "tag"),
            e.keys().asSequence().toSet(),
        )
        assertEquals("NOTIFICATION_SEVERITY_ALERT", e.getString("severity"))
    }

    @Test
    fun `severity maps onto the proto enum`() {
        assertEquals("NOTIFICATION_SEVERITY_INFO", CompanionInbox.severityName(NotificationEvent.Severity.INFO))
        assertEquals("NOTIFICATION_SEVERITY_ALERT", CompanionInbox.severityName(NotificationEvent.Severity.WARN))
        assertEquals("NOTIFICATION_SEVERITY_CRITICAL", CompanionInbox.severityName(NotificationEvent.Severity.CRITICAL))
    }

    @Test
    fun `a page is capped, defaulting to 100 and never above 500`() {
        val box = inbox(max = 1000)
        repeat(600) { box.onNotification(event("e$it")) }
        assertEquals(100, ids(box.list(0, 0)).size)
        assertEquals(7, ids(box.list(0, 7)).size)
        assertEquals(500, ids(box.list(0, 10_000)).size)
        assertEquals(100, ids(box.list(0, -3)).size)
    }

    @Test
    fun `a tagged event replaces the one it supersedes, under a new id`() {
        val box = inbox()
        box.onNotification(event("recording", tag = "evt-1"))
        box.onNotification(event("other"))
        box.onNotification(event("recorded", tag = "evt-1"))

        assertEquals(listOf("other", "recorded"), titles(box.list(0, 0)))
        assertEquals(listOf(2L, 3L), ids(box.list(0, 0)))
    }

    @Test
    fun `bounded by count and by age`() {
        val box = inbox(max = 3, maxAge = 60_000)
        repeat(5) { box.onNotification(event("e$it")) }
        assertEquals(listOf(3L, 4L, 5L), ids(box.list(0, 0)))

        now += 600_000 // events carry the real clock; step well past it
        val r = box.list(0, 0)
        assertEquals(emptyList<Long>(), ids(r))
        assertEquals(0L, r.getLong("latestId"))
    }

    @Test
    fun `ids survive a restart and are never reused, even once everything aged out`() {
        inbox(maxAge = 60_000).apply { repeat(3) { onNotification(event("e$it")) } }
        now += 600_000 // events carry the real clock; step well past it
        val reopened = inbox(maxAge = 60_000)
        assertEquals(emptyList<Long>(), ids(reopened.list(0, 0)))
        now = System.currentTimeMillis() // back in step with the event clock
        reopened.onNotification(event("later"))
        assertEquals(listOf(4L), ids(reopened.list(0, 0)))

        assertEquals(listOf("later"), titles(inbox().list(3, 0)))

        // The stored counter wins over the entries, whatever they hold.
        file.writeText("""{"nextId":42,"entries":[]}""")
        inbox().onNotification(event("after"))
        assertEquals(listOf(42L), ids(inbox().list(0, 0)))
    }

    @Test
    fun `an unreadable file starts empty and is replaced by the next event`() {
        file.writeText("{ not json")
        val box = inbox()
        assertEquals(emptyList<Long>(), ids(box.list(0, 0)))
        box.onNotification(event("a"))
        assertEquals(listOf("a"), titles(inbox().list(0, 0)))
    }

    @Test
    fun `the file is owner-only and holds what was shown, not the event's extras`() {
        inbox().onNotification(event("a"))
        assertEquals(
            setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE),
            Files.getPosixFilePermissions(file.toPath()),
        )
        assertFalse(file.readText().contains("secret.mp4"))
        assertFalse(File(file.path + ".tmp").exists())
    }

    @Test
    fun `ListInbox is served over Connect, reading a proto3 JSON string cursor`() {
        val box = inbox()
        listOf("a", "b", "c").forEach { box.onNotification(event(it)) }
        val d = ConnectDispatcher()
        NotificationsServiceImpl(box).register(d)
        val out = ByteArrayOutputStream()

        d.dispatch(
            "POST", "/bladewatch.v1.NotificationsService/ListInbox", """{"afterId":"1","limit":1}""",
            "application/json", "1", "test", out,
        )

        val http = out.toString("UTF-8")
        assertTrue(http, http.startsWith("HTTP/1.1 200"))
        val r = JSONObject(http.substringAfter("\r\n\r\n"))
        assertEquals(listOf("b"), titles(r))
        assertEquals(3L, r.getLong("latestId"))
    }
}
