import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'vehicle_controller.dart';
import 'vehicle_hero.dart';
import 'vehicle_models.dart';
import '../../widgets/bw_choice_chip.dart';

/// Shows why a vehicle command failed.
///
/// The daemon can refuse WITHOUT a reason: it answers 200 with success:false and
/// an empty message. Three call sites handled that three different ways. The
/// appearance writes returned null and showed NOTHING — the colour swatch simply
/// snapped back with no explanation, which reads as a broken tap. The
/// climate/window ones showed a snackbar with empty text. And the same
/// two-line snackbar was hand-copied eight times.
///
/// `vehicle_action_failed` was ported from Android for precisely this case and
/// had never been wired to anything.
void showVehicleCommandError(BuildContext context, String message) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message.isEmpty ? l10n.vehicle_action_failed : message)),
  );
}


/// Ground truth: `VehicleController.kt` (root layout/status/appearance/
/// polling), `VehiclePanels.kt` (Climate/Windows; seats removed, BladeWatch-7bx4), `TyreOverlay.kt`
/// (the tyre cards — plain styled widgets in native too, not a Canvas
/// painter; see `VehicleHeroView.kt` for the 3D hero, wrapped here by
/// [VehicleHero]).
///
/// [heroBuilder] exists solely as a test seam: the real 3D hero
/// ([VehicleHero]) wraps a `webview_flutter` `WebViewController`, which
/// throws if constructed with no platform implementation registered — true
/// in every `flutter test` run (no real WebView plugin is registered
/// outside a real app/device). Production code never passes this; tests
/// substitute a plain placeholder so the rest of the screen (status,
/// appearance, tabs, tyre cards, actions) is fully widget-testable without
/// ever constructing a real WebView. Matches `DiagnosticsScreen`'s injected
/// controller-factory pattern.
class VehicleScreen extends StatefulWidget {
  final VehicleController controller;
  final Widget Function(BuildContext context, VehicleController controller)? heroBuilder;

  const VehicleScreen({super.key, required this.controller, this.heroBuilder});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  VehicleTab _tab = VehicleTab.climate;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
    widget.controller.loadAppearance();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => widget.controller.poll());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    if (c.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hero = (widget.heroBuilder ?? (ctx, ctrl) => VehicleHero(controller: ctrl))(context, c);

    final heroPane = _HeroPane(l10n: l10n, theme: theme, controller: c, hero: hero);
    final controls = _ControlsPanel(
      l10n: l10n,
      theme: theme,
      controller: c,
      tab: _tab,
      onTabSelected: (t) => setState(() => _tab = t),
    );

    // BladeWatch-vuul: the head unit ROTATES. Landscape lays out in ~1280x553dp of screen
    // body (1280x720dp display, less the system bars and the app toolbar — measured, see
    // docs/ui-ux-design-language.md); portrait is the transpose.
    // (docs/ui-ux-design-language.md, "Target device"). This screen was built for portrait and
    // silently broke in landscape: the controls panel wanted roughly 44 (appearance bar)
    // + 48 (tab chips) + 360 (a fixed maxHeight) = ~452dp of the ~553dp available, leaving
    // ~100dp for tyre cards that need 252dp, and because
    // it was a Stack sibling of a Positioned.fill hero and four Positioned tyre cards, nothing
    // shared a constraint. The panel simply covered the car and sliced the tyre cards through
    // the middle of their kPa line.
    //
    // Two orientations, two arrangements, and in BOTH the hero and the controls are laid out
    // with real constraints rather than absolute offsets, so neither can eat the other.
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth >= _wideLayoutMinWidth
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 55, child: heroPane),
                Expanded(flex: 45, child: controls),
              ],
            )
          : Column(
              children: [
                Expanded(child: heroPane),
                // ConstrainedBox, NOT Flexible. Flexible here is a trap: it and the
                // Expanded above are both flex children with flex 1, so RenderFlex splits
                // the height 50/50 — the hero is capped at half the screen, the controls
                // take only their content, and the slack becomes dead space at the bottom.
                // Measured at 720x1280: hero 640, controls 200, 440px of nothing below it.
                //
                // A non-flex child is measured first and the single remaining flex child
                // gets everything left, so the car takes all the room the controls do not.
                // The bound is still needed: _ControlsPanel shrink-wraps around a Flexible
                // scroll area, which cannot resolve against an unbounded height.
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: box.maxHeight * _portraitControlsMaxFraction),
                  child: controls,
                ),
              ],
            ),
    );
  }
}

/// Most of a portrait screen the controls may occupy; the car gets the rest. Only a cap —
/// the panel shrink-wraps its content and scrolls beyond this, it does not stretch to it.
///
/// Canonical value: see "Responsive breakpoints" in docs/ui-ux-design-language.md.
const double _portraitControlsMaxFraction = 0.55;

/// Above this width the screen splits into two columns. Sits between the head unit's two
/// orientations — 720dp portrait, 1280dp landscape (density 240, so dpr 1.5) — so in practice
/// it is an orientation switch, expressed as a width so it degrades sensibly at any other size.
///
/// Canonical value: see "Responsive breakpoints" in docs/ui-ux-design-language.md.
const double _wideLayoutMinWidth = 700;

// ─────────────────────────── Hero pane ────────────────────────────────────

/// The car and everything describing the car itself: the 3D model, the four tyre pressures,
/// lock state, charge/fuel and the colour picker.
///
/// The tyre cards anchor to this pane's four CORNERS. That is both why they can no longer be
/// clipped and a better map of the physical car than the previous `Positioned(top: 60 …)` /
/// `Positioned(top: 156 …)` offsets: left column the right-hand wheels, right column the
/// left-hand wheels, top row rear, bottom row front — the same arrangement those offsets
/// produced, now stated as intent instead of arithmetic.
class _HeroPane extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;
  final Widget hero;

  const _HeroPane({required this.l10n, required this.theme, required this.controller, required this.hero});

  @override
  Widget build(BuildContext context) {
    final tyres = controller.state.tyres;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: hero),
              // Lock pill top-centre, in the gap between the two tyre columns.
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _LockPill(l10n: l10n, theme: theme, controller: controller),
                ),
              ),
              _corner(Alignment.topLeft, _TyreCard(label: 'RR', tyre: tyres.rr, theme: theme)),
              _corner(Alignment.bottomLeft, _TyreCard(label: 'FR', tyre: tyres.fr, theme: theme)),
              _corner(Alignment.topRight, _TyreCard(label: 'RL', tyre: tyres.rl, theme: theme)),
              _corner(Alignment.bottomRight, _TyreCard(label: 'FL', tyre: tyres.fl, theme: theme)),
            ],
          ),
        ),
        if (controller.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(l10n.vehicle_data_unavailable, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
        _ChargeCard(l10n: l10n, theme: theme, controller: controller),
        _AppearanceBar(l10n: l10n, theme: theme, controller: controller),
      ],
    );
  }

  Widget _corner(Alignment alignment, Widget card) => Align(
        alignment: alignment,
        child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 96, child: card)),
      );
}

// ─────────────────────────── Status card ─────────────────────────────────

/// Lock state only. This was `_StatusCard`, which also carried the charge/fuel readout as a
/// translucent pill floating over the middle of the car — it overlapped the model, and being
/// translucent it let the 3D render show through its own numbers. Charge and fuel now live in
/// [_ChargeCard], below the car, where they are simply readable.
class _LockPill extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _LockPill({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final (dotColor, lockLabel) = switch (controller.state.doors.overall) {
      1 => (theme.colorScheme.primary, l10n.vehicle_locked),
      2 => (theme.colorScheme.error, l10n.vehicle_unlocked),
      _ => (Colors.grey, '\u2014'),
    };
    return _GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(key: const ValueKey('vehicle.status.lockDot'), width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(lockLabel, key: const ValueKey('vehicle.status.lockText')),
        ],
      ),
    );
  }
}

// ─────────────────────────── Charge / fuel ────────────────────────────────

/// Charge, range and — on a PHEV — fuel and fuel range, as a solid card under the car rather
/// than a translucent pill on top of it. Laid out as a wrapping row of value/label pairs so it
/// stays one line in the landscape hero column and reflows rather than clipping when narrow.
class _ChargeCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _ChargeCard({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final battery = controller.state.battery;
    final known = battery.soc > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 20,
          runSpacing: 8,
          children: [
            _stat(
              known ? l10n.vehicle_status_charge_fmt(battery.soc) : l10n.vehicle_status_charge_unknown,
              known ? l10n.vehicle_status_range_fmt(battery.rangeKm) : l10n.vehicle_status_range_unknown,
              const ValueKey('vehicle.status.charge'),
              const ValueKey('vehicle.status.range'),
            ),
            // PHEV only. A BEV never reports these, so the pair simply does not exist there
            // rather than reading "Fuel: 0%" on a car with no tank.
            if (battery.hasFuel)
              _stat(
                l10n.vehicle_status_fuel_fmt(battery.fuelPercent),
                l10n.vehicle_status_fuel_range_fmt(battery.fuelRangeKm),
                const ValueKey('vehicle.status.fuel'),
                const ValueKey('vehicle.status.fuelRange'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String sub, Key valueKey, Key subKey) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, key: valueKey, style: theme.textTheme.titleMedium),
          Text(sub, key: subKey, style: theme.textTheme.bodySmall),
        ],
      );
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

// ─────────────────────────── Tyre card ────────────────────────────────────

class _TyreCard extends StatelessWidget {
  final String label;
  final TyreInfo tyre;
  final ThemeData theme;

  const _TyreCard({required this.label, required this.tyre, required this.theme});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tier = tyreTier(tyre);
    final dotColor = switch (tier) {
      TyreTier.muted => Colors.grey,
      TyreTier.alert => theme.colorScheme.error,
      TyreTier.warn => Colors.amber,
      TyreTier.caution => Colors.amber,
      TyreTier.normal => theme.colorScheme.primary,
    };
    final stateText = switch (tier) {
      TyreTier.muted => l10n.vehicle_tyre_no_signal,
      TyreTier.alert => switch (tyre.airLeakState) {
          >= 2 => l10n.vehicle_tyre_fast_leak,
          1 => l10n.vehicle_tyre_slow_leak,
          _ => l10n.vehicle_tyre_low,
        },
      TyreTier.warn => l10n.vehicle_tyre_check_pressure,
      TyreTier.caution => (tyre.psi != null && tyre.psi! > 45) ? l10n.vehicle_tyre_high : l10n.vehicle_tyre_low,
      TyreTier.normal => l10n.vehicle_tyre_ok,
    };
    return Container(
      key: ValueKey('vehicle.tyre.$label'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
          Text(tyre.psi != null ? '${tyre.psi!.toStringAsFixed(1)} PSI' : '—', style: theme.textTheme.titleSmall),
          Text(tyre.kPa != null ? '${tyre.kPa} kPa' : '— kPa', style: theme.textTheme.labelSmall),
          if (tyre.temperatureC != null) Text('${tyre.temperatureC}°C', style: theme.textTheme.labelSmall),
          Text(stateText, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ─────────────────────────── Bottom panel ─────────────────────────────────

class _ControlsPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;
  final VehicleTab tab;
  final void Function(VehicleTab) onTabSelected;

  const _ControlsPanel({required this.l10n, required this.theme, required this.controller, required this.tab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final availableTabs = [
      VehicleTab.climate,
      VehicleTab.windows,
    ];
    final effectiveTab = availableTabs.contains(tab) ? tab : VehicleTab.climate;

    return Container(
      decoration: BoxDecoration(
        // BladeWatch-9c7d: OPAQUE, not alpha 0.92. This panel sits in a Stack over
        // the 3D hero and the four tyre cards, which are Positioned at fixed
        // offsets. At 0.92 the high-contrast text behind it read straight through —
        // "242 kPa" and "OK" were legible under the tab chips and the window rows,
        // which looks like a rendering fault rather than a design. The rounded top
        // corners already carry the bottom-sheet-over-content idea without the
        // bleed-through.
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The appearance bar (colour swatches + model name) moved into _HeroPane: it
          // describes the car, not the controls (BladeWatch-vuul).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (final t in availableTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: BwChoiceChip(
                      key: ValueKey('vehicle.tab.${t.name}'),
                      label: Text(_tabLabel(l10n, t)),
                      selected: t == effectiveTab,
                      onSelected: (_) => onTabSelected(t),
                    ),
                  ),
              ],
            ),
          ),
          // Flexible, NOT a fixed maxHeight: 360. That constant was the direct cause of
          // BladeWatch-vuul — 360 plus the tab chips plus the appearance bar came to ~452dp,
          // more than a landscape head unit's ~553dp of screen body leaves, so the panel grew over the car and
          // clipped the tyre cards. Taking whatever room the parent gives and scrolling inside
          // it means the tab content can never push past its own pane again.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: switch (effectiveTab) {
                VehicleTab.climate => _ClimateTab(l10n: l10n, theme: theme, controller: controller),
                VehicleTab.windows => _WindowsTab(l10n: l10n, theme: theme, controller: controller),
              },
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(AppLocalizations l10n, VehicleTab t) => switch (t) {
        VehicleTab.climate => l10n.vehicle_tab_climate,
        VehicleTab.windows => l10n.vehicle_tab_windows,
      };
}

// ─────────────────────────── Appearance bar ───────────────────────────────

class _AppearanceBar extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _AppearanceBar({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final entry = controller.selectedModelEntry;
    final modelLabel = entry?.name ?? 'BYD Seal 5 DM-i Dynamic';
    final canPickModel = controller.manifestModels.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          for (final hex in kColorPresetHexes)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                key: ValueKey('vehicle.color.$hex'),
                onTap: () async {
                  final error = await controller.selectColor(hex);
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                    border: Border.all(color: hex == controller.selectedColor ? theme.colorScheme.primary : Colors.transparent, width: 2),
                  ),
                ),
              ),
            ),
          GestureDetector(
            key: const ValueKey('vehicle.color.custom'),
            onTap: () => _showCustomColorPicker(context),
            child: CircleAvatar(radius: 14, backgroundColor: theme.colorScheme.surfaceContainerHighest, child: const Text('+')),
          ),
          const Spacer(),
          // Flexible + ellipsis, not a bare Text. The swatches are fixed-width, so the model
          // name is the only thing that can absorb a narrow pane — and in the landscape
          // two-column layout this bar lives in the ~528dp hero column rather than the full
          // 1280dp, where an unbounded label overflowed the Row.
          Flexible(
            child: GestureDetector(
              key: const ValueKey('vehicle.model.name'),
              onTap: canPickModel ? () => _showModelPicker(context) : null,
              child: Text(
                modelLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.labelMedium?.copyWith(color: canPickModel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showModelPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vehicle_appearance_model_title),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: controller.selectedModelId,
            onChanged: (id) {
              Navigator.of(dialogContext).pop();
              if (id != null) {
                // The outer context, not dialogContext — that one is gone.
                controller.selectModel(id).then((error) {
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                });
              }
            },
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final m in controller.manifestModels)
                  RadioListTile<String>(
                    key: ValueKey('vehicle.model.picker.${m.id}'),
                    value: m.id,
                    title: Text(m.name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomColorPicker(BuildContext context) {
    final initial = _parseHex(controller.selectedColor);
    var r = initial.$1, g = initial.$2, b = initial.$3;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.vehicle_appearance_custom_color),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Color.fromARGB(255, r, g, b))),
              _rgbSlider('R', r, (v) => setDialogState(() => r = v)),
              _rgbSlider('G', g, (v) => setDialogState(() => g = v)),
              _rgbSlider('B', b, (v) => setDialogState(() => b = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
            TextButton(
              key: const ValueKey('vehicle.color.custom.apply'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                controller.selectColor(hex).then((error) {
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                });
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rgbSlider(String label, int value, ValueChanged<int> onChanged) => Row(
        children: [
          SizedBox(width: 16, child: Text(label)),
          Expanded(child: Slider(value: value.toDouble(), min: 0, max: 255, onChanged: (v) => onChanged(v.round()))),
        ],
      );

  (int, int, int) _parseHex(String hex) {
    try {
      final v = int.parse(hex.substring(1), radix: 16);
      return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
    } catch (_) {
      return (255, 255, 255);
    }
  }
}

// ─────────────────────────── Climate tab ──────────────────────────────────

/// Minimum width at which the climate tab puts two controls on one row. See `_ClimateTab._pair`,
/// and "Responsive breakpoints" in docs/ui-ux-design-language.md for the canonical value.
const double _twoUpMinWidth = 500;

class _ClimateTab extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _ClimateTab({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _build(context, box.maxWidth >= _twoUpMinWidth));

  Widget _build(BuildContext context, bool twoUp) {
    final c = controller;
    final outsideTemp = c.state.climate.outsideTempC;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outsideTemp != null) ...[
          Text(l10n.vehicle_outside_temp_fmt(outsideTemp.toStringAsFixed(1)), style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
        ],
        _pair(
          twoUp,
            FilledButton(
              key: const ValueKey('vehicle.climate.ac'),
              style: FilledButton.styleFrom(backgroundColor: c.acOn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest),
              onPressed: () async {
                final error = await c.toggleAc();
                if (context.mounted && error != null) showVehicleCommandError(context, error);
              },
              child: Text(c.acOn ? l10n.vehicle_ac_on : l10n.vehicle_ac_off),
            ),
            FilledButton(
              key: const ValueKey('vehicle.climate.maxCooling'),
              style: FilledButton.styleFrom(backgroundColor: c.maxCooling ? theme.colorScheme.error : theme.colorScheme.surfaceContainerHighest),
              onPressed: () async {
                final error = await c.toggleMaxCooling();
                if (context.mounted && error != null) showVehicleCommandError(context, error);
              },
              child: Text(c.maxCooling ? l10n.vehicle_max_cooling_on : l10n.vehicle_max_cooling_off),
            ),
        ),
        const SizedBox(height: 8),
        _pair(
          twoUp,
          _stepper(context, l10n.vehicle_temp_label, '${c.setpointC}°C', 'vehicle.climate.temp', c.decTemp, c.incTemp),
          _stepper(context, l10n.vehicle_fan_speed_label, l10n.vehicle_fan_level(c.fanLevel), 'vehicle.climate.fan', c.decFan, c.incFan),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('vehicle.screen.toggle'),
          style: FilledButton.styleFrom(backgroundColor: c.screenOn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest),
          onPressed: () async {
            final error = await c.toggleScreen();
            if (context.mounted && error != null) showVehicleCommandError(context, error);
          },
          child: Text(c.screenOn ? l10n.vehicle_screen_on : l10n.vehicle_screen_off),
        ),
        const SizedBox(height: 8),
        _pair(
          twoUp,
          _stepper(context, l10n.vehicle_media_volume_label, '${c.mediaVolumePercent}%',
              'vehicle.media.volume', c.stepVolumeDown, c.stepVolumeUp),
          FilledButton(
            key: const ValueKey('vehicle.media.mute'),
            style: FilledButton.styleFrom(
                backgroundColor: c.mediaMuted ? theme.colorScheme.error : theme.colorScheme.surfaceContainerHighest),
            onPressed: () async {
              final error = await c.toggleMute();
              if (context.mounted && error != null) showVehicleCommandError(context, error);
            },
            child: Text(c.mediaMuted ? l10n.vehicle_media_muted : l10n.vehicle_media_mute),
          ),
        ),
        const SizedBox(height: 8),
        _pair(
          twoUp,
            FilledButton(
              key: const ValueKey('vehicle.climate.frontDefrost'),
              style: FilledButton.styleFrom(
                  backgroundColor: c.frontDefrostOn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest),
              onPressed: () async {
                final error = await c.toggleFrontDefrost();
                if (context.mounted && error != null) showVehicleCommandError(context, error);
              },
              child: Text(l10n.vehicle_front_defrost),
            ),
            FilledButton(
              key: const ValueKey('vehicle.climate.rearDefrost'),
              style: FilledButton.styleFrom(
                  backgroundColor: c.rearDefrostOn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest),
              onPressed: () async {
                final error = await c.toggleRearDefrost();
                if (context.mounted && error != null) showVehicleCommandError(context, error);
              },
              child: Text(l10n.vehicle_rear_defrost),
            ),
        ),
      ],
    );
  }


  /// Climate stepper. The callbacks return an error message (null on success) so
  /// Two controls side by side when there is room, stacked when there is not.
  ///
  /// A stepper's minus/value/plus cluster is rigid — two 48dp icon buttons plus the value —
  /// so only its label can absorb a squeeze, and below some width the pair overflows however
  /// the label is constrained. The landscape controls column is ~432dp at the 960dp width the
  /// tests pump (45% of it), where
  /// the temperature and fan steppers overflowed by 16px.
  Widget _pair(bool twoUp, Widget a, Widget b) => twoUp
      ? Row(children: [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)])
      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 8), b]);

  /// a refused command can be SHOWN — they used to be bare VoidCallbacks, which
  /// is why a refusal was silent and the optimistic value stayed on screen.
  Widget _stepper(
    BuildContext context,
    String label,
    String value,
    String keyPrefix,
    Future<String?> Function() onMinus,
    Future<String?> Function() onPlus,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            IconButton(
                key: ValueKey('$keyPrefix.minus'),
                tooltip: l10n.cd_decrease,
                icon: const Icon(Icons.remove_circle),
                onPressed: () async {
                  final error = await onMinus();
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                }),
            Text(value),
            IconButton(
                key: ValueKey('$keyPrefix.plus'),
                tooltip: l10n.cd_increase,
                icon: const Icon(Icons.add_circle),
                onPressed: () async {
                  final error = await onPlus();
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                }),
          ],
        ),
      );
}

// ─────────────────────────── Windows tab ──────────────────────────────────

class _WindowsTab extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _WindowsTab({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final w = c.state.windows;
    final caps = c.state.capabilities.windows;
    final isVented = [w.lf, w.rf, w.lr, w.rr].where((v) => v != -1).let((vals) => vals.isNotEmpty && vals.every((v) => v >= 1 && v <= 20));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _windowCell(context, l10n.vehicle_window_front_left, 1, w.lf)),
            const SizedBox(width: 8),
            Expanded(child: _windowCell(context, l10n.vehicle_window_front_right, 2, w.rf)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _windowCell(context, l10n.vehicle_window_rear_left, 3, w.lr)),
            const SizedBox(width: 8),
            Expanded(child: _windowCell(context, l10n.vehicle_window_rear_right, 4, w.rr)),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.vehicle_all_windows, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            _actionChip(context, l10n.vehicle_window_close, 'vehicle.window.closeAll', () => c.closeAllWindows()),
            const SizedBox(width: 6),
            _actionChip(context, isVented ? l10n.vehicle_window_close_vent : l10n.vehicle_window_vent_12, 'vehicle.window.vent',
                () => c.ventAllWindows(isVented ? 0 : 12)),
            const SizedBox(width: 6),
            _actionChip(context, l10n.vehicle_window_open_all, 'vehicle.window.openAll', () => c.openAllWindows()),
          ],
        ),
        // BladeWatch-c2h1: "close all" used to run through the BYD cloud CLOSEWINDOW
        // command, which worked with the car asleep. That path was deleted in 61b4d7f,
        // so every control here is now the local SDK primitive and needs the head unit
        // awake. Say so rather than let a remote tap look like it silently failed.
        const SizedBox(height: 6),
        Text(
          l10n.vehicle_window_awake_note,
          key: const ValueKey('vehicle.window.awakeNote'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (caps.sunroof || caps.sunshade) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (caps.sunroof) Expanded(child: _windowCell(context, l10n.vehicle_sunroof, 5, w.sunroof)),
              if (caps.sunroof && caps.sunshade) const SizedBox(width: 8),
              if (caps.sunshade) Expanded(child: _windowCell(context, l10n.vehicle_sunshade, 6, w.sunshade)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _actionChip(BuildContext context, String label, String key, Future<String?> Function() onTap) => ActionChip(
        key: ValueKey(key),
        label: Text(label),
        onPressed: () async {
          final error = await onTap();
          if (context.mounted && error != null) showVehicleCommandError(context, error);
        },
      );

  Widget _windowCell(BuildContext context, String name, int area, int current) {
    final presets = presetsForArea(area);
    final snap = presetFor(current, presets);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$name (${current < 0 ? '–%' : '$current%'})', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final pct in presets)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _presetButton(context, area, pct, snap == pct),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetButton(BuildContext context, int area, int pct, bool active) {
    final c = controller;
    return SizedBox(
      height: 32,
      child: TextButton(
        key: ValueKey('vehicle.window.${area}_$pct'),
        style: TextButton.styleFrom(
          backgroundColor: active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
          foregroundColor: active ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          padding: EdgeInsets.zero,
        ),
        onPressed: () async {
          final error = await c.setWindowPercent(area, pct);
          if (context.mounted && error != null) showVehicleCommandError(context, error);
        },
        child: Text('$pct%', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

extension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
