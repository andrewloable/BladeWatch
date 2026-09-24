package net.bladewatch.app.server

import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.PrivateKey
import java.security.SecureRandom
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Base64
import java.util.Date
import java.util.UUID
import java.util.concurrent.TimeUnit
import javax.net.ssl.KeyManagerFactory
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLServerSocketFactory
import net.bladewatch.app.config.SecretConfigStore

/**
 * The LAN listener's TLS identity (BladeWatch-rdtj.4).
 *
 * A companion on the same network as the car connects directly to `https://<car>:[PORT]` instead of
 * over Pear, because Hyperswarm cannot connect two peers behind one NAT. That path must not be plain
 * HTTP: the Bearer JWT -- and with it every vehicle-control endpoint -- would cross a shared Wi-Fi
 * in the clear. So it is TLS with a self-signed certificate, and the companion pins its SHA-256
 * [Identity.fingerprintSha256], delivered out of band in the pairing QR -- not trust-on-first-use.
 *
 * The key and certificate live in the 600 shell-only secret store (section `lanTls`), the same
 * custody as the device secret. No separate keystore file, so no second file mode to get wrong and
 * no keystore password to protect.
 *
 * ## Never rotated on expiry -- deliberately
 *
 * Rotation changes the fingerprint and silently breaks every paired companion. Expiry would be the
 * only trigger, and it is not a safe one here: this head unit NTP-corrects its wall clock after boot
 * and the clock can jump (see AuthMiddleware), so a certificate minted or checked under a wrong clock
 * would look expired and rotate for no reason. Pinning never evaluates validity anyway. The identity
 * is regenerated only when it is missing or unreadable.
 */
object LanTls {
    const val PORT = 8443

    internal const val SECTION = "lanTls"
    private const val PRIVATE_KEY = "privateKeyPkcs8"
    private const val CERTIFICATE = "certificateDer"
    /**
     * Deliberately generic (BladeWatch-cjhz): the subject is readable by anything on the LAN before
     * any credential, and "BladeWatch" announced that a BladeWatch car is parked here. Nothing
     * checks it -- the companion pins the fingerprint. Only NEW identities get it: an existing
     * certificate is never rotated, or every paired companion would lose the car.
     */
    private const val COMMON_NAME = "localhost"

    class Identity(val privateKey: PrivateKey, val certificate: X509Certificate) {
        /**
         * Lowercase hex, no separators -- the form the pairing payload carries. Equals the
         * colon-separated value `openssl x509 -fingerprint -sha256` prints, colons aside.
         */
        val fingerprintSha256: String by lazy {
            MessageDigest.getInstance("SHA-256").digest(certificate.encoded)
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        }
    }

    /**
     * The stored identity, or a new one persisted on first use.
     *
     * @param onReplacingUnreadable called when a stored identity exists but cannot be parsed and is
     *   about to be replaced -- that changes the fingerprint, so the caller should log it loudly.
     *
     * Synchronized because the TLS listener and the pairing IPC command both call this from
     * byd_cam_daemon, each through its OWN SecretConfigStore (whose lock is per instance). Unlocked,
     * both could mint an identity on first use and the listener would serve one certificate while
     * pairing handed out the other's fingerprint -- a pin that could never match.
     */
    @Synchronized
    fun loadOrCreate(
        store: SecretConfigStore,
        now: Date = Date(),
        onReplacingUnreadable: (Exception) -> Unit = {},
    ): Identity {
        val storedKey = store.getString(SECTION, PRIVATE_KEY)
        val storedCert = store.getString(SECTION, CERTIFICATE)
        if (storedKey != null && storedCert != null) {
            try {
                return parse(storedKey, storedCert)
            } catch (e: Exception) {
                onReplacingUnreadable(e)
            }
        }
        val identity = create(now)
        val b64 = Base64.getEncoder()
        check(
            store.putString(SECTION, PRIVATE_KEY, b64.encodeToString(identity.privateKey.encoded)) &&
                store.putString(SECTION, CERTIFICATE, b64.encodeToString(identity.certificate.encoded))
        ) { "could not persist the LAN TLS identity to the secret store" }
        return identity
    }

    fun serverSocketFactory(identity: Identity): SSLServerSocketFactory {
        // In-memory only; the password protects nothing that is not already in this process.
        val password = UUID.randomUUID().toString().toCharArray()
        val keyStore = KeyStore.getInstance("PKCS12").apply {
            load(null, null)
            setKeyEntry("lan", identity.privateKey, password, arrayOf(identity.certificate))
        }
        val keyManagers = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
            .apply { init(keyStore, password) }.keyManagers
        return SSLContext.getInstance("TLS").apply { init(keyManagers, null, null) }.serverSocketFactory
    }

    /** TLS 1.2 and 1.3 only; everything older is broken or deprecated. */
    fun enabledProtocols(supported: Array<String>): Array<String> =
        supported.filter { it == "TLSv1.3" || it == "TLSv1.2" }.toTypedArray()

    private fun create(now: Date): Identity {
        val keyPair = KeyPairGenerator.getInstance("EC")
            .apply { initialize(ECGenParameterSpec("secp256r1"), SecureRandom()) }
            .generateKeyPair()
        val certificate = SelfSignedCert.build(
            keyPair,
            COMMON_NAME,
            // A day of slack either way of a clock that may be wrong at boot; nothing checks it.
            notBefore = Date(now.time - TimeUnit.DAYS.toMillis(1)),
            notAfter = Date(now.time + TimeUnit.DAYS.toMillis(3650)),
            serial = BigInteger(63, SecureRandom()).add(BigInteger.ONE),
        )
        return Identity(keyPair.private, certificate)
    }

    private fun parse(keyB64: String, certB64: String): Identity {
        val b64 = Base64.getDecoder()
        val key = KeyFactory.getInstance("EC").generatePrivate(PKCS8EncodedKeySpec(b64.decode(keyB64)))
        val cert = CertificateFactory.getInstance("X.509")
            .generateCertificate(b64.decode(certB64).inputStream()) as X509Certificate
        // A key and certificate that parse but do not belong together would fail every handshake
        // while looking fine here -- prove they are a pair.
        val probe = "bladewatch-lan-tls".toByteArray()
        val signed = java.security.Signature.getInstance("SHA256withECDSA")
            .run { initSign(key); update(probe); sign() }
        check(
            java.security.Signature.getInstance("SHA256withECDSA")
                .run { initVerify(cert.publicKey); update(probe); verify(signed) }
        ) { "stored LAN TLS key does not match its certificate" }
        return Identity(key, cert)
    }
}
