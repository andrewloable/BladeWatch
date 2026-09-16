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
/// climate/seat/window ones showed a snackbar with empty text. And the same
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
/// polling), `VehiclePanels.kt` (Climate/Seats/Windows), `TyreOverlay.kt`
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

    return Stack(
      children: [
        Positioned.fill(child: hero),
        ..._tyreCardPositions(theme, c),
        Column(
          children: [
            _StatusCard(l10n: l10n, theme: theme, controller: c),
            if (c.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.vehicle_data_unavailable, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              ),
            const Spacer(),
            _BottomPanel(l10n: l10n, theme: theme, controller: c, tab: _tab, onTabSelected: (t) => setState(() => _tab = t)),
          ],
        ),
      ],
    );
  }

  List<Widget> _tyreCardPositions(ThemeData theme, VehicleController c) {
    final tyres = c.state.tyres;
    return [
      Positioned(top: 60, left: 14, width: 96, child: _TyreCard(label: 'RR', tyre: tyres.rr, theme: theme)),
      Positioned(top: 60 + 96, left: 14, width: 96, child: _TyreCard(label: 'FR', tyre: tyres.fr, theme: theme)),
      Positioned(top: 60, right: 14, width: 96, child: _TyreCard(label: 'RL', tyre: tyres.rl, theme: theme)),
      Positioned(top: 60 + 96, right: 14, width: 96, child: _TyreCard(label: 'FL', tyre: tyres.fl, theme: theme)),
    ];
  }
}

// ─────────────────────────── Status card ─────────────────────────────────

class _StatusCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _StatusCard({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final lockVal = state.doors.overall;
    final (dotColor, lockLabel) = switch (lockVal) {
      1 => (theme.colorScheme.primary, l10n.vehicle_locked),
      2 => (theme.colorScheme.error, l10n.vehicle_unlocked),
      _ => (Colors.grey, '—'),
    };
    final battery = state.battery;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(key: const ValueKey('vehicle.status.lockDot'), width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text(lockLabel, key: const ValueKey('vehicle.status.lockText')),
              ],
            ),
          ),
          _GlassPill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  battery.soc > 0 ? l10n.vehicle_status_charge_fmt(battery.soc) : l10n.vehicle_status_charge_unknown,
                  key: const ValueKey('vehicle.status.charge'),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  battery.soc > 0 ? l10n.vehicle_status_range_fmt(battery.rangeKm) : l10n.vehicle_status_range_unknown,
                  key: const ValueKey('vehicle.status.range'),
                  style: theme.textTheme.bodySmall,
                ),
                // PHEV only. A BEV never reports these, so the two rows simply
                // do not exist there rather than reading "Fuel: 0%" on a car
                // with no tank.
                if (battery.hasFuel) ...[
                  Text(
                    l10n.vehicle_status_fuel_fmt(battery.fuelPercent),
                    key: const ValueKey('vehicle.status.fuel'),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.vehicle_status_fuel_range_fmt(battery.fuelRangeKm),
                    key: const ValueKey('vehicle.status.fuelRange'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _BottomPanel extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;
  final VehicleTab tab;
  final void Function(VehicleTab) onTabSelected;

  const _BottomPanel({required this.l10n, required this.theme, required this.controller, required this.tab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final availableTabs = [
      VehicleTab.climate,
      if (controller.state.capabilities.seats.anyAvailable) VehicleTab.seats,
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
          _AppearanceBar(l10n: l10n, theme: theme, controller: controller),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: switch (effectiveTab) {
                VehicleTab.climate => _ClimateTab(l10n: l10n, theme: theme, controller: controller),
                VehicleTab.seats => _SeatsTab(l10n: l10n, theme: theme, controller: controller),
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
        VehicleTab.seats => l10n.vehicle_tab_seats,
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
          GestureDetector(
            key: const ValueKey('vehicle.model.name'),
            onTap: canPickModel ? () => _showModelPicker(context) : null,
            child: Text(modelLabel, style: theme.textTheme.labelMedium?.copyWith(color: canPickModel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)),
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

class _ClimateTab extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _ClimateTab({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final insideTemp = c.state.climate.insideTempC;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insideTemp != null) ...[
          Text(l10n.vehicle_inside_temp_fmt(insideTemp.toStringAsFixed(1)), style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('vehicle.climate.ac'),
                style: FilledButton.styleFrom(backgroundColor: c.acOn ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest),
                onPressed: () async {
                  final error = await c.toggleAc();
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                },
                child: Text(c.acOn ? l10n.vehicle_ac_on : l10n.vehicle_ac_off),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: const ValueKey('vehicle.climate.maxCooling'),
                style: FilledButton.styleFrom(backgroundColor: c.maxCooling ? theme.colorScheme.error : theme.colorScheme.surfaceContainerHighest),
                onPressed: () async {
                  final error = await c.toggleMaxCooling();
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                },
                child: Text(c.maxCooling ? l10n.vehicle_max_cooling_on : l10n.vehicle_max_cooling_off),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _stepper(context, l10n.vehicle_temp_label, '${c.setpointC}°C', 'vehicle.climate.temp', c.decTemp, c.incTemp)),
            const SizedBox(width: 8),
            Expanded(child: _stepper(context, l10n.vehicle_fan_speed_label, l10n.vehicle_fan_level(c.fanLevel), 'vehicle.climate.fan', c.decFan, c.incFan)),
          ],
        ),
      ],
    );
  }


  /// Climate stepper. The callbacks return an error message (null on success) so
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

// ─────────────────────────── Seats tab ────────────────────────────────────

class _SeatsTab extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VehicleController controller;

  const _SeatsTab({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    // No "nothing available" fallback: this widget is only ever built for
    // VehicleTab.seats, which _BottomPanel only offers when
    // capabilities.seats.anyAvailable is already true (mirrors native's
    // rebuildTabBar() gate) -- showDriver/showPassenger together are exactly
    // that same condition, so at least one row always renders. Native's
    // buildSeatsTab() keeps an equivalent defensive fallback anyway, but it
    // is equally unreachable there (same gate in rebuildTabBar()); trusting
    // the precondition here instead of guarding against a state that cannot
    // occur.
    final c = controller;
    final caps = c.state.capabilities.seats;
    final showDriver = caps.driverHeat || caps.driverCool || caps.driverMemoryRecall;
    final showPassenger = caps.passengerHeat || caps.passengerCool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDriver) _seatRow(context, l10n.vehicle_seat_driver, 1, caps.driverHeat, caps.driverCool, caps.driverMemoryRecall, c.driverHeat, c.driverVent),
        if (showDriver) const SizedBox(height: 12),
        if (showPassenger) _seatRow(context, l10n.vehicle_seat_passenger, 2, caps.passengerHeat, caps.passengerCool, false, c.passengerHeat, c.passengerVent),
      ],
    );
  }

  Widget _seatRow(BuildContext context, String title, int position, bool hasHeat, bool hasCool, bool hasMemory, int heat, int cool) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            if (hasHeat)
              FilledButton(
                key: ValueKey('vehicle.seat.heat.$position'),
                onPressed: () async {
                  final error = await c.cycleSeatHeat(position);
                  if (context.mounted && error != null) {
                    showVehicleCommandError(context, error);
                  }
                },
                child: Text(l10n.vehicle_seat_heat_label(_heatLabel(heat))),
              ),
            if (hasHeat) const SizedBox(width: 8),
            if (hasCool)
              FilledButton(
                key: ValueKey('vehicle.seat.cool.$position'),
                onPressed: () async {
                  final error = await c.cycleSeatCool(position);
                  if (context.mounted && error != null) {
                    showVehicleCommandError(context, error);
                  }
                },
                child: Text(l10n.vehicle_seat_cool_label(_heatLabel(cool))),
              ),
            if (hasMemory && position == 1) ...[
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('vehicle.seat.recall.1'),
                onPressed: () async {
                  final error = await c.recallSeatPosition(1);
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                },
                child: Text(l10n.vehicle_seat_pos_1),
              ),
              const SizedBox(width: 4),
              FilledButton(
                key: const ValueKey('vehicle.seat.recall.2'),
                onPressed: () async {
                  final error = await c.recallSeatPosition(2);
                  if (context.mounted && error != null) showVehicleCommandError(context, error);
                },
                child: Text(l10n.vehicle_seat_pos_2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _heatLabel(int level) => switch (level) {
        1 => l10n.vehicle_heat_low,
        2 => l10n.vehicle_heat_high,
        _ => l10n.vehicle_heat_off,
      };
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
    final snap = presetFor(current);
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
              for (final pct in const [0, 25, 50, 75, 100])
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
