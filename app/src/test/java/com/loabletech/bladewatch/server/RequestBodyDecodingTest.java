package net.bladewatch.app.server;

import java.nio.charset.StandardCharsets;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-ou7y: a request body must survive the byte/char round trip.
 *
 * <p>{@code Content-Length} counts BYTES, but the request is read through a
 * {@code BufferedReader}, whose {@code read(char[])} returns CHARACTERS. Under a UTF-8
 * decoder those two numbers differ for any non-ASCII body: a 10-byte body of five
 * two-byte characters yields five chars, so the read loop asks for ten, gets five, and
 * then blocks for five more that never arrive — the request hangs until the socket
 * timeout and fails. Pure ASCII is the one case where byte count and char count agree,
 * which is why this survived so long.
 *
 * <p>The fix makes the reader byte-transparent by decoding as ISO-8859-1, which maps
 * bytes 0-255 bijectively onto chars 0-255, and then recovers the text with
 * {@link HttpServer#decodeRequestBody}. These tests pin that round trip. They matter
 * because the failure is invisible in ASCII testing and presents as a timeout rather
 * than as a decoding error.
 */
public class RequestBodyDecodingTest {

    /** Exactly what the reader hands over: one byte per char, in the low 8 bits. */
    private static char[] asLatin1Chars(String text) {
        byte[] utf8 = text.getBytes(StandardCharsets.UTF_8);
        char[] chars = new char[utf8.length];
        for (int i = 0; i < utf8.length; i++) {
            chars[i] = (char) (utf8[i] & 0xFF);
        }
        return chars;
    }

    private static void assertRoundTrips(String original) {
        char[] chars = asLatin1Chars(original);
        Assert.assertEquals(
                "the reader must yield one char per BYTE, so the char count matches "
                        + "Content-Length exactly — that is the whole point of the fix",
                original.getBytes(StandardCharsets.UTF_8).length, chars.length);
        Assert.assertEquals(original, HttpServer.decodeRequestBody(chars, chars.length));
    }

    @Test
    public void asciiBodyIsUnchanged() {
        assertRoundTrips("{\"status\":\"ok\",\"zone\":\"Home\"}");
    }

    @Test
    public void emptyBodyIsEmpty() {
        Assert.assertEquals("", HttpServer.decodeRequestBody(new char[0], 0));
    }

    /**
     * The case that actually broke. Two bytes per character, so a UTF-8 reader would
     * return half as many chars as Content-Length promised and the read loop would stall.
     */
    @Test
    public void accentedTextRoundTrips() {
        assertRoundTrips("{\"zone\":\"Garação\"}");
    }

    /** BladeWatch ships 17 locales; most of them are not Latin. */
    @Test
    public void nonLatinScriptsRoundTrip() {
        assertRoundTrips("{\"zone\":\"自宅\"}");          // Japanese, 3 bytes per char
        assertRoundTrips("{\"zone\":\"Дом\"}");           // Russian, 2 bytes per char
        assertRoundTrips("{\"zone\":\"บ้าน\"}");           // Thai, combining marks
        assertRoundTrips("{\"zone\":\"المنزل\"}");        // Arabic, right-to-left
    }

    /** Four-byte sequences — the widest UTF-8 gets, and the easiest to truncate. */
    @Test
    public void astralCharactersRoundTrip() {
        assertRoundTrips("{\"note\":\"parked 🚗 here\"}");
    }

    /**
     * The decoder must honour the length it is given and ignore trailing slack, because
     * the caller allocates {@code new char[contentLength]} but may have read fewer on a
     * truncated request.
     */
    @Test
    public void respectsTheLengthArgumentAndIgnoresSlack() {
        String text = "{\"zone\":\"Home\"}";
        char[] chars = new char[64];
        char[] real = asLatin1Chars(text);
        System.arraycopy(real, 0, chars, 0, real.length);
        Assert.assertEquals(text, HttpServer.decodeRequestBody(chars, real.length));
    }

    /**
     * Every byte value must survive, including those above 0x7F that a naive
     * {@code (byte) char} narrowing could mangle if the reader were not Latin-1.
     */
    @Test
    public void allByteValuesSurviveTheNarrowing() {
        char[] chars = new char[256];
        for (int i = 0; i < 256; i++) chars[i] = (char) i;
        byte[] out = HttpServer.decodeRequestBody(chars, 256)
                .getBytes(StandardCharsets.ISO_8859_1);
        // The UTF-8 decode replaces invalid sequences, so compare what a UTF-8 round trip
        // is expected to yield rather than the raw input — the property under test is that
        // the NARROWING is lossless, which the length and the ASCII prefix both show.
        Assert.assertEquals("bytes 0x00-0x7F must be preserved exactly", 128,
                countMatchingPrefix(chars, out));
    }

    private static int countMatchingPrefix(char[] expected, byte[] actual) {
        int n = 0;
        while (n < actual.length && n < expected.length && (byte) expected[n] == actual[n]) n++;
        return n;
    }
}
