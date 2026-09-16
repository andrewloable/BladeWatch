/**
 * Human-readable size formatting.
 *
 * Extracted from `SettingsComponent` so it can be unit-tested: as component methods these
 * were reachable only through Angular's DI, which is why size formatting — the kind of code
 * where a `<` should have been `<=` and nobody notices until a value sits exactly on a
 * boundary — had no tests at all.
 *
 * Binary units throughout (1024, not 1000), matching what the daemon reports.
 */

const KIB = 1024;

/**
 * Format a byte count for display.
 *
 * Accepts `bigint` because the storage RPCs return 64-bit sizes; anything unusable — zero,
 * negative, NaN — renders as `0 B` rather than something alarming like `NaN GB`.
 */
export function formatBytes(value: number | bigint): string {
  const bytes = Number(value);
  if (!bytes || bytes < 0 || Number.isNaN(bytes)) return '0 B';
  if (bytes < KIB) return `${bytes} B`;

  const kb = bytes / KIB;
  if (kb < KIB) return `${kb.toFixed(1)} KB`;

  const mb = kb / KIB;
  if (mb < KIB) return `${mb.toFixed(1)} MB`;

  return `${(mb / KIB).toFixed(2)} GB`;
}

/**
 * Format a megabyte count, promoting to GB past 1024 MB.
 *
 * Used for storage-limit sliders, where the underlying setting is MB and showing "4096 MB"
 * reads worse than "4.0 GB".
 */
export function formatMb(mb: number): string {
  return mb >= KIB ? `${(mb / KIB).toFixed(1)} GB` : `${mb} MB`;
}
