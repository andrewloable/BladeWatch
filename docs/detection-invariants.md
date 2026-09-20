# Detection Invariants

This document is about the **surveillance / sentry mode detection pipeline** only —
`GpuSurveillancePipeline` → `SurveillanceEngineGpu` → the native motion pipeline → the YOLO
gate → the texture tracker. It does **not** cover `RecordingModeManager.Mode.PROXIMITY_GUARD`,
which is a separate, radar-triggered recording mode driven by `ProximityGuardController` and
has no AI detection stage of its own. Conflating the two would misdescribe both.

## Prime directive

**False-positive rejection is the protected property of this pipeline. Only misses are
defects.** A change that makes the pipeline catch more real intruders is not, by itself,
justification for shipping it — if it costs the owner even one false alarm they didn't have
before, the likely outcome is not "safer car," it's "owner turns sentry mode off," at which
point it catches nothing at all. Every invariant below exists because a past change traded
false-positive rejection for detection sensitivity and a real regression followed — the
pipeline's source comments name each one (`FIX: ...`) because it already happened once. "This
catches more" is never sufficient on its own; it must be paired with evidence that none of the
invariants below were weakened to get there.

## Evidence channels

BladeWatch's sentry pipeline has **three** independent evidence channels. (A fourth,
radar-triggered channel exists in the app, but it belongs to `PROXIMITY_GUARD`, a different
recording mode — see the scope note above. Inventing a fourth channel here to match some other
count would misdescribe this pipeline.)

1. **Per-quadrant native motion pipeline** —
   [motion_pipeline_v2.cpp](../app/src/main/cpp/surveillance/motion_pipeline_v2.cpp) /
   [motion_pipeline_v2.h](../app/src/main/cpp/surveillance/motion_pipeline_v2.h). The
   always-on, first-line channel: a 640×480 2×2 mosaic is split into four independent 320×240
   quadrants, each run through a 6-stage filter (brightness/global-flash suppression → per-block
   luma+edge dual-gate activation with shadow discrimination → temporal confidence decay →
   connected-component spatial coherence → distance-zone + alarm-threshold rejection →
   loitering/approaching/passing behavioral classification). Everything downstream depends on
   this producing at least `THREAT_MEDIUM` in `stage5_behaviorClassification()`.
2. **YOLO11n object classification** —
   [YoloDetector.kt](../app/src/main/java/com/loabletech/bladewatch/ai/YoloDetector.kt),
   invoked from `SurveillanceEngineGpu.runAiOnQuadrant()`. A TFLite object detector (GPU →
   NNAPI → CPU fallback chain) that gates `THREAT_MEDIUM` events always, and `THREAT_HIGH`
   events during the post-deterrent window (see Invariant 5), against a real COCO-class
   detection. Applies a confidence threshold (default 0.25), a per-class quadrant-relative
   distance filter (person: height ≥15% of quadrant height; cars/buses/trucks/trains: **width**
   ≥20%, because vehicles are wide, not tall; bikes/motorcycles: height ≥10%), NMS (IoU 0.45),
   and a "ghost filter" that discards the entire result if it exceeds 50 detections (almost
   certainly a degenerate model output, not 50 real objects).
3. **NCC texture tracker** —
   [texture_tracker.h](../app/src/main/cpp/surveillance/texture_tracker.h) /
   `texture_tracker.cpp`. Once YOLO anchors a bounding box, this per-quadrant normalized
   cross-correlation tracker memorizes the object's pixel texture and follows it frame-to-frame
   without re-running YOLO, waking YOLO again only as a periodic "heartbeat" to re-verify. Its
   distinguishing property: it tracks texture, not absolute luminance, so it survives global
   brightness swings that would reset the motion pipeline's confidence (Invariant 10).

`AdaptiveBitrateController` was also read for this document — it adjusts encoder bitrate from
a motion score and has no bearing on detection decisions; it is not an evidence channel.

## Invariants

Each one is falsifiable, names what it protects, what breaking it looks like from the owner's
seat, and which file enforces it. All ten are backed by a `FIX:`-style comment in source
recording the regression that motivated them — these are not hypothetical.

1. **Shadows are recognized only by uniform darkening with preserved color ratios; a
   *brightening* change is never classified as a shadow.**
   Protects against tree/cloud shadows *and* headlight sweeps causing false alarms. Breaking
   it (the "Headlight False-Positive" regression) looks like: every car that turns a corner at
   night sets off a `THREAT_HIGH` alarm, because headlight sweeps preserve chroma ratios just
   like real shadows do. Enforced in `isShadowPixel()`'s `allDarker` check
   (`motion_pipeline_v2.cpp`).

2. **A block with strong edge evidence (≥2 edge-changed pixels) is never shadow-suppressed,
   no matter how large its shadow-pixel ratio is.**
   Protects a person casting their own shadow from being erased along with it. Breaking it
   (the "Self-Erasing Person" regression) looks like: sentry mode never notices someone
   standing still near the car in daylight, because their own shadow dominates the pixel count
   in that block. Enforced in `stage2_blockAnalysis()`'s `edgeChangedCount < 2` guard before
   the shadow-ratio suppression (`motion_pipeline_v2.cpp`).

3. **A brightness/flash event detected on any one camera suppresses all four quadrants
   together for that frame, not just the one that saw it.**
   Protects the other three cameras from a "spillover hallucination" — one camera's flash
   correlates with brief exposure/ISP shifts on the others too. Breaking it looks like: a flash
   on the front camera is reported as motion detected on the *rear* camera. Enforced by Pass 1
   ("Global Illumination Sync") in `v2_processFrame()` (`motion_pipeline_v2.cpp`).

4. **`THREAT_MEDIUM` ("approaching") recordings require an independent YOLO object
   confirmation before a recording commits — motion evidence alone is not enough.**
   Protects against streetlights, porch lights, and slow headlight sweeps that the motion
   pipeline alone classifies as "approaching." Breaking it looks like: every slow light change
   near the car starts a recording and a push notification. Enforced by the `shouldSuppress`
   gate in `SurveillanceEngineGpu.processFrameV2()` ("AI CONFIRMATION GATE"). A documented
   timeout fallback (2s normally, extended to the full 20s deterrent window if a brightness
   event occurred during the sequence) lets motion evidence through alone if YOLO genuinely
   cannot see the object — the invariant is "confirm when possible," not "block forever."

5. **The pipeline's own deterrent flash cannot re-trigger a second recording of itself.**
   Protects against BladeWatch's own intruder-deterrent light being classified as a second
   intruder. Breaking it looks like: every deterrent activation is immediately followed by a
   second "motion detected" push notification and clip, of nothing. Enforced by the
   `deterrentActive`/`deterrentFiredTime` checks and the `DETERRENT_SUPPRESSION_MS` (20s)
   window in `processFrameV2()`, including a pure time-based fallback for when YOLO isn't
   available at all (daemon mode with no `Context`).

6. **Motion must be sustained before it triggers anything — 500ms minimum for confirmed
   loitering, the user's configured loitering-time setting for approaching motion.**
   Protects against a single noisy frame (a bug on the lens, a compression artifact) starting a
   recording. Breaking it looks like: recordings start and stop within one frame, constantly,
   for nothing visible in the clip. Enforced by the `motionDuration >= requiredDuration` check
   in `processFrameV2()`, using the *peak* threat across the sequence so a brief
   MEDIUM→NONE→MEDIUM flicker doesn't reset the clock.

7. **A single frame is never enough — motion must be spatially confirmed across multiple
   frames (temporal decay) and form a connected region of a minimum size, not scattered
   single-block noise.**
   Protects against ISO sensor grain or single-pixel artifacts scattered across the grid.
   Breaking it looks like: noisy night footage constantly registers as motion. Enforced by
   `stage3_temporalDecay()`'s confidence accumulation and the `largestComponent <
   config->minComponentSize` rejection in `processQuadrant()` (`motion_pipeline_v2.cpp`).

8. **Motion outside the configured distance zone is rejected regardless of how strong the
   signal is.**
   Protects against alerting on a pedestrian or car legitimately passing on a sidewalk or road
   well beyond the vehicle — "near your car" must mean near the car. Breaking it looks like:
   sentry mode records every pedestrian and car that passes on the street the vehicle is parked
   on. Enforced by the `centroidY < config->maxDistanceRow` check in `processQuadrant()`.

9. **Classification (loitering vs. approaching vs. passing) is based on trajectory, with a
   proximity-mass override for side cameras, not on raw presence.**
   Protects the distinction that drives both the trigger delay (Invariant 6) and the YOLO-gate
   strictness (Invariant 4) — a passing pedestrian on the sidewalk and someone standing at the
   car are different events. Breaking it looks like either every passerby treated as a threat,
   or — the regression this fix addressed — someone standing right next to a fisheye side
   camera dismissed as "passing" because the centroid-toward-center heuristic that works for
   front/rear cameras doesn't apply to lateral motion. Enforced by
   `stage5_behaviorClassification()`, including its `activeAreaFraction > 0.15f` override for
   left/right cameras.

10. **A texture-tracker lock on a *person* (not a vehicle) survives brightness suppression
    that would otherwise zero out motion confidence.**
    This is the one invariant that guards against a *suppressor* costing too much — see
    Suppressors below. Protects a genuinely-tracked person from being lost mid-approach because
    their own vehicle's headlights swept the camera. Breaking it looks like: a real intruder's
    recording cuts off mid-event the moment a car's headlights pass. Enforced in
    `processFrameV2()`'s tracker-immunity block, deliberately restricted to `classId == 0`
    (person) — vehicle tracks get no such immunity, because vehicles moving past are not the
    threat this override exists to protect.

## Suppressors

Each of these deliberately causes a miss. Each is allowed for a stated reason, not by default.

- **Safe locations** ([SafeLocationManager](../app/src/main/java/com/loabletech/bladewatch/surveillance/SafeLocationManager.java),
  geofence, Haversine check against GPS) — disables surveillance entirely inside a
  user-defined zone (checked in `AccSentryDaemon`/`CameraDaemon` before arming sentry on ACC
  OFF). Allowed because the owner has explicitly said "I don't need to be watched here" — a
  home garage generates constant benign motion (family, pets, deliveries) that would otherwise
  be a stream of real false alarms. This is a user decision, not the pipeline misjudging a
  scene.
- **Schedule windows** ([SurveillanceSchedule](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceSchedule.java))
  — disables surveillance outside user-configured day/hour windows (same call sites as safe
  locations). Allowed for the same reason: explicit owner intent ("I only care overnight"),
  not a pipeline judgment call.
- **Brightness/global-flash suppression countdown** (5–10 frames, 500ms–1s, `motion_pipeline_v2.cpp`
  Stage 1 and Pass 1) — a short, automatic, time-bounded miss window after any sudden light
  change, because the pipeline cannot yet tell whether the light change itself is the event or
  is masking one. Allowed because it is bounded in both time and blast radius (frames, not
  minutes) — and Invariant 10 exists specifically to bound how much a *person* mid-approach can
  be cost by this window.
- **Shadow and oscillation filtering** (`shadowFilterMode`, `oscillationThreshold`,
  `motion_pipeline_v2.cpp` Stage 2 / Stage 2.5) — deliberately treats certain pixel changes
  (tree-shadow flicker, cloud shadows) as "not motion" even though pixels changed. Allowed
  because these are near-certain non-threats, and Invariant 2 (edge-evidence override) bounds
  how much real motion this filtering is allowed to absorb.
- **YOLO's ghost filter** (>50 detections discarded entirely, `YoloDetector.parseOutput()`) —
  a deliberate miss of whatever a busy scene actually contained. Allowed because 50
  simultaneous "detections" from a single-camera quadrant is far more likely to be a
  degenerate model output (lens flare, encoder corruption) than 50 real objects, and passing it
  through would flood storage and notifications with garbage.

## Change checklist

Before proposing any change to the above — a threshold, a new filter, a new evidence source —
answer these, in the close reason or PR description:

1. **What did you measure the false-positive rate against, before and after?** There is
   currently no automated regression suite for this pipeline (`app/src/test/` has no motion,
   shadow, YOLO, or sustained-motion tests — see "What we do not know" below), so this is
   necessarily a manual, on-device before/after comparison. State what scenes/conditions you
   ran and for how long.
2. **Did you specifically re-test every scenario named in a `FIX:` comment this change
   touches?** Tree shadows in wind, a car turning a corner at night, a person standing in their
   own shadow, the deterrent's own flash, a side-camera person standing still, a slow headlight
   sweep. Each was a real regression once; a change that doesn't re-check the ones it could
   plausibly affect is trusting that history won't repeat.
3. **Which invariant, if any, does this change loosen?** If the answer is "none," say so
   explicitly and why you believe that. If the answer is "one of the ten above," that is not
   automatically disqualifying — but it must be argued, not asserted, and the suppressor/invariant
   pairing above (e.g. Invariant 10 bounding the brightness-suppression suppressor) is the model
   for what that argument should look like: a bound, not a hope.
4. **"Catches more" evidence must include what it did NOT newly catch.** A demo of the new
   detection working on a real intruder is not evidence by itself — pair it with a run through
   the false-positive scenarios in point 2 showing they still reject.

## What we do not know

- **`SurveillanceEngineGpu`'s lineage relative to any prior/related implementation is
  unestablished.** This file is smaller than some other detection engines seen in the broader
  Overdrive/Electro evaluation research (`docs/evaluations/`), and **nobody has determined
  whether that is because BladeWatch's fork represents an earlier version of the same code, or
  because it has evolved independently since the fork.** This matters concretely: it changes
  the cost of any future "port that engine's detection improvements" issue by several times
  (a port against a close relative is a diff; a port against an independently-diverged engine
  is a re-implementation), and it must not be quietly assumed away. Whoever picks up such an
  issue should re-establish this before estimating scope.
- **There is no automated test coverage for any of the ten invariants above.** `app/src/test/java/com/loabletech/bladewatch/surveillance/`
  contains only fisheye-dewarp tests and a config-toggles test — nothing exercises the native
  motion pipeline, the shadow/oscillation filters, the YOLO gate, or the sustained-motion/
  deterrent-suppression logic. Every invariant here is currently enforced by source code and
  verified, per its `FIX:` comment, by a human re-testing on a device after the fact. This
  document exists partly to compensate for that gap; it is not a substitute for eventually
  closing it.
- **Whether the "45 of 60 Overdrive signals available" style claims made elsewhere in
  `docs/evaluations/` apply to detection specifically has not been checked here.** This
  document is about what BladeWatch's OWN pipeline does, not a comparison; a future reader
  wanting that comparison has to do it separately, against this document's evidence-channel
  list, not assume parity.

## Source References

- Native motion pipeline: [motion_pipeline_v2.cpp](../app/src/main/cpp/surveillance/motion_pipeline_v2.cpp), [motion_pipeline_v2.h](../app/src/main/cpp/surveillance/motion_pipeline_v2.h)
- Texture tracker: [texture_tracker.h](../app/src/main/cpp/surveillance/texture_tracker.h), `texture_tracker.cpp`
- YOLO gate: [YoloDetector.kt](../app/src/main/java/com/loabletech/bladewatch/ai/YoloDetector.kt)
- Detection orchestration, sustained-motion/deterrent gating: [SurveillanceEngineGpu.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.kt)
- GPU pipeline plumbing (encoder, downscaler, recorder wiring): [GpuSurveillancePipeline.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.kt)
- Suppressors: [SafeLocationManager.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/SafeLocationManager.kt), [SurveillanceSchedule.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceSchedule.kt)
- Outer suppressor gating call sites: `AccSentryDaemon.java` (~line 1946–1959), `CameraDaemon.java` (~lines 1515, 2025–2037, 2264–2270)
- Encoder quality (not a detection channel): [AdaptiveBitrateController.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/AdaptiveBitrateController.kt)
