package net.bladewatch.bladewatch_ui.auth

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

private class FakeIpc(private val respond: (JSONObject) -> JSONObject) : IpcCommandSender {
    val sentCommands = mutableListOf<JSONObject>()
    override fun sendCommand(command: JSONObject): JSONObject {
        sentCommands.add(command)
        return respond(command)
    }
}

private fun authSectionResponse(deviceId: String, deviceSecret: String, tokenEpoch: Long = 0L): JSONObject =
    JSONObject().put("status", "ok").put(
        "section",
        JSONObject().put("deviceId", deviceId).put("deviceSecret", deviceSecret).put("tokenEpoch", tokenEpoch),
    )

private fun hmacSha256Base64Url(data: String, secret: String): String {
    val mac = Mac.getInstance("HmacSHA256")
    mac.init(SecretKeySpec(secret.toByteArray(Charsets.UTF_8), "HmacSHA256"))
    return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(data.toByteArray(Charsets.UTF_8)))
}

class JwtMinterTest {

    @Test
    fun `mints a JWT with the correct 3-part structure and a valid signature`() {
        val ipc = FakeIpc { authSectionResponse("byd-test-device", "shh-fake-secret", tokenEpoch = 3) }
        val minter = JwtMinter(ipc)

        val jwt = minter.mintJwt()

        requireNotNull(jwt)
        val parts = jwt.split(".")
        assertEquals(3, parts.size)

        val header = String(Base64.getUrlDecoder().decode(parts[0]), Charsets.UTF_8)
        assertTrue(header.contains("\"alg\":\"HS256\""))

        val payload = String(Base64.getUrlDecoder().decode(parts[1]), Charsets.UTF_8)
        assertTrue(payload.contains("\"sub\":\"byd-test-device\""))
        assertTrue(payload.contains("\"ver\":3"))

        val expectedSig = hmacSha256Base64Url("${parts[0]}.${parts[1]}", "shh-fake-secret")
        assertEquals(expectedSig, parts[2])
    }

    @Test
    fun `sends secret_get_section for the auth section — never a raw secret_get`() {
        val ipc = FakeIpc { authSectionResponse("d", "s") }
        JwtMinter(ipc).mintJwt()

        assertEquals(1, ipc.sentCommands.size)
        assertEquals("secret_get_section", ipc.sentCommands.single().optString("cmd"))
        assertEquals("auth", ipc.sentCommands.single().optString("section"))
    }

    @Test
    fun `sets iat and exp 24 hours apart`() {
        val ipc = FakeIpc { authSectionResponse("d", "s") }
        val before = System.currentTimeMillis() / 1000
        val jwt = minterJwtOrFail(ipc)
        val after = System.currentTimeMillis() / 1000

        val payload = decodePayload(jwt)
        val iat = payload.getLong("iat")
        val exp = payload.getLong("exp")
        assertTrue(iat in before..after)
        assertEquals(24 * 60 * 60L, exp - iat)
    }

    @Test
    fun `returns null when the response has no section object`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `returns null when deviceId is missing`() {
        val ipc = FakeIpc {
            JSONObject().put("status", "ok").put("section", JSONObject().put("deviceSecret", "s"))
        }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `returns null when deviceSecret is missing`() {
        val ipc = FakeIpc {
            JSONObject().put("status", "ok").put("section", JSONObject().put("deviceId", "d"))
        }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `defaults tokenEpoch to 0 when absent`() {
        val ipc = FakeIpc {
            JSONObject().put("status", "ok").put(
                "section",
                JSONObject().put("deviceId", "d").put("deviceSecret", "s"),
            )
        }
        val payload = decodePayload(minterJwtOrFail(ipc))
        assertEquals(0L, payload.getLong("ver"))
    }

    @Test
    fun `returns null, not a thrown exception, when the IPC call is rejected`() {
        val ipc = FakeIpc { throw IpcException.CommandRejected("nope") }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `returns null when the IPC call times out`() {
        val ipc = FakeIpc { throw IpcException.Timeout("slow") }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `returns null when the daemon is not listening`() {
        val ipc = FakeIpc { throw IpcException.DaemonNotListening("down") }
        assertNull(JwtMinter(ipc).mintJwt())
    }

    @Test
    fun `never caches — each mint re-fetches the auth section`() {
        val ipc = FakeIpc { authSectionResponse("d", "s") }
        val minter = JwtMinter(ipc)

        minter.mintJwt()
        minter.mintJwt()

        assertEquals(2, ipc.sentCommands.size)
    }

    @Test
    fun `a rotated secret produces a different signature on the next mint`() {
        var secret = "secret-v1"
        val ipc = FakeIpc { authSectionResponse("d", secret) }
        val minter = JwtMinter(ipc)

        val jwt1 = minterJwtOrFail(minter)
        secret = "secret-v2"
        val jwt2 = minterJwtOrFail(minter)

        assertNotEquals(jwt1.split(".")[2], jwt2.split(".")[2])
    }

    @Test
    fun `stateVersion starts at 0 and bumps on invalidate`() {
        val minter = JwtMinter(FakeIpc { authSectionResponse("d", "s") })

        assertEquals(0, minter.stateVersion())
        minter.invalidate()
        assertEquals(1, minter.stateVersion())
        minter.invalidate()
        assertEquals(2, minter.stateVersion())
    }

    // --- getAccessCode ---

    @Test
    fun `getAccessCode returns the raw device secret`() {
        val ipc = FakeIpc { authSectionResponse("d", "shh-fake-secret") }
        assertEquals("shh-fake-secret", JwtMinter(ipc).getAccessCode())
    }

    @Test
    fun `getAccessCode returns null when the auth section is unavailable`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        assertNull(JwtMinter(ipc).getAccessCode())
    }

    // --- regenerateAccessCode ---

    @Test
    fun `regenerateAccessCode sends secret_put with a 20-char code and returns it`() {
        val ipc = FakeIpc { cmd ->
            if (cmd.optString("cmd") == "secret_put") JSONObject().put("status", "ok")
            else authSectionResponse("d", "s")
        }
        val code = JwtMinter(ipc).regenerateAccessCode()

        requireNotNull(code)
        assertEquals(20, code.length)
        val putCmd = ipc.sentCommands.first { it.optString("cmd") == "secret_put" }
        assertEquals("auth", putCmd.optString("section"))
        assertEquals("deviceSecret", putCmd.optString("key"))
        assertEquals(code, putCmd.optString("value"))
    }

    @Test
    fun `regenerateAccessCode only uses the documented character set`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val code = requireNotNull(JwtMinter(ipc).regenerateAccessCode())
        assertTrue(code.matches(Regex("[a-zA-Z0-9]{20}")))
    }

    @Test
    fun `regenerateAccessCode returns null and does not invalidate when the daemon rejects the write`() {
        val ipc = FakeIpc { JSONObject().put("status", "error") }
        val minter = JwtMinter(ipc)

        val code = minter.regenerateAccessCode()

        assertNull(code)
        assertEquals(0, minter.stateVersion())
    }

    @Test
    fun `regenerateAccessCode bumps stateVersion on success so ConnectClient drops its cached JWT`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val minter = JwtMinter(ipc)

        minter.regenerateAccessCode()

        assertEquals(1, minter.stateVersion())
    }

    @Test
    fun `regenerateAccessCode two calls produce different codes`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val minter = JwtMinter(ipc)

        val first = minter.regenerateAccessCode()
        val second = minter.regenerateAccessCode()

        assertNotEquals(first, second)
    }

    // --- setCustomAccessCode ---

    @Test
    fun `setCustomAccessCode rejects a password shorter than CUSTOM_SECRET_MIN_LENGTH without any IPC call`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val minter = JwtMinter(ipc)

        val result = minter.setCustomAccessCode("short")

        assertEquals(false, result)
        assertEquals(0, ipc.sentCommands.size)
        assertEquals(0, minter.stateVersion())
    }

    @Test
    fun `setCustomAccessCode accepts a password of exactly the minimum length`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val minter = JwtMinter(ipc)

        val result = minter.setCustomAccessCode("a".repeat(JwtMinter.CUSTOM_SECRET_MIN_LENGTH))

        assertEquals(true, result)
    }

    @Test
    fun `setCustomAccessCode persists the exact password via secret_put`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        JwtMinter(ipc).setCustomAccessCode("my-custom-password-1")

        val putCmd = ipc.sentCommands.first { it.optString("cmd") == "secret_put" }
        assertEquals("auth", putCmd.optString("section"))
        assertEquals("deviceSecret", putCmd.optString("key"))
        assertEquals("my-custom-password-1", putCmd.optString("value"))
    }

    // --- the daemon's auth cache must be dropped after a secret write ---
    //
    // Regression guard. secret_put only rewrites the secrets file; the daemon's
    // AuthManager keeps the old secret in cachedState and keeps validating against
    // it. Without the follow-up auth_invalidate, changing your access code makes the
    // daemon reject every JWT the Flutter side mints afterwards — i.e. it locks you
    // out of your own car.

    @Test
    fun `setCustomAccessCode invalidates the daemon auth cache right after writing`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }

        JwtMinter(ipc).setCustomAccessCode("my-custom-password-1")

        val order = ipc.sentCommands.map { it.optString("cmd") }
        assertEquals(listOf("secret_put", "auth_invalidate"), order)
    }

    @Test
    fun `regenerateAccessCode invalidates the daemon auth cache right after writing`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }

        JwtMinter(ipc).regenerateAccessCode()

        val order = ipc.sentCommands.map { it.optString("cmd") }
        assertEquals(listOf("secret_put", "auth_invalidate"), order)
    }

    @Test
    fun `setCustomAccessCode reports failure when the cache invalidate is rejected`() {
        // The secret landed but the daemon is still validating against the old one.
        // Reporting success here would tell the user their new code works when every
        // subsequent RPC is about to be rejected.
        val ipc = FakeIpc { cmd ->
            if (cmd.optString("cmd") == "auth_invalidate") JSONObject().put("status", "error")
            else JSONObject().put("status", "ok")
        }
        val minter = JwtMinter(ipc)

        assertEquals(false, minter.setCustomAccessCode("my-custom-password-1"))
        assertEquals(0, minter.stateVersion())
    }

    @Test
    fun `regenerateAccessCode returns null when the cache invalidate is rejected`() {
        val ipc = FakeIpc { cmd ->
            if (cmd.optString("cmd") == "auth_invalidate") JSONObject().put("status", "error")
            else JSONObject().put("status", "ok")
        }
        val minter = JwtMinter(ipc)

        assertNull(minter.regenerateAccessCode())
        assertEquals(0, minter.stateVersion())
    }

    @Test
    fun `no auth_invalidate is sent when the secret write itself fails`() {
        val ipc = FakeIpc { JSONObject().put("status", "error") }

        JwtMinter(ipc).setCustomAccessCode("my-custom-password-1")

        assertEquals(listOf("secret_put"), ipc.sentCommands.map { it.optString("cmd") })
    }

    @Test
    fun `setCustomAccessCode returns false and does not invalidate when the daemon rejects the write`() {
        val ipc = FakeIpc { JSONObject().put("status", "error") }
        val minter = JwtMinter(ipc)

        val result = minter.setCustomAccessCode("my-custom-password-1")

        assertEquals(false, result)
        assertEquals(0, minter.stateVersion())
    }

    @Test
    fun `setCustomAccessCode bumps stateVersion on success`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val minter = JwtMinter(ipc)

        minter.setCustomAccessCode("my-custom-password-1")

        assertEquals(1, minter.stateVersion())
    }

    private fun minterJwtOrFail(ipc: IpcCommandSender): String = requireNotNull(JwtMinter(ipc).mintJwt())
    private fun minterJwtOrFail(minter: JwtMinter): String = requireNotNull(minter.mintJwt())

    private fun decodePayload(jwt: String): JSONObject {
        val parts = jwt.split(".")
        return JSONObject(String(Base64.getUrlDecoder().decode(parts[1]), Charsets.UTF_8))
    }
}
