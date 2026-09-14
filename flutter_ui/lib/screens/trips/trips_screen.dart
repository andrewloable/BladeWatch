import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'trip_detail_controller.dart';
import 'trip_detail_screen.dart';
import 'trips_controller.dart';
import 'trips_models.dart';
import '../../widgets/bw_choice_chip.dart';

/// Ground truth: `TripsController.kt` (852 LOC) + `TripsFragment.kt`. Native
/// puts its 3-tab bar at the *bottom* of the screen, content above it —
/// preserved as-is, not "fixed" to a top tab bar.
class TripsScreen extends StatefulWidget {
  final TripsController controller;
  final TripDetailController Function() detailControllerFactory;

  const TripsScreen({super.key, required this.controller, required this.detailControllerFactory});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
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
    final c = widget.controller;

    // Mirrors native's OnBackPressedCallback(enabled while the detail
    // overlay is open): back closes the detail instead of leaving the
    // screen.
    return PopScope(
      canPop: c.selectedTripId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) c.closeDetail();
      },
      child: c.selectedTripId == null ? _buildList(context, c) : _buildDetail(context, c),
    );
  }

  Widget _buildDetail(BuildContext context, TripsController c) {
    return TripDetailScreen(
      controller: widget.detailControllerFactory(),
      tripId: c.selectedTripId!,
      config: c.state is TripsLoaded ? (c.state as TripsLoaded).config : null,
      onClose: c.closeDetail,
    );
  }

  Widget _buildList(BuildContext context, TripsController c) {
    return Column(
      children: [
        Expanded(child: _body(context, c)),
        _TabBar(activeTab: c.activeTab, onSelect: c.selectTab),
      ],
    );
  }

  Widget _body(BuildContext context, TripsController c) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (c.state) {
      case TripsLoading():
        return Center(key: const ValueKey('trips.loading'), child: Text(l10n.webview_loading));
      case TripsError(:final message):
        return Center(
          key: const ValueKey('trips.error'),
          child: Text(l10n.trips_load_error(message), style: TextStyle(color: theme.colorScheme.error)),
        );
      case TripsLoaded():
        return switch (c.activeTab) {
          TripsTab.trips => _TripsTab(state: c.state as TripsLoaded, onSelectTrip: c.openDetail, onSelectFilter: c.selectFilter, activeFilter: c.activeFilter),
          TripsTab.stats => _StatsTab(state: c.state as TripsLoaded),
          TripsTab.storage => _StorageTab(
              key: ValueKey('trips.storage.${(c.state as TripsLoaded).config?.distanceUnit}.${(c.state as TripsLoaded).storage?.storageType}'),
              state: c.state as TripsLoaded,
              controller: c,
            ),
        };
    }
  }
}

class _TabBar extends StatelessWidget {
  final TripsTab activeTab;
  final ValueChanged<TripsTab> onSelect;

  const _TabBar({required this.activeTab, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tabs = [
      (TripsTab.trips, l10n.trips_tab_trips, 'trips.tab.trips'),
      (TripsTab.stats, l10n.trips_tab_stats, 'trips.tab.stats'),
      (TripsTab.storage, l10n.trips_tab_storage, 'trips.tab.storage'),
    ];
    return ColoredBox(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            for (final (tab, label, key) in tabs)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: BwChoiceChip(
                    key: ValueKey(key),
                    label: Text(label, textAlign: TextAlign.center),
                    selected: tab == activeTab,
                    onSelected: (_) => onSelect(tab),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final TripsDaysFilter activeFilter;
  final ValueChanged<TripsDaysFilter> onSelect;

  const _FilterRow({required this.activeFilter, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      TripsDaysFilter.seven: l10n.trips_filter_7_days,
      TripsDaysFilter.fourteen: l10n.trips_filter_14_days,
      TripsDaysFilter.thirty: l10n.trips_filter_30_days,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in TripsDaysFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BwChoiceChip(
                key: ValueKey('trips.filter.${filter.days}'),
                label: Text(labels[filter]!),
                selected: filter == activeFilter,
                onSelected: (_) => onSelect(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripsTab extends StatelessWidget {
  final TripsLoaded state;
  final ValueChanged<int> onSelectTrip;
  final ValueChanged<TripsDaysFilter> onSelectFilter;
  final TripsDaysFilter activeFilter;

  const _TripsTab({required this.state, required this.onSelectTrip, required this.onSelectFilter, required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distUnit = state.config?.distanceUnit ?? 'km';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _FilterRow(activeFilter: activeFilter, onSelect: onSelectFilter),
        const SizedBox(height: 8),
        if (state.summary != null) ...[
          _SummaryCard(summary: state.summary!, distanceUnit: distUnit),
          const SizedBox(height: 12),
        ],
        if (state.trips.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(key: const ValueKey('trips.empty'), child: Text(l10n.trips_empty_state, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
          )
        else
          for (final trip in state.trips) ...[
            _TripRow(trip: trip, distanceUnit: distUnit, onTap: () => onSelectTrip(trip.id)),
            const SizedBox(height: 4),
          ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final TripsSummary summary;
  final String distanceUnit;

  const _SummaryCard({required this.summary, required this.distanceUnit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final distDisplay = distanceUnit == 'mi'
        ? '${(summary.totalDistanceKm * 0.621371).toStringAsFixed(1)} mi'
        : '${summary.totalDistanceKm.toStringAsFixed(1)} km';

    return Card(
      key: const ValueKey('trips.summaryCard'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.trips_period_summary_title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(children: [_stat('${summary.tripCount}', l10n.trips_stat_trips), _stat(distDisplay, distanceUnit.toUpperCase())])),
              Expanded(child: Column(children: [_stat(summary.formattedHours, l10n.trips_stat_hours), _stat('${summary.avgEfficiency.toStringAsFixed(0)}%', l10n.trips_stat_efficiency)])),
              Expanded(
                child: Column(children: [
                  _stat(summary.totalEnergyKwh.toStringAsFixed(1), l10n.trips_stat_kwh),
                  _stat((summary.avgEnergyPerKm * 100).toStringAsFixed(2), l10n.trips_stat_kwh_per_100km),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Builder(builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
        );
      });
}

class _TripRow extends StatelessWidget {
  final TripItem trip;
  final String distanceUnit;
  final VoidCallback onTap;

  const _TripRow({required this.trip, required this.distanceUnit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dist = distanceUnit == 'mi' ? '${(trip.distanceKm * 0.621371).toStringAsFixed(1)} mi' : '${trip.distanceKm.toStringAsFixed(1)} km';

    return Card(
      key: ValueKey('trips.row.${trip.id}'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(trip.formattedDate, style: theme.textTheme.bodyMedium)),
                if (trip.overallScore > 0) Text(l10n.trips_score_label(trip.overallScore), style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: Text('$dist  ·  ${trip.formattedDuration}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
                if (trip.tripCost > 0 && trip.currency.isNotEmpty)
                  Text('${trip.currency} ${trip.tripCost.toStringAsFixed(2)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final TripsLoaded state;
  const _StatsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dna = state.dna;
    final range = state.range;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          key: const ValueKey('trips.driverScoreCard'),
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.trips_driver_score_title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Center(child: Text('${dna?.scoreOutOf500 ?? 0} / 500', style: theme.textTheme.headlineMedium)),
              Center(child: Text(l10n.trips_driver_score_overall(dna?.overall ?? 0), style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          key: const ValueKey('trips.rangeCard'),
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.trips_range_title, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (range != null && range.estimatedKm > 0) ...[
                Center(child: Text('${range.estimatedKm.toStringAsFixed(0)} km', style: theme.textTheme.headlineMedium)),
                if (range.builtInKm > 0) Center(child: Text(l10n.trips_range_byd_estimate(range.builtInKm.toStringAsFixed(0)), style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
              ] else
                Center(child: Text(l10n.trips_range_no_data, style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
            ]),
          ),
        ),
        if (dna != null) ...[
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('trips.dnaCard'),
            color: theme.colorScheme.surfaceContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.trips_dna_title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _ScoreBar(label: l10n.trips_dna_anticipation, score: dna.anticipation),
                _ScoreBar(label: l10n.trips_dna_smoothness, score: dna.smoothness),
                _ScoreBar(label: l10n.trips_dna_speed_discipline, score: dna.speedDiscipline),
                _ScoreBar(label: l10n.trips_dna_efficiency, score: dna.efficiency),
                _ScoreBar(label: l10n.trips_dna_consistency, score: dna.consistency),
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreBar({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (score.clamp(0, 100)) / 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodyMedium)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fraction, minHeight: 8, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: 6),
        Text('$score', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
      ]),
    );
  }
}

class _StorageTab extends StatefulWidget {
  final TripsLoaded state;
  final TripsController controller;

  const _StorageTab({super.key, required this.state, required this.controller});

  @override
  State<_StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends State<_StorageTab> {
  late bool _analyticsEnabled;
  late final TextEditingController _currencyController;
  late final TextEditingController _rateController;
  late String _distanceUnit;
  late String _storageType;

  @override
  void initState() {
    super.initState();
    final cfg = widget.state.config;
    final storage = widget.state.storage;
    _analyticsEnabled = cfg?.enabled ?? false;
    _currencyController = TextEditingController(text: cfg?.currency ?? 'USD');
    _rateController = TextEditingController(text: (cfg?.electricityRate ?? 0.0).toStringAsFixed(4));
    _distanceUnit = cfg?.distanceUnit ?? 'km';
    _storageType = storage?.storageType ?? 'INTERNAL';
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final ok = await widget.controller.applyStorageChanges(
      enabled: _analyticsEnabled,
      rate: rate,
      currency: _currencyController.text,
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
                Row(children: [
                  SizedBox(
                    width: 80,
                    child: TextField(key: const ValueKey('trips.storage.currency'), controller: _currencyController, decoration: const InputDecoration(isDense: true)),
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
                const SizedBox(height: 12),
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
