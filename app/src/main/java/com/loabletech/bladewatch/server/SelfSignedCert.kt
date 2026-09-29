package net.bladewatch.app.server

import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.KeyPair
import java.security.Signature
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Builds one self-signed X.509 v3 certificate over an EC P-256 key -- the LAN TLS listener's
 * identity (see [LanTls]).
 *
 * ponytail: a hand-written DER encoder for exactly this one certificate shape. Android exposes no
 * public API that builds a certificate (only hidden, repackaged BouncyCastle), and pulling in
 * bcpkix costs megabytes for a ~60-line job. It is not a general ASN.1 library and must not grow
 * into one; if a second certificate shape is ever needed, reach for BouncyCastle then. The result
 * is parsed back through the platform's own X.509 parser before it is returned, so a malformed
 * encoding fails here, loudly, rather than in a TLS handshake.
 *
 * No extensions: the companion pins this certificate by SHA-256 fingerprint, so hostname, key usage
 * and chain are never evaluated. Layout (RFC 5280 section 4.1):
 *
 *     Certificate  ::= SEQUENCE { tbs, signatureAlgorithm, BIT STRING signature }
 *     TBS          ::= SEQUENCE { [0] version v3, serial, signatureAlgorithm, issuer,
 *                                 validity, subject, subjectPublicKeyInfo }
 */
internal object SelfSignedCert {

    private val ECDSA_WITH_SHA256 = oid(1, 2, 840, 10045, 4, 3, 2)
    private val COMMON_NAME = oid(2, 5, 4, 3)

    fun build(
        keyPair: KeyPair,
        commonName: String,
        notBefore: Date,
        notAfter: Date,
        serial: BigInteger,
    ): X509Certificate {
        require(serial.signum() > 0) { "serial must be positive (RFC 5280 4.1.2.2)" }
        val algorithm = seq(ECDSA_WITH_SHA256) // ECDSA identifiers carry no parameters
        val name = seq(set(seq(COMMON_NAME, tlv(0x0C, commonName.toByteArray(Charsets.UTF_8)))))
        val tbs = seq(
            tlv(0xA0, tlv(0x02, byteArrayOf(2))), // [0] EXPLICIT version: 2 means v3
            tlv(0x02, serial.toByteArray()),
            algorithm,
            name,
            seq(time(notBefore), time(notAfter)),
            name, // self-signed: subject == issuer
            keyPair.public.encoded, // already a DER SubjectPublicKeyInfo
        )
        val signature = Signature.getInstance("SHA256withECDSA").run {
            initSign(keyPair.private)
            update(tbs)
            sign()
        }
        val der = seq(tbs, algorithm, tlv(0x03, byteArrayOf(0) + signature)) // 0 unused bits
        return CertificateFactory.getInstance("X.509")
            .generateCertificate(der.inputStream()) as X509Certificate
    }

    private fun tlv(tag: Int, body: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(tag)
        if (body.size < 0x80) {
            out.write(body.size) // short form
        } else {
            val len = BigInteger.valueOf(body.size.toLong()).toByteArray().dropWhile { it == 0.toByte() }
            out.write(0x80 or len.size) // long form: count of length octets, then the length
            out.write(len.toByteArray())
        }
        out.write(body)
        return out.toByteArray()
    }

    private fun seq(vararg parts: ByteArray) = tlv(0x30, parts.reduce(ByteArray::plus))
    private fun set(vararg parts: ByteArray) = tlv(0x31, parts.reduce(ByteArray::plus))

    private fun oid(vararg arcs: Long): ByteArray {
        val out = ByteArrayOutputStream()
        out.write((40 * arcs[0] + arcs[1]).toInt())
        for (arc in arcs.drop(2)) {
            // base-128, most significant group first, high bit set on all but the last
            val groups = generateSequence(arc) { it ushr 7 }.takeWhile { it > 0 }
                .map { (it and 0x7F).toInt() }.toList().ifEmpty { listOf(0) }.reversed()
            groups.forEachIndexed { i, g -> out.write(if (i < groups.size - 1) g or 0x80 else g) }
        }
        return tlv(0x06, out.toByteArray())
    }

    /** UTCTime through 2049, GeneralizedTime from 2050 on -- RFC 5280 section 4.1.2.5. */
    private fun time(date: Date): ByteArray {
        val year = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { time = date }.get(Calendar.YEAR)
        val (tag, pattern) = if (year < 2050) 0x17 to "yyMMddHHmmss'Z'" else 0x18 to "yyyyMMddHHmmss'Z'"
        val text = SimpleDateFormat(pattern, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(date)
        return tlv(tag, text.toByteArray(Charsets.US_ASCII))
    }
}
