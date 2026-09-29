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

    private fun minterJwtOrFail(ipc: IpcCommandSender): String = requireNotNull(JwtMinter(ipc).mintJwt())
    private fun minterJwtOrFail(minter: JwtMinter): String = requireNotNull(minter.mintJwt())

    private fun decodePayload(jwt: String): JSONObject {
        val parts = jwt.split(".")
        return JSONObject(String(Base64.getUrlDecoder().decode(parts[1]), Charsets.UTF_8))
    }
}
