import { describe, expect, it } from 'vitest';
import en from '../../../../../app/src/main/assets/web/i18n/en.json';

/**
 * BladeWatch-y78o.1 requires the still-frame view to be "visibly labelled as still frames, not
 * presented as live video" — live.component.html renders `live.stillFrameLabel` (translate
 * pipe) whenever `usingStillFrame()` is true.
 *
 * This project's vitest config is deliberately DOM-free (`environment: 'node'`, see
 * vitest.config.ts's own comment: "Anything needing Angular's compiler belongs in e2e/") and
 * there is no existing component-test harness — no `*.component.spec.ts` file exists anywhere
 * in this codebase. Rendering the template itself is therefore Playwright's job, not vitest's;
 * `typecheck:templates` is what actually catches a typo'd binding (this project's own documented
 * lesson: such a typo "compiles clean... and silently renders nothing at runtime" under both
 * `tsc` and `vite build`).
 *
 * What IS meaningfully testable here, without a DOM: that the key the template references
 * actually exists in the shipped catalogue and is not empty — catching "forgot to add the key"
 * or "added an empty string", either of which would leave the label rendering nothing.
 */
describe('live.stillFrameLabel', () => {
  it('exists in the English catalogue and is non-empty', () => {
    expect(en.live.stillFrameLabel).toBeTruthy();
    expect(typeof en.live.stillFrameLabel).toBe('string');
  });

  it('mentions "still" and is distinct from the LIVE badge text — not just any non-empty string', () => {
    // Loose on purpose (no exact-string pin, this is prose that may get copy-edited) but
    // specific enough to catch someone accidentally wiring the key to the wrong text, e.g. a
    // copy-paste of badgeLive that would relabel the fallback as "live" instead of "still".
    const text = en.live.stillFrameLabel.toLowerCase();
    expect(text).toContain('still');
    expect(text).not.toBe(en.live.badgeLive.toLowerCase());
  });
});
