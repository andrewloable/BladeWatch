# UI/UX Design Language

BladeWatch's interface follows **Material 3** (Material You), as defined at
<https://m3.material.io/>. The **Flutter in-car UI** (`flutter_ui/`,
`net.bladewatch.incarapp`) is the canonical M3 surface — color roles, type scale,
shape scale, elevation model, and motion curves — and additionally adopts
**Material 3 Expressive** refinements (tighter type tracking, tonal active
indicators) tuned for a large in-car display.

> **This changed in Phase 4.** The native Kotlin shell that used to be the source
> of truth was deleted (`BladeWatch-81g9.2`). `packages/bladewatch_theme/lib/*_tokens.dart`
> is now authoritative; the Android XML themes survive only for the two surfaces
> the service host still draws (the status overlay and `SetupGuideDialog`) and
> must be kept in step with Dart, not the other way round. The parity tests under
> `flutter_ui/test/theme/` read the XML and assert it matches the Dart tokens, so
> drift fails the build without a device.

There is no web UI any more: the Angular SPA, the static pages and the generated
`design-tokens.css` they used were removed (BladeWatch-rdtj.22). The Dart tokens below are
the **source of truth**; the Android XML is derived from them for the status overlay only.

> Material 3 version: **1.13.0** (Android Material Components), per
> [libs.versions.toml:9](../gradle/libs.versions.toml#L9).

## Two layers, one language

| Layer | Renders | Role |
|-------|---------|------|
| **Flutter** (`flutter_ui/`, `net.bladewatch.incarapp`, and the companion app) | the whole in-car UI: nav rail, every screen, every dialog; the companion's screens | **M3 source of truth**, shared by both apps through `packages/bladewatch_theme` (BladeWatch-rdtj.11) — [color_tokens.dart](../packages/bladewatch_theme/lib/color_tokens.dart), [type_tokens.dart](../packages/bladewatch_theme/lib/type_tokens.dart), [dimens_tokens.dart](../packages/bladewatch_theme/lib/dimens_tokens.dart), assembled in [bladewatch_theme.dart](../packages/bladewatch_theme/lib/bladewatch_theme.dart) |
| **Android XML** (`net.bladewatch.app`) | the status overlay and `SetupGuideDialog` **only** | **Derived.** [colors_m3.xml](../app/src/main/res/values/colors_m3.xml) (+ `values-night`), [themes_bladewatch.xml](../app/src/main/res/values/themes_bladewatch.xml), [dimens_bladewatch.xml](../app/src/main/res/values/dimens_bladewatch.xml). Kept in step by the parity tests in `flutter_ui/test/theme/` |

Icons in Flutter use the built-in Material Icons font by semantic name
(`Icons.dashboard`, `Icons.directions_car`, …) rather than the Material Symbols
Rounded font the icon table below specifies — the closest available equivalent.
The XML drawables in that table are still the overlay's icons.

When a role changes, change the Dart token first. The XML parity tests will fail
until the overlay follows.

**Target device.** BYD Seal 15.6″ rotatable infotainment — landscape
`1920×1080`, portrait `1080×1920`. The design language is tuned for this large,
bright, glanceable surface, not a phone.

**In dp, measured on the head unit 2026-09-20.** `wm density` reports **240**, so the
device pixel ratio is `240/160 = 1.5`. Three different numbers matter and conflating
them is how layouts get mis-sized:

| Landscape | px | dp | What it is |
|---|---|---|---|
| Display | `1920×1080` | `1280×720` | The panel. Not a layout budget. |
| Usable window | `1920×906` | `1280×604` | After the system status and bottom bars — `dumpsys window` reports `mStable=[0,84][1920,990]`. |
| Screen body | `1920×830` | `1280×553` | After the app's own toolbar. **This is what a screen actually lays out in.** |

This line previously claimed `960×540dp` / `540×960dp`, which assumes density 320. The
width was genuinely wrong — `960` against a real `1280`. The height was wrong about the
display but landed near the real *body* height by coincidence, which is why layout
arithmetic done against `540dp` looked plausible. Measure with
`adb shell wm size; wm density` for the display and `adb shell dumpsys window | grep mStable`
for the usable window; do not trust any of these numbers from memory.

**Both orientations must lay out.** The unit rotates, and a screen built for only one of
them does not merely look cramped in the other — it clips. The Vehicle screen shipped a
single `Stack` whose hero, tyre cards and control panel shared no constraint, which was
fine in portrait and covered the car entirely in landscape (BladeWatch-vuul).

### Responsive breakpoints

The spacing table below is the token set for *rhythm*; it has no entry for a breakpoint,
so these are recorded here instead of being reinvented per screen. Each is measured, not
picked:

| Constant | Value | Why that number |
|---|---|---|
| wide-layout minimum width | `700dp` | Between the device's two orientations (`1280dp` landscape, `720dp` portrait), so in practice it is an orientation switch, expressed as a width so it degrades sensibly elsewhere. |
| two-up control minimum width | `500dp` | A stepper's −/value/+ cluster is rigid: two `48dp` icon buttons plus the value, so only its label can absorb a squeeze. Two steppers in a `432dp` column overflowed by 16px. |
| portrait controls maximum height | `0.55` of the screen | A **cap**, not a target — the panel shrink-wraps its content and scrolls past it. The car takes whatever is left. |

**Do not express the portrait split as `Expanded` + `Flexible`.** Both are flex children
with flex `1`, so `RenderFlex` splits the height 50/50 no matter what the content wants:
the hero is capped at half the screen and the slack becomes dead space at the bottom.
Measured at `720×1280`: hero `640`, controls `200`, `440px` of nothing underneath. Make
the controls a **non-flex** child with a bounded height — non-flex children are measured
first, so the single remaining flex child takes everything left.

## UI Refactor Ground Rules

> **Historical.** These governed the 2025 native-Android M3 refactor, whose
> subject — the Kotlin fragments and XML layouts — was deleted in Phase 4
> (`BladeWatch-81g9.2`). They still apply verbatim to the status overlay and
> `SetupGuideDialog`, the only XML surfaces left. For the Flutter UI the
> equivalent rule is simpler: visual changes never alter behaviour, never change
> which RPC a control calls, and never change a user-visible string's meaning.

**Scope: visual / UI refactor ONLY.** The app is in production and runs
perfectly today. This initiative changes only the *appearance* of the UI to the
Material 3 language. It must **not change, add, or remove any functionality,
feature, or behavior.**

**Preserve all behavior:**

- Do not add new features/screens, and do not remove or hide existing ones.
- Do not change navigation structure, routes, or the set of actions/controls on
  any screen.
- Do not change the data shown, units, number/time formatting semantics,
  thresholds, or any business logic.
- Do not touch daemon / IPC / HTTP / WebSocket / BYD comms, config keys, storage
  paths, auth, or any non-UI code.
- Keep every user-visible string and its meaning — you may restyle text, not
  reword it.

**Do not break the code ↔ view wiring:**

- Do **not** rename or delete view IDs (`@+id/...`), click handlers,
  `ViewBinding` / `findViewById` references, adapter view types, tags, or
  `contentDescription`s that code relies on. If a view ID genuinely must change,
  update **every** reference in Kotlin/Java/tests in the same change.
- Keep view types compatible with the fragment's code (a `RecyclerView` stays a
  `RecyclerView`, a `ViewPager2` stays a `ViewPager2`, etc.).
- Icon refactors keep the **same drawable resource names/IDs** (`@drawable/ic_*`)
  so every layout/menu/code reference still resolves — only the vector art
  changes to the Material Symbols style.

**Allowed changes (visual only):** colors → M3 roles; corners → M3 shape scale;
text styles → M3 type scale; spacing/padding → M3 spacing tokens; swapping a raw
widget for the `Widget.BladeWatch.M3.*` equivalent **when behavior is
identical**; icons → M3 Material Symbols; ripple/press feedback; motion and
transitions.

**Verify before closing:** build, deploy to the head unit
(`$CAR_IP:5555`) following the clean-reinstall steps in `CLAUDE.md`, and
confirm the screen looks M3-correct in **light and dark** *and* behaves exactly
as before — every control, list, dialog, and data field works identically. A
behavior difference is a regression; fix it before closing.

**If unsure, stop and ask.** Never guess at functionality.

## Color

BladeWatch uses the full M3 tonal color-role system
(<https://m3.material.io/styles/color/system/overview>). Every UI color is a
**role**, never a raw hex value. Both **light and dark** variants ship and are
complete; dark is the default on the head unit.

**Accent roles** — each has a `*-container` and an `on-*` text pair:

- `primary` — cyan-blue brand accent (dark `#3CD7FF`, light `#00677E`); CTAs,
  active states, sliders. Generated from the BladeWatch logo seed `#00D4FF`
  (see `drawable/ic_sidebar_logo.xml`).
- `secondary` — muted blue-grey; secondary affordances, nav active-indicator container.
- `tertiary` — indigo (dark `#C1C4EB`, light `#595C7E`); links, info accents, and
  the second stop of the brand accent stripe — kept distinct from the cyan primary.
- `error` — destructive actions and validation.

**Surfaces & neutrals:**

- `background` / `surface` — the base canvas.
- Five **surface-container tiers** — `surface-container-lowest` → `-low` →
  `surface-container` → `-high` → `-highest` — used for tonal elevation (cards,
  sheets, and dialogs sit on progressively higher tiers).
- `surface-variant`, `surface-dim`, `surface-bright`.
- `outline` / `outline-variant` — borders, dividers, hints.
- `inverse-surface` / `inverse-on-surface` / `inverse-primary` — snackbars and
  inverted chips.
- `scrim` — modal scrims.

**Status colors** (BladeWatch domain, layered on top of M3):
`status-success`, `status-warning`, `status-danger`, `status-info` — SOC/battery
state, sentry state, alerts.

- Flutter (source of truth): [color_tokens.dart](../packages/bladewatch_theme/lib/color_tokens.dart).
- **Reaching them from a widget:** `Theme.of(context).extension<BwStatusColors>()!`.
  `ColorScheme` has no success/warning slot, so these four are registered as a
  `ThemeExtension` on both themes rather than being squeezed into an M3 role.
  Use the extension — do **not** re-derive a status colour by branching on
  `theme.brightness` and writing the hex inline. That is what
  `settings_daemons_screen.dart` had done, reproducing `statusWarning`'s dark
  value verbatim under a comment noting the theme had no such role; a token
  reimplemented by hand has stopped being a token.
- Android (derived, overlay + setup dialog only): [colors_m3.xml](../app/src/main/res/values/colors_m3.xml) (light) and
  [values-night/colors_m3.xml](../app/src/main/res/values-night/colors_m3.xml)
  (dark), bound to theme attributes in
  [themes_bladewatch.xml](../app/src/main/res/values/themes_bladewatch.xml).

> **Rule:** reference color **roles**, never raw hex.

## Typography

Type follows the M3 type scale
(<https://m3.material.io/styles/typography/type-scale-tokens>) with **M3
Expressive** tightening so text reads crisp on a 1920×1080 head unit — stock M3
tracking looks soft at that size and viewing distance.

- **Android** overrides the display / headline / title / label roles to
  `sans-serif-medium` with negative tracking on the large roles and small
  positive tracking on labels. Body roles inherit M3 defaults (long-form text
  doesn't benefit from tighter tracking). See
  `TextAppearance.BladeWatch.*` in
  [themes_bladewatch.xml](../app/src/main/res/values/themes_bladewatch.xml).
- **Web** families: `Inter` (sans, `--family-sans`) and `JetBrains Mono`
  (mono, `--family-mono`).

| Role | Letter spacing (Android / web var) |
|------|-----------------------------------|
| Display Small | `-0.02` |
| Headline Large | `-0.02` |
| Headline Medium | `-0.015` |
| Headline Small | `-0.01` |
| Title Large | `-0.005` |
| Title Medium | `0` |
| Label Large | `+0.01` |
| Label Medium | `+0.04` |

Web tracking vars: `--tracking-display` `-0.02em`, `--tracking-headline`
`-0.015em`, `--tracking-title` `-0.005em`, `--tracking-label` `0.01em`.

## Shape & Elevation

### Shape

M3 rounded shape scale (<https://m3.material.io/styles/shape/overview>), mapped
to components:

| Token (Android / web) | Radius | Used by |
|-----------------------|--------|---------|
| `card_radius_xs` / `--radius-xs` | `4dp` | M3 extra-small: very small chips, badge corners |
| `card_radius_sm` / `--radius-sm` | `8dp` | M3 small: nav-rail active indicator, small badges |
| `card_radius_accent` / `--radius-md` | `14dp` | pills inside cards, segmented buttons, buttons |
| `card_radius_standard` / `--radius-lg` | `20dp` | dashboard metrics, diagnostics tiles, integration cards, settings sections |
| `card_radius_hero` / `--radius-xl` | `24dp` | dashboard hero, recordings preview pane |
| `card_radius_dialog` / `--radius-2xl` | `28dp` | dialogs and bottom sheets (M3 spec) |
| — / `--radius-full` | `full` | fully-rounded pills |

- Android: `card_radius_*` in
  [dimens_bladewatch.xml](../app/src/main/res/values/dimens_bladewatch.xml) and
  `ShapeAppearance.BladeWatch.Small`/`LargeComponent` in
  [themes.xml](../app/src/main/res/values/themes.xml).

### Elevation

M3 **tonal elevation** (<https://m3.material.io/styles/elevation/overview>):
components elevate by sitting on a higher **surface-container** tier, not by
casting heavy shadows.

- Android cards are flat — `cardElevation=0dp` on `colorSurfaceContainer`
  (Filled card style).
- Web exposes optional drop shadows `--shadow-sm/md/lg` (softer values under
  light theme) for floating elements, but surface tiers carry most of the
  hierarchy.

## Motion & Layout

### Motion

M3 motion (<https://m3.material.io/styles/motion/overview>) — durations and
easings:

- Durations: `--duration-short` `180ms`, `--duration-med` `240ms`,
  `--duration-long` `320ms`.
- Easings: `--easing-standard` `cubic-bezier(0.2, 0, 0, 1)`,
  `--easing-emphasized` `cubic-bezier(0.05, 0.7, 0.1, 1)` (M3 emphasized),
  `--easing-decel` `cubic-bezier(0, 0, 0.2, 1)`.

Interactions share a consistent press/hover language — hover lifts onto a
tonal-primary surface, press scales down — between the native nav links and the
web brand cluster.

### Layout rhythm

Canonical spacing tokens. **Layouts must reference tokens, never hard-coded dp.**

| Token | Value |
|-------|-------|
| page padding (h / top / bottom) | `24` / `20` / `24` dp |
| inter-card gap | `12dp` (split `6`/`6` in horizontal grids) |
| card padding (standard / hero) | `20` / `24` dp |
| grid tile min-height | `128dp` |
| card icon (standard / service / hero) | `24` / `32` / `56` dp |

- Android:
  [dimens_bladewatch.xml](../app/src/main/res/values/dimens_bladewatch.xml).

## Components

All native components derive from `Widget.Material3.*` via
`Widget.BladeWatch.M3.*` in
[themes_bladewatch.xml](../app/src/main/res/values/themes_bladewatch.xml)
(<https://m3.material.io/components>).

- **Cards** — Filled (`colorSurfaceContainer`, `0dp` elevation, `20dp` corners)
  is the default; the Outlined variant uses a `1dp` `colorOutlineVariant` stroke.
- **Buttons** — Filled, Tonal, Outlined, Text. `textAllCaps=false`,
  `sans-serif-medium`, `14dp` pill corners (Text = `10dp`). Outlined uses a
  `colorOutline` stroke.
- **Navigation rail** (primary navigation, M3 Expressive) — `colorSurface`
  background, `colorOnSurfaceVariant` items, a `colorSecondaryContainer`
  `56×32dp` pill **active indicator**, labels always visible. In landscape (the head
  unit: ~604 logical px between the car's own bars at 1.5x) the rail is dense (2dp item
  padding, 2dp icon-to-label gap, compact language button) so the language button and every
  destination fit without scrolling; each item stays over 48dp tall, and the rail's panel
  always runs the full height (BladeWatch-5l5o).
- **Segmented buttons** — single-selection `MaterialButtonGroup`
  (e.g. the Dashcam / Surveillance mode toggle).
- **Slider** — `colorPrimary` track / thumb / halo; inactive track
  `colorSurfaceContainerHighest`.
- **Bottom sheet** — `colorSurfaceContainerLow`, large-component (`16dp`) shape.
- **Dialogs** — `28dp` corners on `colorSurfaceContainerHigh`; a **filled-tonal
  primary CTA** plus a flat-text neutral action; a tinted `32dp` `colorPrimary`
  title icon. Used by `MaterialAlertDialogBuilder` and the custom-view dialogs
  (setup guide, battery health, reset data, camera selection, ROI drawing, …).
- **Top app bar & accent stripe** — an optional glass top app bar; a `3px`
  `primary → tertiary` gradient **accent stripe** anchors the brand at the top
  of every page (the native toolbar and the web sidebar share the same
  gradient). The Flutter shell builds it in
  [app_shell.dart](../flutter_ui/lib/shell/app_shell.dart); the old
  `app-shell.css` was retired with the legacy static pages in `c970b59`.
- **Inline caption / honesty text** — a short `bodySmall` line placed directly
  under the control it explains (no icon, no tinted container), used for
  plain-language cost or side-effect disclosures such as the Sentry mode
  battery-drain note and the camera-contention note in
  [surveillance_screen.dart](../flutter_ui/lib/screens/surveillance/surveillance_screen.dart),
  and the drive-format warning in the same file. Conditional captions (shown
  only while the condition they describe is actually true, e.g. camera
  contention) must not be replaced with a permanently visible caption — see
  `surveillance_screen_test.dart`'s `'General tab'` group.
- **Utility rail** (BladeWatch-y78o.2) — a narrow, fixed-width (`168dp`)
  `colorSurface`-dark (`0xFF101010`, the same fixed tone the Live screen's
  direction bar/mark button already used before this) column alongside a
  full-stage primary view, carrying a screen's secondary controls and a
  compact preview of another destination. First used in
  [live_view_screen.dart](../flutter_ui/lib/screens/live_view/live_view_screen.dart):
  the camera keeps the whole video area, and the rail carries the 5-way
  direction selector, the recording bookmark button, and a location preview.
  A preview in this rail is a **summary**, never a second live instance of
  the destination it previews (no embedded map here — a short status line
  reusing the destination's own strings) — tapping it navigates to the real
  destination, which stays in the primary nav rail.

## Icons

BladeWatch uses **Material Symbols Rounded** exclusively for all UI icons
(<https://m3.material.io/styles/icons/overview>). Every icon is drawn on a
`24dp` grid at **weight 400**, **grade 0**, **optical size 24**. Most icons use
**fill 0** (outlined); a small set use **fill 1** (filled) for active or
positive states.

### Implementation pattern

Android vector drawables use one of two approaches:

1. **Scaled group (most icons)** — viewport stays `24×24`; a `<group>` applies
   `scaleX/Y=0.025` + `translateY=24` so the Material Symbols 960-unit path
   data renders on the correct pixel grid without coordinate transforms in the
   path itself.
2. **Direct 960 viewport** (e.g. `ic_notifications`) — `viewportWidth/Height`
   is `960`; the `<group>` applies only `translateY=960`. This avoids a
   vector clip bug on this head unit's renderer that occasionally crops the
   trailing edge of paths rendered through an inner-group scale transform.
   (Measured platform: **Android 10 / API 29, WebView 74, Vulkan 1.1** — earlier
   revisions of this doc said Android 7.1 / Chrome 58, which was never true of
   the hardware.)

All M3 icons carry `android:tint="?attr/colorOnSurfaceVariant"` so they
auto-flip between light and dark themes. The navigation rail additionally
applies a `colorSecondaryContainer` active-indicator tint via the
`Widget.BladeWatch.M3.NavigationRailView` style — the icon drawable itself does
not encode that active color.

> **Rule:** when replacing icon art, keep the exact resource file name
> (`@drawable/ic_*`) so every layout, menu, and code reference continues to
> resolve — only the `<path>` data changes.

### Icon → Material Symbol mapping

| Resource ID | Material Symbol | Fill | Role |
|-------------|----------------|------|------|
| `@drawable/ic_back` | `arrow_back` | 0 | Navigation back button |
| `@drawable/ic_battery_health` | `battery_charging_full` | 0 | Battery health status |
| `@drawable/ic_camera_probe` | `photo_camera` | 0 | Camera setup / probe |
| `@drawable/ic_camera_select` | `switch_camera` | 0 | Camera source selection |
| `@drawable/ic_check` | `check` | 1 | Confirmation / done (filled) |
| `@drawable/ic_check_circle` | `check_circle` | 1 | Success state (filled circle) |
| `@drawable/ic_chevron_left` | `chevron_left` | 0 | Navigate left / collapse left |
| `@drawable/ic_chevron_right` | `chevron_right` | 0 | Navigate right / expand right |
| `@drawable/ic_clear` | `close` | 0 | Clear input / dismiss |
| `@drawable/ic_cloud` | `cloud` | 0 | Cloud connectivity |
| `@drawable/ic_collapse` | `expand_less` | 0 | Collapse panel upward |
| `@drawable/ic_console` | `terminal` | 0 | ADB debug console |
| `@drawable/ic_copy` | `content_copy` | 0 | Copy to clipboard |
| `@drawable/ic_daemons` | `hub` | 0 | Background daemon processes |
| `@drawable/ic_dashboard` | `dashboard` | 0 | Dashboard screen |
| `@drawable/ic_delete` | `delete` | 0 | Delete / remove |
| `@drawable/ic_diagnostics` | `monitor_heart` | 0 | System health diagnostics |
| `@drawable/ic_directions_car` | `directions_car` | 0 | Vehicle / car |
| `@drawable/ic_download_log` | `download` | 0 | Download log file |
| `@drawable/ic_error` | `error` | 1 | Error / failure (filled) |
| `@drawable/ic_events` | `event` | 0 | Surveillance events list |
| `@drawable/ic_expand` | `expand_more` | 0 | Expand panel downward |
| `@drawable/ic_favorite` | `favorite` | 1 | Favourite / saved trip (filled) |
| `@drawable/ic_filter_list` | `tune` | 0 | Filter / sort controls |
| `@drawable/ic_fullscreen` | `fullscreen` | 0 | Enter full-screen |
| `@drawable/ic_fullscreen_exit` | `fullscreen_exit` | 0 | Exit full-screen |
| `@drawable/ic_kofi` | `local_cafe` | 0 | Support link (Ko-fi) |
| `@drawable/ic_language` | `language` | 0 | Language selection |
| `@drawable/ic_link` | `link` | 0 | External link / URL |
| `@drawable/ic_live` | `live_tv` | 0 | Live camera stream |
| `@drawable/ic_location` | `location_on` | 1 | GPS location pin (filled) |
| `@drawable/ic_mqtt` | `router` | 0 | MQTT / network routing |
| `@drawable/ic_notifications` | `notifications` | 0 | Push notifications |
| `@drawable/ic_play_circle` | `play_circle` | 1 | Play video (filled circle) |
| `@drawable/ic_recording` | `videocam` | 0 | Dashcam recording |
| `@drawable/ic_route` | `route` | 0 | Navigation route |
| `@drawable/ic_sentry` | `shield` | 0 | Sentry / surveillance mode |
| `@drawable/ic_services` | `memory` | 0 | System services / CPU |
| `@drawable/ic_settings` | `settings` | 0 | Settings screen |
| `@drawable/ic_share` | `share` | 0 | Share action |
| `@drawable/ic_signal_disconnected` | `cloud_off` | 0 | Server disconnected |
| `@drawable/ic_smart_toy` | `smart_toy` | 0 | AI / ML object detection |
| `@drawable/ic_star` | `star` | 1 | Star / rating (filled) |
| `@drawable/ic_traffic_monitor` | `traffic` | 0 | Traffic monitoring |
| `@drawable/ic_trips` | `timeline` | 0 | Trips and analytics |
| `@drawable/ic_update` | `system_update` | 0 | App update available |
| `@drawable/ic_vehicle_control` | `directions_car` | 0 | Vehicle control tab |
| `@drawable/ic_videocam_off` | `videocam_off` | 0 | Recording off / camera muted |
| `@drawable/ic_vpn_lock` | `vpn_lock` | 0 | Secure tunnel / VPN |
| `@drawable/ic_warning` | `warning` | 0 | Warning / caution |

### Custom / non-Material-Symbols drawables

These files live in `drawable/` but are **not** Material Symbols icons and must
**not** be restyled to the outlined symbol set:

| Resource ID | Purpose | Notes |
|-------------|---------|-------|
| `@drawable/ic_sidebar_logo` | BladeWatch brand logo (72dp) | Custom artwork — cyan camera + glow ring |
| `@drawable/ic_status_dot` | 10dp solid circle | Tinted at call-site to `status_success`, `status_warning`, or `status_danger` |
| `@drawable/ic_overlay_rec_active` | Recording-active overlay indicator | Hardcoded green `#22C55E` (≈ M3 status-success) |
| `@drawable/ic_overlay_rec_inactive` | Recording-inactive overlay indicator | Grey videocam body + red slash |
| `@drawable/ic_overlay_trip_active` | Trip-active overlay indicator | Hardcoded green `#22C55E` navigation arrow |
| `@drawable/ic_overlay_trip_inactive` | Trip-inactive overlay indicator | Grey arrow + red slash |
| `@drawable/ic_launcher_background` | Adaptive launcher icon background | Not a UI icon |
| `@drawable/ic_launcher_foreground` | Adaptive launcher icon foreground | Not a UI icon |

## Theming & token pipeline

### Light / dark

- **Flutter** — `BladeWatchTheme.light()` / `.dark()` build the two `ThemeData`
  objects from the Dart tokens; mode follows the app's own setting.
- **Android** — `Theme.BladeWatch.M3` extends
  `Theme.Material3.Light.NoActionBar`; the dark variant lives in `values-night/`.
  Mode is driven by `AppCompatDelegate.setDefaultNightMode` (which is why
  appcompat survives in the service host APK). Applies to the status overlay and
  `SetupGuideDialog` only.

### Token pipeline

- [color_tokens.dart](../packages/bladewatch_theme/lib/color_tokens.dart) is the
  **source of truth** for color roles.
  [colors_m3.xml](../app/src/main/res/values/colors_m3.xml) (+ `values-night`)
  mirrors it for the status overlay; `flutter_ui/test/theme/color_tokens_test.dart`
  parses the XML and fails if the two drift.

### Authoring rules

- Use **roles / tokens**, never raw hex or hard-coded `dp`.
- Flutter: reference `BladeWatchColors` / `BladeWatchType` / `BladeWatchDimens`
  or `Theme.of(context)`, never a literal `Color(0x…)` or a bare number.
- Android (overlay / setup dialog): inherit `Widget.BladeWatch.M3.*` /
  `TextAppearance.BladeWatch.*`; reference `?attr/color*` and `@dimen/*`.
- Keep both light and dark complete for any new role.

## HUD skin (in-car Flutter, and the companion)

The in-car UI wears a "cyberpunk HUD" look (epics BladeWatch-8w4p and BladeWatch-2llu, v1.4.1.0): near-black
panels in dark mode, white panels in light mode, cyan and magenta accents (with glow in dark), Space Mono,
uppercase tracked labels, thin bordered cards. It is the app's only theme: `main.dart` installs
`BwHud.themeData(...)` for both `theme` and `darkTheme`, every screen draws its own `HudTitleBar`, and the
shell has no toolbar. The Material 3 tokens (`BladeWatchTheme`) survive as the base the HUD theme is built on, and
for the status overlay's Android XML parity. The companion converted too (see "Companion" below).

**It is additive.** The M3 colour tokens in `packages/bladewatch_theme` are parity-tested against the Android
XML, so none of the HUD palette lives in them. The HUD has its own files in the same package (shared by the
in-car app and the companion; `flutter_ui/lib/theme/hud_theme.dart` re-exports them). The palette is defined
once in [hud_theme.dart](../packages/bladewatch_theme/lib/hud_theme.dart) as the `BwHud` theme extension
(`BwHud.dark`, `BwHud.light`), installed in `main.dart` for both `theme` and `darkTheme` as part of
`BwHud.themeData(...)`. Read it with `BwHud.of(context)`, which falls back to the const for the theme's
brightness when the extension is absent (tests that pump a bare `BladeWatchTheme`). Widgets never
hold a literal HUD colour and never branch on brightness: a difference between the modes is a token
(for example `glowCyan` is null in light and `labelWeight` is bold in light). It is NOT part of the
XML parity pipeline.

**Reference.** The owner's design is in `docs/design/hud-reference/` (`dashboard-dark.html`,
`dashboard-dark.png`, `dashboard-light.html`). Each token in `hud_theme.dart` names the Tailwind class
it came from; `flutter_ui/test/theme/hud_theme_test.dart` pins every value, retyped, so a changed hex
fails. Not built from the reference: its top status bar (clock, `SYS_ON`, theme toggle, connectivity
icons: no backing features), `.scanlines` (never applied) and `.cyber-grid` (covered by the page's
solid background).

**Typeface.** Space Mono (SIL OFL 1.1), bundled by `packages/bladewatch_theme`
(`assets/fonts/SpaceMono-{Regular,Bold}.ttf`, declared in that package's pubspec) and addressed as
`BwHud.fontFamily` (`packages/bladewatch_theme/SpaceMono`) from either app. It is bundled, not fetched, because the head
unit works offline. It covers Latin, Latin-Extended and Vietnamese only; other scripts (ja, ko, zh, th,
hi, ru) fall back to the platform font glyph by glyph. Its licence is the package asset `assets/fonts/OFL.txt`, shown
after the app's own licence under Settings > About > License. Only HUD subtrees use it; the app-wide
text theme is unchanged.

**Shared pieces** ([hud_widgets.dart](../packages/bladewatch_theme/lib/hud_widgets.dart)): `HudPanel` (bordered,
rounded, optionally gradient and shadowed surface) and `HudPulse` (Tailwind's `animate-pulse`: opacity
1, 0.5, 1 over 2 s). `HudPulse` stands still under `MediaQuery.disableAnimations`; a widget test that
pumps one and calls `pumpAndSettle` must set that flag, or the loop never settles.

### The HUD kit (BladeWatch-oxcx)

Most screens are built from stock Material widgets, so the HUD is delivered mainly as a **`ThemeData`**:
`BwHud.themeData(Brightness)` (cached) returns a complete theme for the mode, built on `BladeWatchTheme` so
`BwStatusColors` survives (re-mapped: success = the cyan dot, warning = the new amber `BwHud.warning`, danger =
magenta, info = accent). It is the app theme, so every route, dialog and sheet inherits it. `HudScope` applies
it to a subtree that does not run under it (a test, or a companion screen before it installs the theme), and
`showHudDialog` / `showHudSheet` are the same wrapper for a dialog or sheet (the sheet's own chrome belongs to the
modal route, so the helper passes it explicitly); in the in-car app they are now redundant but harmless. What the
theme cannot express is a small kit in
`hud_widgets.dart`.

| Piece | Spec |
|---|---|
| `ColorScheme` | primary = accent; primaryContainer/secondaryContainer = the soft accent fill (`viewAllFill` over `panel`); tertiary, error = magenta; errorContainer = magenta 15% over `panel`; surface = `pageBackground`; surfaceContainer/Low = `panel`; High/Highest = `panelPressed`; outline = `panelBorderStrong`, outlineVariant = `panelBorder` (both flattened over `panel`) |
| Text | Space Mono. display 30/36 bold, headlineMedium 24/32, headlineSmall and titleLarge 20/28 bold, titleMedium 16/24 bold, titleSmall 14/20 bold, body 16/24, 14/20, 12/16, labelLarge 12/16 bold .05em, labelMedium/Small 12/16 and 10/15 in `labelWeight`. Stock buttons keep the string's own case (Flutter has no text-transform): a screen upper-cases a label itself where the design is upper-case (chips, section labels, rail, tiles) |
| Card | `panel` fill, 4 dp radius, 1 dp `panelBorder`, no elevation, no margin. The 12 dp radius and gradient are `HudPanel` for a hero card |
| Dialog / bottom sheet | `panel`, 12 dp radius, `cardBorder`; the title is 20 dp bold accent with the glow in dark |
| Buttons | all 4 dp, 12 bold, 20x10 padding, min height 36 (the 48 dp touch target stays: Material pads it). Filled = accent text and border on the soft accent fill; outlined = `textSecondary` on `panel` with `chipBorder`; text = accent, no box; icon = `iconAccent`. Disabled = `panel`, 38% text |
| Switch | on: accent thumb, soft accent track, accent outline; off: `textSecondary` thumb, `panel` track, `panelBorder` outline |
| Checkbox / radio / slider / progress | accent when active; slider and progress tracks are `panelBorder` flattened |
| Text field / dropdown / menus | filled `panel`, 4 dp, `panelBorder`; focus = accent; error = magenta; 12 bold label (accent when floating) |
| Segmented / choice chip | selected: accent border on the soft accent fill; unselected: `panel` with `chipBorder`/`panelBorder` |
| List tile | `iconAccent` icon, 14 bold title, 12 `textSecondary` subtitle, selected = accent on the soft fill |
| Divider / tabs / tooltip / snackbar | `cardDivider` 1 dp; accent indicator on `cardDivider`; `panelPressed` box with `panelBorderStrong`; snackbar `panelPressed`, floating, `panelBorderStrong` |
| `HudTitleBar` | the page title (pulsing 8 dp magenta square, 20 dp accent, rule; optional trailing status and back arrow) |
| `HudSectionLabel` | 12 bold upper-case, .1em, accent; optional magenta icon and trailing |
| `HudChip` | the status chip; `live` = strong border, bright text, pulsing dot |
| `HudListRow` | a tappable 4 dp row, at least 48 dp tall; `selected` = accent border on the soft fill |
| `HudStatusDot` | four states, never collapsed: ok (cyan, glow), warning (amber), bad (magenta), idle (grey); `pulse` only for live things |
| `HudEmptyState` / `HudErrorState` / `HudLoading` | icon over an upper-case message; magenta for an error, with an optional retry; an accent spinner |

Tests: `flutter_ui/test/theme/hud_theme_data_test.dart` (every component reads its token) and
`flutter_ui/test/widgets/hud_kit_test.dart` (each kit widget, and a demo harness that renders one of every stock
control in both modes).

**Startup, dialogs and sheets (BladeWatch-2llu.1).** The startup screen: HUD page background, the brand lockup in
the accent, the three daemon rows in the hero `HudPanel` with `HudStatusDot`s that are the REAL state (ready = cyan,
waiting = grey: the check is binary process liveness, there is no "starting" to claim), upper-case header and status
labels, the continue and progress widgets themed. Every `showDialog` is `showHudDialog` and the language picker is
`showHudSheet` (redundant under the app-wide theme, kept as the kit's helpers). The setup guide's step badges are 4 dp boxes, not circles. `BwChoiceChip` is a
thin `ChoiceChip` wrapper that leaves the look to the chip theme (accent border on the soft fill) and drops the check
mark. The pairing QR keeps its white quiet zone in both modes (a QR must stay high-contrast). The brand lockup's
wordmark follows the theme's headline (Space Mono), so it no longer matches the native launch drawable exactly; the
handoff is a splash and the difference is accepted.

**Navigation rail** ([nav_rail.dart](../flutter_ui/lib/shell/nav_rail.dart)). The rail is shared shell, so
it wears the HUD skin on every screen. 80 dp wide (a 1 dp edge line inside it), items 4 dp from each
side, 4 dp-radius boxes: inactive is bare (18 dp icon, 10 dp label, slate); active has the top-to-bottom
gradient, a 1 dp accent border, a 20 dp icon and a bold `-0.5` tracked label, plus the cyan glow in dark.
Labels are the app's localized strings, uppercased (`RECORDINGS`, `DIAGNOSTICS`; the reference's
`RECORDS`/`DIAG` would be rewording), scaled down to fit rather than cut. The reference's 64 dp items with
16 dp gaps do not fit nine items in the head unit's 604 dp, so landscape (`compact`) is 52 dp items with
6 dp gaps (the globe/language button and nine items total about 570 dp; the 48 dp touch target holds);
portrait keeps 64 and 12. There is no divider before About (the reference has none). The language
button stays at the top of the rail: it is a real feature the reference has no slot for.

**No toolbar.** The shell is the rail plus the stage: no `_Toolbar`, no accent stripe, page background
`BwHud.pageBackground`, and the rail carries the language button in both orientations (it lived in the toolbar in
Android's portrait layout). A route with no screen mounted (a stub) is a bare placeholder on the same page. A new
screen draws its own `HudTitleBar` and needs nothing from the shell.

**The other screens (BladeWatch-2llu.2 to .5).** Each one opens with a `HudTitleBar` (the localized rail label,
upper-cased; a pushed sub-screen adds the back arrow), uses `HudSectionLabel` for its block headings, `HudLoading` /
`HudErrorState` / `HudEmptyState` for those three states, and otherwise relies on the HUD `ThemeData`: the stock
`Card` (4 dp, `panelBorder`, no margin: a screen that stacks cards spaces them itself), switches, sliders, dropdowns,
text fields, `ListTile`s, chips, tabs and dialogs already read as HUD. Only what the theme cannot express is coded by
hand. Buttons and choice chips keep the sentence case of their localized strings; only titles and section labels are
upper-cased.
- *Trips and Diagnostics*: the trip detail's end dot is magenta (the trip's end), its score bars are coloured by the
  real score band (>= 70 accent, >= 40 amber, else magenta); the health-tile dots map connecting/probing to amber and
  active to the accent, with unknown and offline kept distinct; the ADB console and Performance sub-screens have a HUD
  title bar with a back arrow instead of the M3 app bar.
- *Settings* ([settings_screen.dart](../flutter_ui/lib/screens/settings/settings_screen.dart)): the 264 dp sub-rail is
  one `HudListRow` per section (accent border on the soft fill when selected, a chevron only on the two drill-downs),
  and the pane opens with a `HudTitleBar` plus the section's one-line description. Group cards are the theme's `Card`;
  the Appearance theme and drive-side options are 4 dp tiles (accent border on the soft accent fill when selected; the
  theme preview swatches keep their literal light/dark previews, since they show what the theme looks like). The
  Services rows use a `HudStatusDot` that is real state (up = cyan, starting = amber, stopped = grey; the Pear peer
  row keeps its own coloured reachability lines), the destructive Reset block and the storage-format card use the
  magenta and its border, the Surveillance safe-zone map markers are accent (zone) and magenta (the car), and the
  Recording and Surveillance tab rows are ruled off the content like the Trips tab bar. The standalone Surveillance
  route (`showTitleBar: true`) draws its own title bar; inside the hub the pane title is the header.

**Dashboard** ([dashboard_screen.dart](../flutter_ui/lib/screens/dashboard/dashboard_screen.dart)). Five blocks
down a 24 dp-padded page, spread apart (`justify-between`) when the window is taller than they are and
scrolling when it is shorter. The natural height was about 590 dp, inside the head unit's 604 dp, until the
VEHICLE card (2026-10-04) added about 100: on the head unit the tile row now starts at about 628 dp and is
reached by scrolling (measured on the car).
- *Title bar*: an 8 dp magenta square in a `HudPulse`, `DASHBOARD // OVERVIEW` (the localized rail label plus
  `dashboard_hud_overview`, uppercased) at 20 dp bold, tracking 0.05em, cyan with a glow in dark; on the right
  `SECURE_LINK: ACTIVE` only while the Remote access tile is Online (`pear.enabled && running && reachable`),
  otherwise `SECURE_LINK: OFFLINE`. The reference's label is unconditional; a link that is not up is never claimed.
- *Summary card* (`HudPanel`, 12 dp radius, 24 padding, gradient left to right in dark, flat white in light): header
  `THIS WEEK TELEMETRY` (`dashboard_trips_this_week` + `dashboard_hud_telemetry`) with a magenta microchip icon, and
  the View all trips button (a 26 dp box; the 48 dp touch target is absorbed by trimming the card's top padding by 11
  and the header's bottom padding by 11, so the layout matches the reference). Three columns of `1fr`, 24 gap, a 1 dp
  rule after the first two, running through the stat rows. Row 1 values 30 dp (Trips and Distance glow cyan in dark; the
  Drive Time value glows magenta and its label is magenta), the cost row 24 dp, labels 12 dp; a distance draws its unit
  (after the last space) at 18 dp in the bright accent inside the SAME `Text.rich`, so the plain text stays `83.3 km`.
  The corner glows are radial gradients, not blurs.
- *Vehicle card* (2026-10-04): the same panel (`_HeroPanel`, shared with the summary card), headed `VEHICLE`
  (`dashboard_metric_vehicle`) with a magenta car icon and no button, so its paddings are the reference's 24 and 12
  untrimmed. One 24 dp row on the summary card's three columns, so the columns line up down the page: Battery, EV
  Range, and a third column holding Fuel and Fuel Range side by side, empty on a car with no tank.
- *Chips*: 4 dp boxes, 20x10 padding, 12 dp bold uppercase; not tappable. The recording chip has a pulsing dot only while
  recording. Pair a device is the same box in magenta (its label is the localized `pairing_title`, uppercased, so it
  reads `PAIR A DEVICE`, not the reference's `PAIR DEVICE`).
- *Tiles*: five across (16 gap) from 1100 dp of width, otherwise two to a row; 112 dp tall, 4 dp radius, 16 padding.
  Values 20 dp bold (the vehicle model 12 dp, keeping its own casing: `DM-i`), labels 10 dp. Live is magenta (with a glow in
  dark), Remote access glows cyan in dark and is cyan-700 in light. The recordings tile's dot and the remote tile's status
  dot are real state, not decoration. The recordings string `● N` has its bullet replaced by the glowing dot.
- *Light vs dark* is tokens only: no glow, flat card, bold labels, magenta Drive Time and LIVE, slate labels.
- Tests: `flutter_ui/test/screens/dashboard/dashboard_screen_test.dart` ("HUD skin" group). Widget tests draw shadows without
  blur (`debugDisableShadows`), so glows are checked as tokens, and on the device.

### Companion (BladeWatch-0glp)

The companion (phones and desktops, `companion/`) wears the same HUD. Its kit is the in-car one: the tokens,
`BwHud.themeData`, `HudPanel`, `HudTitleBar` and the rest live in `packages/bladewatch_theme` (the in-car app
re-exports them), and Space Mono is declared by that package, so a `TextStyle` with `BwHud.fontFamily`
(`packages/bladewatch_theme/SpaceMono`) renders in both apps. `CompanionApp` installs
`BwHud.themeData(Brightness.light / dark)` as `theme` and `darkTheme`, and its screen tests pump the same theme
(`test/support.dart`). The typeface's SIL OFL notice is registered with Flutter's `LicenseRegistry`
(`companion/lib/font_licence.dart`), so it is listed on Settings > About > Licenses next to the packages' own.

**Shell (BladeWatch-0glp.2).** No app bar: `HomeShell` draws the screen's name as a `HudTitleBar` (upper-cased,
lined up with the page below it and capped at the same 960 dp) over the page. Wide (>= 700 dp): a permanent 240 dp side
panel on `railBackground` with the `BladeWatch` wordmark as a header that never scrolls and every place as a
`HudNavItem` (`horizontal`, 48 dp, the in-car rail's active box: gradient, accent border, glow in dark). Phone: a bottom
bar of four places and "More", each a vertical `HudNavItem`; every label shows, upper-case, at ONE size for the whole
bar: the largest at which the longest label fits its fifth of the width (`labelScaler`, 2026-10-04: scaled one by one,
RECORDINGS sat smaller than its neighbours; the old Material bar hard-wrapped a long one mid-word), and the text scale
is capped at 1.3. The Events item carries the unseen-alert count as a badge. "More" is a
`showHudSheet` of `HudListRow`s. `HudNavItem` is the kit's version of the in-car rail item, which now uses it too.

The connection page (`CarPage`) is one `HudPanel` per state with a `HudStatusDot` that is the REAL state of the link:
amber while it is still looking or the car is not answering (both clear by themselves), magenta when it needs the owner
(unreachable, refused); a spinner while busy, a magenta icon otherwise. `LoadError` is the kit's `HudErrorState`. Pairing
is a `HudTitleBar` (the pulsing magenta square is "pairing", HUD rule 4) over one hero panel holding the form; the QR
scan page keeps the camera preview untouched inside an accent-bordered `HudPanel` frame, under a title bar with the way back.

**Shared building blocks (BladeWatch-0glp.3).** `Section` is the HUD theme's own card (4 dp, bordered, 16 dp padding)
under an upper-case accent title (the action drops below it when both do not fit); `InfoRow` is a 12 dp label over a
14 dp bold value, and at a large text size (over about 1.4x) it stacks label over value instead of breaking a word;
`LoaderView` shows `HudLoading`. Every screen built from these is on the HUD without edits.

**Figures (`StatGrid`, `ScoreBars`, 2026-10-04 design review).** A group of figures is sized together, never one by
one: every value in a grid takes the largest size at which the longest fits its column on one line, and every label
one size too, wrapping between words before it shrinks (only a word too long for its column shrinks them). Columns
are 16 dp apart. Score bars give label and bar half the row each, with all labels at one size. Shrinking each text on
its own had put "₱0.00" beside a smaller "₱49.96", one tiny label among full-size ones, and clipped "Electric Cost".

**Dashboard, Events, Alerts.** The Dashboard's chips are 4 dp boxes with a `HudStatusDot` that is real state: the
route is cyan, the services amber when partial, the recording dot magenta and pulsing only while the car records
(grey and still when idle), ACC and safe zone cyan when true. Vehicle comes first: Battery and Range (Electric range
on a car with a tank), then Fuel and Fuel range, as value-over-label rows two across without a glow, then Charging,
health and 12 V as plain rows. This week follows: Trips and Distance cyan, Drive time magenta, then the costs as a
plain value-over-label row, each value scaled down before it wraps (2026-10-04; there is no SOC or total Range row).
Events' alerts are `HudListRow`s (severity icon in the status colours, the play icon on a clip alert); a row that has
arrived since the list was last seen is the accent-bordered one, and an empty inbox is a `HudEmptyState`. The alert
settings are `Section`s with the theme's switches.

**Live and Recordings (BladeWatch-0glp.4).** The picture is untouched (a black letterbox is the one literal colour on
the page, as on the head unit) inside a 4 dp `panelBorder` frame (`HudPanel`); the GPS chip over it stays dark and
translucent in both modes, with the HUD's 4 dp corners and border. Single choices (camera, type, day) are the chip theme's
accent-border look with no check mark; the who/severity filters are multi-select, so their check mark stays. A clip is a
`HudListRow` (thumbnail in a 4 dp frame, when, kind, length, size, what was seen): a ticked clip is the accent-bordered
row, and delete is magenta (`destructiveStyle` for a button, the magenta icon for a row action). The player has a
`HudTitleBar` with the way back (title = when it was taken, the download as its action), the video in a black frame, the
progress bar in the accent on `panelBorder`, timecodes in Space Mono, and the detection strip in HUD colours (person
magenta, vehicle cyan, bike amber, anything else grey). The page gutter (24 dp) sits outside `ContentWidth`, so list rows
are exactly the content width and line up with the title bar.

**Vehicle, Location, Trips (BladeWatch-0glp.5).** Vehicle is `Section`s with the theme's switches and buttons, window
presets as single choices (no check mark), and a tyre row led by a `HudStatusDot` that is what the car reports (cyan when
it reports no leak, magenta when it does); every window command still asks first. `CarMap` is the accent route and
magenta markers in a 4 dp `panelBorder` frame (the night inversion of the tiles is unchanged); Location is that map with
the recenter button over it and the position as a `HudListRow` with the copy action. Trips: the tabs and day filter sit
on the page gutter, the period summary is a `Section`, each trip a `HudListRow` with a score badge in its real band
(70 and up the accent, 40 and up amber, below that magenta, as in the car); the trip detail has a `HudTitleBar` with the
way back and a magenta delete, its confirm is `destructiveStyle`, and the map is the framed `CarMap`. The settings form is
the theme's fields, dropdown and switch in `Section`s, distance unit and storage place as single choices; the
currency-symbol picker is unchanged.

**Surveillance, Performance, Diagnostics, About, Settings (BladeWatch-0glp.6).** All `Section`s over the shared rows,
so they were on the HUD already; what was restyled by hand: Surveillance's zone delete is magenta (its 4 dp framed
camera snapshots were removed in 1.4.1.2, repeating Live); Diagnostics carries a `HudStatusDot` on the rows that are a state (LAN access and the camera
pipeline cyan when on and a grey dot when off, the SD card that failed to mount magenta) and the SOH reset confirm is
magenta; Settings' recording mode is a column of `HudListRow`s, the car's configured mode the accent-bordered one, the
trip-costs entry is a row, the Trips costs form opens under a `HudTitleBar` with the way back, and every destructive
confirm (unpair, cleanup, format the SD card, twice) is `destructiveStyle`. About lists the Space Mono OFL notice with the
other licences (registered with Flutter's `LicenseRegistry`, see above). Single choices everywhere are the chip theme's
accent-border look with no check mark; multi-select filters (the overlay fields, who/severity) keep theirs.

**What is left.** Every companion screen is on the HUD, and it has been run on the real engine three ways, each with a
fake car (so nothing touched the real one): macOS (dark and light, desktop and phone size, 2.0x text, ja, th, ru), a
real Android 13 phone at 360 dp (all 13 pages dark and light, pairing, the QR scan page with the camera, the licences
page with the Space Mono OFL entry, ja, th, hi, ru, tr), and, for the in-car app, the head unit itself. What those runs
found was fixed: the map's attribution ran off a phone's edge, stacked form fields touched, Live and Location's title
bar did not line up with their full-width frame, Recordings' type chips scrolled sideways (they wrap now), and on the
head unit the Vehicle and Trips content ran off the 24 dp gutter and some controls were still solid Material fills.
Still open: an iOS run, a real car's data on the companion (video, the live picture), Turkish capitalisation
(Dart's `toUpperCase` is not locale-aware, so "Diğer" reads DIĞER, not DİĞER), and the independent review
(BladeWatch-0glp.7). The desktop label/value rows still put the value at the card's half.

**On a TV (BladeWatch 1.4.1.2)** the remote moves focus, and the HUD's own controls showed it barely or not
at all, so `TvFocusRing` (`companion/lib/tv.dart`) draws one ring around whatever control has focus: the
accent, a 3 dp stroke over a soft 8 dp glow, 10 dp corners, 3 dp outside the control. It is the only
focus indicator; nothing per widget. Whole-screen nodes (pages, scopes) get none. Up and down stay in their
column -- the side panel and the page are each a `TvPane` -- and scroll a page to its text before leaving it
(from a title bar's button with nothing focusable below, as on a trip's summary, they scroll the page under it);
rows that open nothing (most of Events' alerts) still take focus on a TV (`tvReadable`) so the remote can walk
the list; per-clip delete buttons are hidden on a TV so the remote lands on the clips; the map takes no focus on
a TV (`CarMap`), since flutter_map pans on the arrow keys and focus could never leave it; and a slider on a TV
is in directional navigation (`tvSlider`): left and right change it, up and down move on.

## Source References

- Flutter theme (source of truth):
  [bladewatch_theme.dart](../packages/bladewatch_theme/lib/bladewatch_theme.dart),
  [color_tokens.dart](../packages/bladewatch_theme/lib/color_tokens.dart),
  [type_tokens.dart](../packages/bladewatch_theme/lib/type_tokens.dart),
  [dimens_tokens.dart](../packages/bladewatch_theme/lib/dimens_tokens.dart).
- Dart ↔ XML parity gates: [flutter_ui/test/theme/](../flutter_ui/test/theme/).
- M3 theme parent, color roles, and component widgets (overlay / setup dialog):
  [themes_bladewatch.xml:15](../app/src/main/res/values/themes_bladewatch.xml#L15)
  (theme parent),
  [themes_bladewatch.xml:95](../app/src/main/res/values/themes_bladewatch.xml#L95)
  (type-scale wiring),
  [themes_bladewatch.xml:177](../app/src/main/res/values/themes_bladewatch.xml#L177)
  (navigation rail),
  [themes_bladewatch.xml:194](../app/src/main/res/values/themes_bladewatch.xml#L194)
  (segmented buttons),
  [themes_bladewatch.xml:205](../app/src/main/res/values/themes_bladewatch.xml#L205)
  (dialog overlay),
  [themes_bladewatch.xml:315](../app/src/main/res/values/themes_bladewatch.xml#L315)
  (M3 Expressive type styles).
- Shape appearances:
  [themes.xml:10](../app/src/main/res/values/themes.xml#L10).
- Color roles (light / dark):
  [colors_m3.xml](../app/src/main/res/values/colors_m3.xml),
  [values-night/colors_m3.xml](../app/src/main/res/values-night/colors_m3.xml).
- Shape and spacing dimens:
  [dimens_bladewatch.xml:19](../app/src/main/res/values/dimens_bladewatch.xml#L19).
- App-shell identity (accent stripe, app bar, nav affordance):
  [flutter_ui/lib/shell/app_shell.dart](../flutter_ui/lib/shell/app_shell.dart).
- Material Components version: [libs.versions.toml:9](../gradle/libs.versions.toml#L9).
