#!/usr/bin/env bash
# BladeWatch-ncbb.5: Dart coverage gate for flutter_ui.
#
# Reads flutter_ui/coverage/lcov.info (produced by `flutter test --coverage`),
# excludes lib/gen/** (generated protobuf — never hand-written, so it would
# inflate the denominator with untested boilerplate) and the narrow named
# exclusions in EXCLUDED_FILES below, prints the resulting line-coverage
# percentage, and exits non-zero if it is below THRESHOLD.
#
# Usage:
#   flutter test --coverage   # from flutter_ui/
#   tools/check_flutter_coverage.sh [threshold]   # from the repo root
#
# THRESHOLD defaults to the baseline below and may only ever be raised, never
# lowered — see docs/build-and-operations.md for the ratchet policy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LCOV_FILE="$REPO_ROOT/flutter_ui/coverage/lcov.info"

# Baseline measured 2026-09-12 (BladeWatch-ncbb.1) after adding lib/rpc/**
# (the Connect transport + all 12 typed service clients): 323/325 lines.
# Floor of that real figure. (Previous baseline, BladeWatch-ncbb.5: 92, from
# the untouched `flutter create` template alone.)
THRESHOLD="${1:-99}"

if [ ! -f "$LCOV_FILE" ]; then
  echo "check_flutter_coverage: $LCOV_FILE not found — run 'flutter test --coverage' from flutter_ui/ first" >&2
  exit 1
fi

# Named per-file exclusions, mirroring the Kotlin Kover gate's own exclusion
# list (e.g. LocationServiceChannel*, HttpConnectionsKt) for the same reason
# in each case: a thin platform-boundary wrapper with no branching logic of
# its own, verified on-device instead of by a unit/widget test. Add an entry
# only with a comment explaining which boundary makes it untestable here —
# "hard to test" alone is not a reason (see docs/build-and-operations.md).
EXCLUDED_FILES=(
  # BladeWatch-yz1e.9: constructing a real WebViewController throws
  # `WebViewPlatform.instance != null` in any plain `flutter test` run — no
  # platform implementation is registered outside a real app/device
  # (confirmed empirically, not assumed). VehicleScreen's own heroBuilder
  # test seam keeps every other widget in that screen fully testable.
  "lib/screens/vehicle/vehicle_hero.dart"
)

read -r lf lh <<< "$(awk -F: -v excluded="${EXCLUDED_FILES[*]}" '
  BEGIN { n = split(excluded, ex, " ") }
  /^SF:/ {
    file = $2; skip = (file ~ /^lib\/gen\//)
    if (!skip) { for (i = 1; i <= n; i++) { if (file == ex[i]) { skip = 1; break } } }
  }
  /^LF:/ { if (!skip) { lf += $2 } }
  /^LH:/ { if (!skip) { lh += $2 } }
  END { print lf+0, lh+0 }
' "$LCOV_FILE")"

if [ "$lf" -eq 0 ]; then
  echo "check_flutter_coverage: no coverable lines found in $LCOV_FILE (after excluding lib/gen/**)" >&2
  exit 1
fi

pct=$(awk -v lh="$lh" -v lf="$lf" 'BEGIN { printf "%.2f", (lh / lf) * 100 }')
pct_floor=$(awk -v lh="$lh" -v lf="$lf" 'BEGIN { printf "%d", (lh / lf) * 100 }')

echo "Dart coverage (lib/gen/** + ${#EXCLUDED_FILES[@]} named file(s) excluded): $lh/$lf lines = ${pct}%"

if [ "$pct_floor" -lt "$THRESHOLD" ]; then
  echo "check_flutter_coverage: ${pct}% is below the required ${THRESHOLD}%" >&2
  exit 1
fi

echo "check_flutter_coverage: OK (>= ${THRESHOLD}%)"
