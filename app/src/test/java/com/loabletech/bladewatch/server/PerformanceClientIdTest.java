package net.bladewatch.app.server;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * BladeWatch-qwqq: the performance panel's session id, moved off REST onto ConnectRPC.
 *
 * <p>Monitoring is on-demand — it starts when a client connects and stops when the last one goes
 * away — so the id the server registers is the one the client must send with every heartbeat.
 * If the server were to silently register a DIFFERENT id from the one it returns, heartbeats
 * would never match, the session would time out mid-panel, and monitoring would stop under a
 * user who is still looking at it.
 *
 * <p>Pure so it is testable: {@code PerformanceMonitor} is a daemon singleton over live device
 * counters and cannot be built on the JVM.
 */
public class PerformanceClientIdTest {

    @Test
    public void aCallerSuppliedIdIsUsedVerbatim() {
        assertEquals("bladewatch-flutter-1789787290768",
                PerformanceClientId.resolve("bladewatch-flutter-1789787290768"));
    }

    @Test
    public void anAbsentIdIsGeneratedRatherThanLeftEmpty() {
        for (String absent : new String[] { null, "", "   " }) {
            String id = PerformanceClientId.resolve(absent);
            assertTrue("a generated id must be non-empty, got '" + id + "'",
                    id != null && !id.trim().isEmpty());
        }
    }

    @Test
    public void generatedIdsAreNotAllTheSame() {
        // Two panels open at once must not collide onto one session: disconnecting either would
        // then stop monitoring for both.
        assertNotEquals(PerformanceClientId.resolve(null), PerformanceClientId.resolve(null));
    }
}
