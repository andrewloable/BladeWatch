import { expect, test } from '@playwright/test';

/**
 * Mobile layout for the web UI.
 *
 * The web app is what the owner reaches for when they are away from the car — which means a
 * phone, not a desktop. The existing e2e suite runs Desktop Chrome against a live head unit, so
 * nothing has ever checked that the UI actually fits a phone.
 *
 * These assert properties of the UI rather than of the vehicle, so they run against a locally
 * served build with no daemon. That is the point: a layout regression should be catchable
 * without powering up a car.
 */

/** Widest element that overflows the viewport, or null. Named so failures are actionable. */
async function findHorizontalOverflow(page: import('@playwright/test').Page) {
  return page.evaluate(() => {
    const docWidth = document.documentElement.clientWidth;
    // A couple of pixels of slack: sub-pixel rounding on scaled viewports is not a bug.
    const tolerance = 2;
    for (const el of Array.from(document.querySelectorAll<HTMLElement>('body *'))) {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) continue;
      const style = getComputedStyle(el);
      if (style.position === 'fixed' && style.visibility === 'hidden') continue;
      if (rect.right > docWidth + tolerance) {
        return {
          tag: el.tagName.toLowerCase(),
          cls: el.className?.toString().slice(0, 80) ?? '',
          right: Math.round(rect.right),
          docWidth,
        };
      }
    }
    return null;
  });
}

test.describe('mobile layout', () => {
  test.beforeEach(async ({ page }) => {
    // Serve the i18n catalogue ourselves. It normally comes from the DAEMON, not from the
    // static bundle, so a preview server returns 404 and every label renders empty.
    //
    // That is not a cosmetic difference for these tests, it is the difference between
    // measuring the real UI and measuring a broken one: an empty button collapses to its
    // padding. Measured — the login button reports 28px with no label and ~46px with one, so
    // without this the suite reports a touch-target defect that does not exist.
    await page.route('**/i18n/*.json*', async (route) => {
      const fs = await import('node:fs/promises');
      const path = await import('node:path');
      const file = path.resolve(
        __dirname,
        '../../app/src/main/assets/web/i18n/en.json',
      );
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: await fs.readFile(file, 'utf8'),
      });
    });

    await page.goto('/');
    // The app is served without a daemon, so RPCs fail — that is fine and expected. Wait for
    // the shell to paint rather than for network idle, which never arrives.
    await page.waitForLoadState('domcontentloaded');
    await expect(page.locator('body')).toBeVisible();
    // Labels arrive asynchronously once the catalogue resolves; without this the very first
    // assertion can still measure an unlabelled control.
    await expect(page.locator('button').first()).not.toBeEmpty();
  });

  /**
   * THE mobile defect. A page that scrolls sideways is the classic symptom of a fixed width or
   * an unwrapped flex row, and it makes a UI genuinely unpleasant to use one-handed.
   */
  test('the page does not scroll horizontally', async ({ page }) => {
    const overflow = await findHorizontalOverflow(page);
    expect(
      overflow,
      overflow
        ? `<${overflow.tag} class="${overflow.cls}"> extends to ${overflow.right}px ` +
          `in a ${overflow.docWidth}px viewport`
        : '',
    ).toBeNull();
  });

  test('the document is no wider than the viewport', async ({ page }) => {
    const { scrollWidth, clientWidth } = await page.evaluate(() => ({
      scrollWidth: document.documentElement.scrollWidth,
      clientWidth: document.documentElement.clientWidth,
    }));
    expect(scrollWidth, 'document scrolls wider than the screen').toBeLessThanOrEqual(
      clientWidth + 2,
    );
  });

  /**
   * Interactive controls need to be hittable with a thumb. 44px is Apple's long-standing
   * guidance and roughly the width of an adult fingertip; below that, taps start missing.
   *
   * Reported as a list rather than failing on the first offender, so one run tells you
   * everything to fix.
   */
  test('interactive controls are large enough to tap', async ({ page }) => {
    const tooSmall = await page.evaluate(() => {
      const MIN = 44;
      const offenders: string[] = [];
      const selector = 'button, a[href], input, select, [role="button"]';
      for (const el of Array.from(document.querySelectorAll<HTMLElement>(selector))) {
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) continue; // not rendered
        if (getComputedStyle(el).visibility === 'hidden') continue;
        if (rect.height < MIN) {
          const label = (el.textContent ?? '').trim().slice(0, 30) || el.tagName.toLowerCase();
          offenders.push(`${label} (${Math.round(rect.height)}px)`);
        }
      }
      return offenders;
    });

    expect(tooSmall, `controls under 44px tall: ${tooSmall.join(', ')}`).toEqual([]);
  });

  /**
   * Without a viewport meta tag a mobile browser renders at a desktop width and scales down,
   * which makes every other mobile assertion meaningless and the text unreadable.
   */
  test('a responsive viewport meta tag is present', async ({ page }) => {
    const content = await page.locator('meta[name="viewport"]').getAttribute('content');
    expect(content, 'no viewport meta tag').toBeTruthy();
    expect(content).toContain('width=device-width');
  });

  /**
   * Body text below about 12px is uncomfortable on a phone and is what iOS Safari will
   * silently inflate, breaking the layout the designer intended.
   */
  test('body text is legible without zooming', async ({ page }) => {
    const size = await page.evaluate(() =>
      parseFloat(getComputedStyle(document.body).fontSize),
    );
    expect(size).toBeGreaterThanOrEqual(12);
  });
});
