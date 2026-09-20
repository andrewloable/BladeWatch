package net.bladewatch.app.surveillance;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

import net.bladewatch.app.surveillance.PipelineRateController.RateTarget;

import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

/**
 * BladeWatch-t1lg.3: {@link PipelineRateController}. {@code targetFps} is a pure function
 * (no camera, no EGL, no Android); the transition owner below is tested against a fake
 * {@link RateTarget} that records exactly which methods were invoked, which is what proves a
 * rate change never touches encoder/EGL teardown.
 */
public class PipelineRateControllerTest {

    private static final int CONFIGURED_FPS = 15;
    private static final int DRIVING_FPS = PipelineRateController.DEFAULT_DRIVING_FPS;
    private static final int IDLE_FPS = PipelineRateController.DEFAULT_IDLE_FPS;

    // ==================== targetFps: pure function ====================

    @Test
    public void accOn_noViewers_noMotion_drivingRate() {
        assertEquals(DRIVING_FPS, PipelineRateController.targetFps(true, false, false, CONFIGURED_FPS));
    }

    @Test
    public void accOff_noViewers_noRecentMotion_idleRate() {
        assertEquals(IDLE_FPS, PipelineRateController.targetFps(false, false, false, CONFIGURED_FPS));
    }

    @Test
    public void accOff_liveViewerPresent_noMotion_fullRate_neverIdle() {
        int result = PipelineRateController.targetFps(false, true, false, CONFIGURED_FPS);
        assertEquals(CONFIGURED_FPS, result);
        assertFalse("a live viewer must never see the idle rate", result == IDLE_FPS);
    }

    @Test
    public void accOff_noViewers_recentMotion_fullRate() {
        assertEquals(CONFIGURED_FPS, PipelineRateController.targetFps(false, false, true, CONFIGURED_FPS));
    }

    @Test
    public void accOn_withLiveViewer_fullRate_viewerAlwaysWins() {
        assertEquals(CONFIGURED_FPS, PipelineRateController.targetFps(true, true, false, CONFIGURED_FPS));
    }

    @Test
    public void configuredFpsBelowIdleRate_neverExceedsConfigured() {
        int lowConfigured = IDLE_FPS - 1;
        assertEquals(lowConfigured, PipelineRateController.targetFps(false, false, false, lowConfigured));
    }

    // ==================== Transition owner, against a fake RateTarget ====================

    private static final class FakeRateTarget implements RateTarget {
        final List<Integer> rateChanges = new ArrayList<>();
        final List<String> methodsCalled = new ArrayList<>();
        // Symmetric with a real pipeline: these must NEVER be invoked by the controller.
        void release() { methodsCalled.add("release"); }
        void reinitEncoder() { methodsCalled.add("reinitEncoder"); }
        void teardown() { methodsCalled.add("teardown"); }

        @Override
        public void setDetectionRate(int fps) {
            methodsCalled.add("setDetectionRate");
            rateChanges.add(fps);
        }
    }

    @Test
    public void rateChange_callsOnlyTheRateSetter_neverTeardownOrReinit() {
        FakeRateTarget fake = new FakeRateTarget();
        PipelineRateController controller = new PipelineRateController(fake, CONFIGURED_FPS, DRIVING_FPS, IDLE_FPS);

        controller.setAccOn(true);

        assertEquals(List.of("setDetectionRate"), fake.methodsCalled);
        assertEquals(List.of(DRIVING_FPS), fake.rateChanges);
    }

    @Test
    public void motionArriving_producesRateChangeOnTheSameCall() {
        FakeRateTarget fake = new FakeRateTarget();
        PipelineRateController controller = new PipelineRateController(fake, CONFIGURED_FPS, DRIVING_FPS, IDLE_FPS);
        controller.setAccOn(false); // -> idle rate
        int callsBefore = fake.rateChanges.size();

        controller.onMotionDetected();

        assertEquals(callsBefore + 1, fake.rateChanges.size());
        assertEquals(CONFIGURED_FPS, (int) fake.rateChanges.get(fake.rateChanges.size() - 1));
    }

    @Test
    public void twoIdenticalConsecutiveTargetRates_produceExactlyOneCall() {
        FakeRateTarget fake = new FakeRateTarget();
        PipelineRateController controller = new PipelineRateController(fake, CONFIGURED_FPS, DRIVING_FPS, IDLE_FPS);

        controller.setAccOn(true); // -> driving rate: one real change
        controller.setAccOn(true); // identical resulting rate: must not call again

        assertEquals(List.of(DRIVING_FPS), fake.rateChanges);
    }
}
