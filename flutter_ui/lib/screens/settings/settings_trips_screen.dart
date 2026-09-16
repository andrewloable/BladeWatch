import 'package:flutter/material.dart';

import 'package:bladewatch_ui/util/currency.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../widgets/bw_choice_chip.dart';
import '../trips/trips_controller.dart';
import '../trips/trips_models.dart';

/// Trip Analytics settings — the pricing the trip cost is computed from, the
/// distance unit, and where trips are stored.
///
/// This lived as the Trips screen's third tab ("Storage"). It is configuration,
/// not data, so it belongs beside the other Settings panes; the Trips screen
/// now carries only its two data views (Trips, Stats).
///
/// Shares the app-root [TripsController] with the Trips screen rather than
/// building its own, so a rate edited here is visible to an already-loaded
/// Trips list without a second fetch. The Settings hub therefore must NOT
/// dispose it — same rule as the appearance controller (BladeWatch-imh6.7).
class SettingsTripsScreen extends StatefulWidget {
  final TripsController controller;

  const SettingsTripsScreen({super.key, required this.controller});

  @override
  State<SettingsTripsScreen> createState() => _SettingsTripsScreenState();
}

class _SettingsTripsScreenState extends State<SettingsTripsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // The pane can be opened without the Trips screen ever having been
    // visited, so it cannot assume the controller is already loaded.
    if (widget.controller.state is! TripsLoaded) widget.controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (widget.controller.state) {
      case TripsLoading():
        return Center(key: const ValueKey('settings.trips.loading'), child: Text(l10n.webview_loading));
      case TripsError(:final message):
        return Center(
          key: const ValueKey('settings.trips.error'),
          child: Text(l10n.trips_load_error(message), style: TextStyle(color: theme.colorScheme.error)),
        );
      case TripsLoaded():
        final loaded = widget.controller.state as TripsLoaded;
        return _TripsSettingsBody(
          key: ValueKey('settings.trips.${loaded.config?.distanceUnit}.${loaded.storage?.storageType}'),
          state: loaded,
          controller: widget.controller,
        );
    }
  }
}

/// Width of the currency picker, and of the number entries beside it.
///
/// These are FIXED rather than free-growing: the pane is 1920px wide on the
/// head unit, and a text field that fills it stops looking like a field.
const double _currencyFieldWidth = 104;
const double _numberFieldWidth = 240;

/// The rate row is currency + gap + number, so capping it at this keeps the
/// electricity rate the same visual width as the fuel entries below it.
const double _rateRowWidth = _currencyFieldWidth + 8 + _numberFieldWidth;

class _TripsSettingsBody extends StatefulWidget {
  final TripsLoaded state;
  final TripsController controller;

  const _TripsSettingsBody({super.key, required this.state, required this.controller});

  @override
  State<_TripsSettingsBody> createState() => _TripsSettingsBodyState();
}

class _TripsSettingsBodyState extends State<_TripsSettingsBody> {
  late bool _analyticsEnabled;
  late final TextEditingController _rateController;
  late final TextEditingController _fuelPriceController;
  late final TextEditingController _tankCapacityController;
  late String _currency;
  late String _distanceUnit;
  late String _storageType;

  /// Loaded once from the generated asset. Null until it arrives; the picker is disabled
  /// until then rather than showing an empty list.
  List<String>? _currencyCodes;

  @override
  void initState() {
    super.initState();
    final cfg = widget.state.config;
    final storage = widget.state.storage;
    _analyticsEnabled = cfg?.enabled ?? false;
    _currency = (cfg?.currency.isNotEmpty ?? false) ? cfg!.currency : Currency.defaultCode;
    _rateController = TextEditingController(text: (cfg?.electricityRate ?? 0.0).toStringAsFixed(4));
    // Both default to 0 meaning NOT CONFIGURED, matching the daemon and the web UI.
    _fuelPriceController =
        TextEditingController(text: (cfg?.fuelPricePerL ?? 0.0).toStringAsFixed(2));
    _tankCapacityController =
        TextEditingController(text: (cfg?.fuelTankCapacityL ?? 0.0).toStringAsFixed(1));
    _distanceUnit = cfg?.distanceUnit ?? 'km';
    _storageType = storage?.storageType ?? 'INTERNAL';
    Currency.codes().then((codes) {
      if (mounted) setState(() => _currencyCodes = codes);
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _fuelPriceController.dispose();
    _tankCapacityController.dispose();
    super.dispose();
  }

  /// Whether the fuel settings belong on screen for this car.
  ///
  /// Reads the CONTROLLERS rather than the config so a value typed in this session keeps the
  /// fields visible; otherwise clearing a fuel price to 0 on a car whose drivetrain probe is
  /// cold would make the field vanish mid-edit.
  bool get _showFuelSettings =>
      (widget.state.config?.isPhev ?? false) ||
      _nonNegative(_fuelPriceController.text) > 0 ||
      _nonNegative(_tankCapacityController.text) > 0;

  /// Parse a numeric settings field, treating anything unusable as 0 (not configured).
  static double _nonNegative(String text) {
    final v = double.tryParse(text.trim()) ?? 0.0;
    return v > 0 ? v : 0.0;
  }

  Future<void> _apply() async {
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    // An unparseable or negative entry means "not configured" rather than a guess: a negative
    // price would make the fuel leg subtract from the trip cost.
    final fuelPrice = _nonNegative(_fuelPriceController.text);
    final tankCapacity = _nonNegative(_tankCapacityController.text);
    final ok = await widget.controller.applyStorageChanges(
      enabled: _analyticsEnabled,
      rate: rate,
      fuelPricePerL: fuelPrice,
      fuelTankCapacityL: tankCapacity,
      currency: _currency,
      distanceUnit: _distanceUnit,
      storageType: _storageType,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.toast_failed_to_save_short)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final storage = widget.state.storage;
    final sdAvailable = storage?.sdCardAvailable ?? false;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.trips_storage_title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const ValueKey('trips.storage.analytics'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.trips_storage_analytics_label),
                  value: _analyticsEnabled,
                  onChanged: (v) => setState(() => _analyticsEnabled = v),
                ),
                const SizedBox(height: 8),
                Text(l10n.trips_storage_rate_label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                SizedBox(
                  width: _rateRowWidth,
                  child: Row(children: [
                  SizedBox(
                    width: _currencyFieldWidth,
                    child: DropdownButtonFormField<String>(
                      key: const ValueKey('trips.storage.currency'),
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: const InputDecoration(isDense: true),
                      // Disabled until the generated catalogue loads, rather than briefly
                      // offering an empty menu.
                      // optionsFor guarantees the stored value is present exactly once.
                      // Without that, a legacy value like "$" is absent from the ISO
                      // catalogue and DropdownButtonFormField asserts on the mismatch,
                      // crashing the settings sheet for the owners most needing it.
                      items: Currency.optionsFor(_currency, _currencyCodes)
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: _currencyCodes == null
                          ? null
                          : (v) => setState(() => _currency = v ?? _currency),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('trips.storage.rate'),
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  ]),
                ),
                const SizedBox(height: 12),
                // PHEV only. A BEV has no tank, so these two are not merely unused there —
                // they read as a bug in the app. `showFuelSettings` also stays true when a
                // value is already configured, so a figure can always be cleared and a
                // warming-up drivetrain probe cannot hide a setting still being applied.
                if (_showFuelSettings) ...[
                  Text(l10n.trips_storage_fuel_price_label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  // Width-constrained for the same reason as the tank field below.
                  SizedBox(
                    width: _numberFieldWidth,
                    child: TextField(
                      key: const ValueKey('trips.storage.fuelPrice'),
                      controller: _fuelPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.trips_storage_tank_capacity_label, style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  // A bare full-width underline on a 1920px panel reads as a SLIDER
                  // TRACK, and with the value at 0 sitting hard against the left
                  // edge it reads as a slider parked at its minimum. Constraining
                  // the width makes it read as the number entry it actually is —
                  // reported from the car, not a hypothetical.
                  SizedBox(
                    width: _numberFieldWidth,
                    child: TextField(
                      key: const ValueKey('trips.storage.tankCapacity'),
                      controller: _tankCapacityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(isDense: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(l10n.trips_storage_distance_unit_label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Row(children: [
                  BwChoiceChip(key: const ValueKey('trips.storage.unit.km'), label: const Text('km'), selected: _distanceUnit == 'km', onSelected: (_) => setState(() => _distanceUnit = 'km')),
                  const SizedBox(width: 8),
                  BwChoiceChip(key: const ValueKey('trips.storage.unit.mi'), label: const Text('mi'), selected: _distanceUnit == 'mi', onSelected: (_) => setState(() => _distanceUnit = 'mi')),
                ]),
                const SizedBox(height: 12),
                Text(l10n.trips_storage_location_label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Row(children: [
                  BwChoiceChip(
                    key: const ValueKey('trips.storage.location.internal'),
                    label: Text(l10n.trips_storage_internal),
                    selected: _storageType == 'INTERNAL',
                    onSelected: (_) => setState(() => _storageType = 'INTERNAL'),
                  ),
                  const SizedBox(width: 8),
                  BwChoiceChip(
                    key: const ValueKey('trips.storage.location.sdCard'),
                    label: Text(sdAvailable ? l10n.trips_storage_sd_card : l10n.trips_storage_sd_card_unavailable),
                    selected: _storageType == 'SD_CARD',
                    onSelected: sdAvailable ? (_) => setState(() => _storageType = 'SD_CARD') : null,
                  ),
                ]),
                if (storage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.trips_storage_usage_line(storage.usedMb.toString(), storage.usedUnit, storage.limitMb.toString(), storage.tripsCount),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  if (storage.storagePath.isNotEmpty) Text(storage.storagePath, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                ],
                const SizedBox(height: 12),
                FilledButton(key: const ValueKey('trips.storage.apply'), onPressed: _apply, child: Text(l10n.trips_storage_apply)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SyncCard(controller: widget.controller),
      ],
    );
  }
}

class _SyncCard extends StatelessWidget {
  final TripsController controller;
  const _SyncCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('trips.syncCard'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.trips_sync_title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(l10n.trips_sync_description, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            if (controller.syncResult != null) ...[
              Text(
                controller.syncResult!.success
                    ? l10n.trips_sync_success(controller.syncResult!.added, controller.syncResult!.removed, controller.syncResult!.total)
                    : controller.syncResult!.error ?? l10n.trips_sync_failed_generic,
                style: TextStyle(color: controller.syncResult!.success ? theme.colorScheme.primary : theme.colorScheme.error),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  key: const ValueKey('trips.sync.dismiss'),
                  onPressed: controller.dismissSyncResult,
                  child: Text(l10n.settings_recording_dismiss),
                ),
              ),
            ] else if (controller.syncRunning)
              Center(key: const ValueKey('trips.sync.running'), child: Text(l10n.trips_sync_running))
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(key: const ValueKey('trips.sync.button'), onPressed: controller.syncDatabase, child: Text(l10n.trips_sync_button)),
              ),
          ],
        ),
      ),
    );
  }
}
