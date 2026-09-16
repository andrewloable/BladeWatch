#!/usr/bin/env node
/**
 * Generate the canonical ISO 4217 currency-code list from ICU.
 *
 * Usage:  node tools/gen-currencies.mjs
 *
 * WHY GENERATED. There are ~162 active ISO 4217 codes. A hand-typed list rots
 * silently: a code is mistyped, a currency is redenominated, and nobody notices
 * until an owner cannot find their own currency in the picker. Node's ICU data
 * already carries the authoritative set, so the list is derived from it and the
 * RESULT is committed — the app never calls this at runtime.
 *
 * WHY THE APP DOES NOT CALL ICU ITSELF. `Intl.supportedValuesOf` is ES2022. The
 * head unit runs an Android 10 WebView that does not reliably auto-update on a
 * BYD unit, so relying on it in shipped web code would fail on the one device
 * that matters. Generation happens here, on a dev machine, at author time.
 *
 * WHY NO SYMBOLS. The list is CODES ONLY. Each platform formats currency from
 * its own ICU data at render time — `Intl.NumberFormat` on the web,
 * `NumberFormat.simpleCurrency` via the `intl` package in Flutter. Shipping a
 * symbol table would mean maintaining placement, spacing and decimal-digit
 * rules per currency per locale, which is precisely what ICU already does.
 *
 * Both consumer copies are written from this one run and are byte-identical.
 * `validateCurrencyCatalog` (wired into preBuild) fails the build if they drift,
 * following the same precedent as `validateI18nCatalogs`.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

if (typeof Intl.supportedValuesOf !== 'function') {
  console.error(
    'This Node lacks Intl.supportedValuesOf (needs Node 18+ with full ICU).\n' +
      'Install a full-ICU Node and re-run; do NOT hand-edit the generated files.'
  );
  process.exit(1);
}

const codes = Intl.supportedValuesOf('currency').slice().sort();

if (codes.length < 100) {
  console.error(
    `Only ${codes.length} currency codes from ICU — this Node looks like a ` +
      'small-ICU build. Refusing to write a truncated list.'
  );
  process.exit(1);
}

const payload = {
  _generated:
    'GENERATED FILE - DO NOT EDIT. Regenerate with: node tools/gen-currencies.mjs',
  _source: `ICU via Intl.supportedValuesOf('currency') on Node ${process.version}`,
  _note:
    'Codes only. Symbols and formatting come from each platform ICU at render time.',
  codes,
};

// Both consumers get a byte-identical copy. Two copies exist because the web and
// Flutter builds are separate projects with separate asset pipelines; the drift
// check is what keeps them honest.
const targets = [
  join(repoRoot, 'web', 'src', 'assets', 'iso4217.json'),
  join(repoRoot, 'flutter_ui', 'assets', 'iso4217.json'),
];

const json = JSON.stringify(payload, null, 2) + '\n';
for (const t of targets) {
  mkdirSync(dirname(t), { recursive: true });
  writeFileSync(t, json, 'utf8');
  console.log(`wrote ${codes.length} codes -> ${t.replace(repoRoot + '/', '')}`);
}
