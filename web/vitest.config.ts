import { defineConfig } from 'vitest/config';

/**
 * Unit-test config, deliberately separate from `vite.config.ts`.
 *
 * The app build runs `@analogjs/vite-plugin-angular`, which compiles Angular decorators and
 * templates. Applied to a plain `.spec.ts` it rewrites the file to the point that vitest finds
 * no suite in it at all ("No test suite found"), so the plugin is left out here.
 *
 * That also defines the scope on purpose: these are UNIT tests for framework-free logic —
 * currency formatting, catalogue handling — not component tests. Component and flow coverage
 * is Playwright's job under `e2e/`, running against a real browser where Angular's own
 * rendering is exercised rather than simulated.
 */
export default defineConfig({
  test: {
    // Plain TS units only. Anything needing Angular's compiler belongs in e2e/.
    include: ['src/**/*.spec.ts'],
    environment: 'node',
    // The generated ISO 4217 catalogue is imported as JSON; keep resolution aligned with
    // the app's tsconfig so the import resolves the same way in tests as in the build.
    globals: false,
  },
});
