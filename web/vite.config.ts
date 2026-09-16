import { defineConfig } from 'vite';
import angular from '@analogjs/vite-plugin-angular';

export default defineConfig({
  plugins: [angular()],
  // Per-build cache-bust token appended to the i18n catalog URL (see
  // app.config.ts). The catalog URLs are unhashed (unlike the content-hashed
  // JS/CSS bundle), so without this a browser that cached /i18n/en.json under
  // the old max-age=86400 would keep serving a stale catalog for 24h after an
  // app update — rendering raw keys. A fresh ?v=<build> per release makes the
  // new bundle request a URL the browser has never cached, so the catalog
  // refreshes immediately on the next load (no manual cache-clear / re-add).
  define: {
    __I18N_BUILD__: JSON.stringify(String(Date.now())),
  },
  build: {
    outDir: 'dist',
    rollupOptions: {
      /**
       * Silence two unactionable third-party warnings, and NOTHING else.
       *
       * The prebuilt ESM in @connectrpc and @bufbuild is TypeScript-compiled down to helpers
       * that reference `this` at module top level. Rollup correctly rewrites that to
       * `undefined` for ESM and warns (THIS_IS_UNDEFINED), then tries to map the location back
       * through a sourcemap those packages do not ship and warns again (SOURCEMAP_ERROR).
       * Both are correct behaviour on our side and unfixable on theirs short of vendoring.
       *
       * It is 124 lines per build, and the SOURCEMAP_ERROR text literally reads "Error when
       * using sourcemap for reporting an error" — so every green CI release log looked like it
       * contained 62 errors. That is the real cost: noise that trains you to ignore the build
       * output is worse than no output.
       *
       * Scoped to node_modules on purpose. The same two codes raised by OUR source are real
       * bugs (a top-level `this` in an Angular file is almost always a mistake) and still warn.
       */
      onwarn(warning, defaultHandler) {
        const noisy = warning.code === 'THIS_IS_UNDEFINED' || warning.code === 'SOURCEMAP_ERROR';
        const thirdParty = (warning.id ?? warning.loc?.file ?? '').includes('node_modules');
        if (noisy && thirdParty) return;
        defaultHandler(warning);
      },
    },
  },
  server: {
    proxy: {
      '/bladewatch.v1': 'http://127.0.0.1:8080',
      '/api': 'http://127.0.0.1:8080',
      '/status': 'http://127.0.0.1:8080',
      '/auth': 'http://127.0.0.1:8080',
    },
  },
});
