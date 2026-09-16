import { defineConfig, devices } from '@playwright/test';

/**
 * Mobile UI tests, deliberately separate from `playwright.config.ts`.
 *
 * The main e2e suite points at a LIVE head unit over a tunnel — it needs `e2e/.env`, a running
 * daemon, and a car that is awake. That is the right shape for testing real flows, and the
 * wrong shape for testing layout: nobody should have to power up a vehicle to find out whether
 * the settings page overflows on a phone.
 *
 * So this config serves the built app locally and asserts the things that are properties of the
 * UI itself rather than of the vehicle: does it fit the viewport, can a thumb hit the controls,
 * does the layout reflow instead of demanding horizontal scrolling. Those are exactly the
 * defects a desktop-only suite never sees, and the web UI is reached from a phone whenever the
 * owner is away from the car.
 *
 * Run: npx playwright test --config playwright.mobile.config.ts
 */
export default defineConfig({
  testDir: './e2e-mobile',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  timeout: 30_000,
  expect: { timeout: 10_000 },
  reporter: [['list']],

  // Serve the production build. This is what actually ships, so a layout bug introduced by
  // the bundler's CSS handling shows up here and would not in a dev-server run.
  webServer: {
    command: 'npx vite preview --port 4173 --strictPort',
    url: 'http://127.0.0.1:4173/',
    reuseExistingServer: !process.env.CI,
    timeout: 60_000,
  },

  use: {
    baseURL: 'http://127.0.0.1:4173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  // Two shapes, chosen for their differences rather than their popularity: a small Android
  // viewport at 3x density, and an iPhone whose Safari applies its own minimum font sizing and
  // safe-area insets. A layout that survives both survives most phones.
  projects: [
    { name: 'android-phone', use: { ...devices['Pixel 7'] } },
    { name: 'iphone', use: { ...devices['iPhone 13'] } },
  ],
});
