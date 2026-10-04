#!/bin/bash
# Make a one-architecture copy of the companion's universal macOS app (BladeWatch 1.4.1.2).
#
#   tools/thin_macos_app.sh <BladeWatch.app> <arm64|x86_64> <out dir>
#
# `flutter build macos` has no per-architecture option: it always builds arm64 + x86_64 into every
# binary, and flutter_pear_bare carries a whole Pear runtime for each (desktop/darwin-arm64 and
# desktop/darwin-x64). A Mac only ever runs one. This copies the app, keeps one slice of every
# binary, drops the other architecture's runtime, and re-signs ad hoc, as the build was: thinning
# invalidates the signature, and Apple Silicon refuses to run an unsigned arm64 binary.
#
# Safe because the plugin picks its runtime directory at COMPILE time per slice (`#if arch(arm64)`
# in FlutterPearBarePlugin.swift), so the arm64 slice never looks in darwin-x64, nor x86_64 in
# darwin-arm64.
set -euo pipefail

src=${1:?BladeWatch.app}
arch=${2:?arm64 or x86_64}
out=${3:?out dir}
case "$arch" in
  arm64) other=darwin-x64 ;;
  x86_64) other=darwin-arm64 ;;
  *) echo "arch must be arm64 or x86_64" >&2; exit 2 ;;
esac

mkdir -p "$out"
app="$out/$(basename "$src")"
rm -rf "$app"
ditto "$src" "$app"

rm -rf "$app"/Contents/Resources/flutter_pear_bare_flutter_pear_bare.bundle/Contents/Resources/desktop/"$other"

# Every Mach-O that carries both slices; a file lipo cannot read is not a binary.
while IFS= read -r -d '' f; do
  archs=$(lipo -archs "$f" 2>/dev/null) || continue
  case " $archs " in *" $arch "*) ;; *) echo "$f has no $arch slice ($archs)" >&2; exit 1 ;; esac
  [ "$archs" = "$arch" ] || lipo -thin "$arch" -output "$f" "$f"
done < <(find "$app" -type f -print0)

# Inside out: nested code first, then the app with its own entitlements kept.
find "$app/Contents" -depth \( -name '*.framework' -o -name '*.dylib' -o -name '*.bare' -o -name '*.bundle' -o -name '*.app' \) -print0 \
  | while IFS= read -r -d '' code; do
      codesign --force --sign - --preserve-metadata=identifier,entitlements,flags "$code" 2>/dev/null || true
    done
codesign --force --sign - --preserve-metadata=identifier,entitlements,flags "$app"
codesign --verify --deep --strict "$app"
echo "$app: $(du -sh "$app" | cut -f1), $arch only"
