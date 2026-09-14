import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../rpc/jwt_source.dart';
import '../../rpc/services/recordings_service_client.dart';
import 'recordings_controller.dart';
import 'thumbnail_image.dart';
import 'recordings_models.dart';
import 'recordings_player_controller.dart';
import 'recordings_player_screen.dart';

/// Width at which Recordings uses native's master-detail arrangement: clip
/// list on the left, persistent player pane on the right. Below this there is
/// no room for both, so the list stays full-width and tapping pushes the
/// player as its own route.
const double _masterDetailBreakpoint = 1100;

/// Ground truth: `RecordingsFragment.kt` (895 LOC — header/segment/date/chip
/// chrome) + `RecordingLibraryFragment.kt` (926 LOC — the grid, multi-select,
/// delete, and its own filter bottom sheet).
///
/// Native hosts the library as a *child fragment embedded inside*
/// `RecordingsFragment`, with its own internal filter bar and date row
/// hidden (`newInstanceEmbedded()`) since the parent drives everything
/// through one `applyAll()` call. This port has no fragment-hosting-fragment
/// concept, so both are collapsed into one screen + private widgets below —
/// same visible result, no Android-lifecycle artifact to translate.
///
/// The task explicitly requires reproducing `RecordingLibraryFragment`'s own
/// filter bottom sheet, which native only ever uses for actor/severity chips
/// (Surveillance) — Type chips (Dashcam) have no bottom-sheet equivalent
/// natively, only `RecordingsFragment`'s own always-visible header row. Both
/// are reproduced faithfully: Type as an inline chip row, actor/severity via
/// the "Filter" pill + bottom sheet + inline dismissable chips (mirroring
/// `renderActiveFilters()`).
class RecordingsScreen extends StatefulWidget {
  final RecordingsController controller;
  final RecordingsServiceClient recordingsService;
  final JwtSource jwtSource;
  final VoidCallback onOpenSettings;

  const RecordingsScreen({
    super.key,
    required this.controller,
    required this.recordingsService,
    required this.jwtSource,
    required this.onOpenSettings,
  });

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  String? _jwt;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    unawaited(widget.controller.load());
    unawaited(_loadJwt());
  }

  Future<void> _loadJwt() async {
    final jwt = await widget.jwtSource.mintJwt();
    if (mounted) setState(() => _jwt = jwt);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  /// The clip shown in the embedded detail pane, at head-unit width. Null means
  /// nothing is selected and the pane shows native's "Select a recording"
  /// placeholder. Unused below the breakpoint, where tapping still pushes the
  /// full-screen player instead.
  RecordingItem? _selected;

  /// Rebuilt whenever the selection changes so the pane starts on the right
  /// clip; disposed with the state.
  RecordingsPlayerController? _paneController;

  void _selectForPane(RecordingItem item) {
    final visible = widget.controller.visible;
    final index = visible.indexWhere((r) => r.filename == item.filename);
    _paneController?.dispose();
    setState(() {
      _selected = item;
      _paneController = RecordingsPlayerController(
        recordingsService: widget.recordingsService,
        playlist: visible,
        initialIndex: index < 0 ? 0 : index,
      );
    });
  }

  void _clearPane() {
    _paneController?.dispose();
    setState(() {
      _selected = null;
      _paneController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Native is master-detail: the clip list on the left, a persistent
            // player pane on the right. Below the breakpoint there is no room
            // for both, so the list stays full-width and tapping pushes the
            // player as a route (BladeWatch-3odo).
            final split = constraints.maxWidth >= _masterDetailBreakpoint;
            return Column(
              children: [
                _Header(controller: c, onOpenSettings: widget.onOpenSettings),
                Expanded(
                  child: split
                      ? Row(
                          children: [
                            Expanded(flex: 11, child: _buildBody(context, c, split: true)),
                            const VerticalDivider(width: 1),
                            Expanded(flex: 9, child: _buildDetailPane(context)),
                          ],
                        )
                      : _buildBody(context, c, split: false),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: c.selectMode ? _SelectToolbar(controller: c) : null,
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paneController = _paneController;

    if (_selected == null || paneController == null) {
      return Container(
        key: const ValueKey('recordings.detail.empty'),
        color: theme.colorScheme.surfaceContainer,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(l10n.recordings_preview_placeholder_title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.recordings_preview_placeholder_body,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RecordingsPlayerScreen(
      // Keyed by filename so selecting a different clip rebuilds the player
      // rather than reusing the previous clip's video controller.
      key: ValueKey('recordings.detail.${_selected!.filename}'),
      controller: paneController,
      jwtSource: widget.jwtSource,
      onClose: _clearPane,
    );
  }

  Widget _buildBody(BuildContext context, RecordingsController c, {required bool split}) {
    final l10n = AppLocalizations.of(context)!;
    switch (c.state) {
      case RecordingsLoading():
        return const Center(key: ValueKey('recordings.loading'), child: CircularProgressIndicator());
      case RecordingsError():
        return _ErrorView(onRetry: () => c.load());
      case RecordingsLoaded():
        final visible = c.visible;
        if (visible.isEmpty) {
          return _EmptyView(
            key: const ValueKey('recordings.empty'),
            text: switch (c.filter.source) {
              RecordingSource.surveillance => l10n.recording_lib_no_recordings_sentry,
              RecordingSource.dashcam when c.filter.dashcamTypes.contains('NORMAL') &&
                  !c.filter.dashcamTypes.contains('PROXIMITY') =>
                l10n.recording_lib_no_recordings_normal,
              RecordingSource.dashcam when c.filter.dashcamTypes.contains('PROXIMITY') &&
                  !c.filter.dashcamTypes.contains('NORMAL') =>
                l10n.recording_lib_no_recordings_proximity,
              RecordingSource.dashcam => l10n.recording_lib_no_recordings,
            },
          );
        }
        return _RecordingsGrid(
          controller: c,
          items: visible,
          jwt: _jwt,
          selectedFilename: split ? _selected?.filename : null,
          onTapItem: (item) => split ? _selectForPane(item) : _openPlayer(context, item),
        );
    }
  }

  void _openPlayer(BuildContext context, RecordingItem item) {
    final visible = widget.controller.visible;
    final index = visible.indexWhere((r) => r.filename == item.filename);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecordingsPlayerScreen(
        controller: RecordingsPlayerController(
          recordingsService: widget.recordingsService,
          playlist: visible,
          initialIndex: index < 0 ? 0 : index,
        ),
        jwtSource: widget.jwtSource,
      ),
    ));
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      key: const ValueKey('recordings.error'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.recording_lib_no_recordings),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(l10n.action_retry)),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String text;
  const _EmptyView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(child: Text(text, style: theme.textTheme.bodyLarge));
  }
}

class _Header extends StatelessWidget {
  final RecordingsController controller;
  final VoidCallback onOpenSettings;
  const _Header({required this.controller, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = controller;
    final loaded = c.state is RecordingsLoaded ? c.state as RecordingsLoaded : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.recordings_title, style: theme.textTheme.headlineSmall)),
              Text(
                loaded == null
                    ? l10n.recordings_summary_pending
                    : l10n.recordings_summary_format(
                        loaded.stats.todayCount,
                        loaded.stats.totalCount,
                        _formatBytes(loaded.stats.totalBytes),
                      ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              // A labelled button, not a bare gear: native names this control.
              FilledButton.tonalIcon(
                key: const ValueKey('recordings.settings'),
                icon: const Icon(Icons.settings, size: 18),
                label: Text(l10n.recordings_action_settings),
                onPressed: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<RecordingSource>(
            showSelectedIcon: false,
            key: const ValueKey('recordings.segments'),
            segments: [
              ButtonSegment(
                value: RecordingSource.dashcam,
                label: Text(loaded == null
                    ? l10n.recordings_segment_dashcam
                    : l10n.recordings_segment_dashcam_count(loaded.stats.dashcamCount)),
              ),
              ButtonSegment(
                value: RecordingSource.surveillance,
                label: Text(loaded == null
                    ? l10n.recordings_segment_surveillance
                    : l10n.recordings_segment_surveillance_count(loaded.stats.surveillanceCount)),
              ),
            ],
            selected: {c.filter.source},
            onSelectionChanged: (s) => c.setSource(s.first),
          ),
          const SizedBox(height: 12),
          _DateRow(controller: c),
          const SizedBox(height: 8),
          if (c.filter.source == RecordingSource.dashcam)
            _TypeChipRow(controller: c)
          else
            _SurveillanceFilterRow(controller: c),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1000000000) return '${(bytes / 1000000000).toStringAsFixed(1)} GB';
    if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
    if (bytes >= 1000) return '${(bytes / 1000).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _DateRow extends StatelessWidget {
  final RecordingsController controller;
  const _DateRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final now = DateTime.fromMillisecondsSinceEpoch(c.nowMs);
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final label = !c.filter.dateNarrowed
        ? l10n.recording_lib_date_all_days
        : c.filter.selectedDayMs == today
            ? l10n.recording_lib_date_today
            : c.filter.selectedDayMs == today - 86400000
                ? l10n.recording_lib_date_yesterday
                : _formatDate(c.filter.selectedDayMs);

    return Row(
      children: [
        // Native puts a calendar icon beside the date control so the row reads
        // as a date picker rather than a generic pager.
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.calendar_today, size: 18),
        ),
        if (c.filter.dateNarrowed)
          IconButton(
            key: const ValueKey('recordings.prevDay'),
            icon: const Icon(Icons.chevron_left),
            onPressed: () => c.shiftDay(-1),
          ),
        Expanded(
          child: OutlinedButton(
            key: const ValueKey('recordings.datePick'),
            onPressed: () => _pickDate(context, c),
            child: Text(label),
          ),
        ),
        if (c.filter.dateNarrowed)
          IconButton(
            key: const ValueKey('recordings.nextDay'),
            icon: const Icon(Icons.chevron_right),
            onPressed: c.filter.selectedDayMs < today ? () => c.shiftDay(1) : null,
          ),
        if (c.filter.dateNarrowed)
          IconButton(
            key: const ValueKey('recordings.clearDate'),
            icon: const Icon(Icons.close),
            tooltip: l10n.cd_clear_filter,
            onPressed: () => c.setDateNarrowed(false),
          ),
      ],
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate(BuildContext context, RecordingsController c) async {
    final now = DateTime.now();
    final initial = DateTime.fromMillisecondsSinceEpoch(c.filter.selectedDayMs);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: AppLocalizations.of(context)!.recording_lib_pick_date,
    );
    if (picked != null) c.pickDate(picked.millisecondsSinceEpoch);
  }
}

class _TypeChipRow extends StatelessWidget {
  final RecordingsController controller;
  const _TypeChipRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Native labels this row "TYPE"; without it the chips have no heading.
        Text(
          l10n.recording_lib_filter_section_type.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        FilterChip(
          key: const ValueKey('recordings.chip.typeNormal'),
          label: Text(l10n.recording_lib_chip_type_normal),
          selected: c.filter.dashcamTypes.contains('NORMAL'),
          onSelected: (_) => c.toggleDashcamType('NORMAL'),
        ),
        FilterChip(
          key: const ValueKey('recordings.chip.typeProximity'),
          label: Text(l10n.recording_lib_chip_type_proximity),
          selected: c.filter.dashcamTypes.contains('PROXIMITY'),
          onSelected: (_) => c.toggleDashcamType('PROXIMITY'),
        ),
        if (c.filter.chipsActive)
          ActionChip(
            key: const ValueKey('recordings.resetChips'),
            label: Text(l10n.recording_lib_filter_reset),
            onPressed: c.resetChips,
          ),
      ],
    );
  }
}

class _SurveillanceFilterRow extends StatelessWidget {
  final RecordingsController controller;
  const _SurveillanceFilterRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final active = <(String id, String label, VoidCallback onRemove)>[
      if (c.filter.actorClasses.contains('person'))
        ('person', l10n.recording_lib_chip_person, () => c.toggleActorClass('person')),
      if (c.filter.actorClasses.contains('vehicle'))
        ('vehicle', l10n.recording_lib_chip_vehicle, () => c.toggleActorClass('vehicle')),
      if (c.filter.actorClasses.contains('bike'))
        ('bike', l10n.recording_lib_chip_bike, () => c.toggleActorClass('bike')),
      if (c.filter.actorClasses.contains('animal'))
        ('animal', l10n.recording_lib_chip_animal, () => c.toggleActorClass('animal')),
      if (c.filter.severities.contains('ALERT'))
        ('severity-alert', l10n.recording_lib_chip_alert, () => c.toggleSeverity('ALERT')),
      if (c.filter.severities.contains('CRITICAL'))
        ('severity-critical', l10n.recording_lib_chip_critical, () => c.toggleSeverity('CRITICAL')),
    ];

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          key: const ValueKey('recordings.openFilterSheet'),
          avatar: const Icon(Icons.tune, size: 18),
          label: Text(active.isEmpty
              ? l10n.recording_lib_filter_button
              : l10n.recording_lib_filter_button_active(active.length)),
          onPressed: () => _openFilterSheet(context, c),
        ),
        for (final (id, label, onRemove) in active)
          Chip(
            key: ValueKey('recordings.activeChip.$id'),
            label: Text(label),
            onDeleted: onRemove,
            deleteButtonTooltipMessage: l10n.cd_clear_filter,
          ),
        if (c.filter.chipsActive)
          ActionChip(
            key: const ValueKey('recordings.resetChips'),
            label: Text(l10n.recording_lib_filter_reset),
            onPressed: c.resetChips,
          ),
      ],
    );
  }

  Future<void> _openFilterSheet(BuildContext context, RecordingsController c) {
    // isScrollControlled removes the default 9/16-screen height cap so the
    // sheet can size to content, but that leaves it unbounded -- an
    // explicit max height is what actually gives the sheet's own
    // SingleChildScrollView something to scroll within once content
    // exceeds it, rather than silently overflowing past the viewport.
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      builder: (sheetContext) => _FilterSheet(controller: c),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final RecordingsController controller;
  const _FilterSheet({required this.controller});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
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
    final c = widget.controller;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recording_lib_filter_sheet_title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.recording_lib_filter_section_what, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilterChip(
                key: const ValueKey('recordings.sheet.actorAny'),
                label: Text(l10n.recording_lib_chip_any),
                selected: c.filter.actorClasses.isEmpty,
                onSelected: (_) => c.resetActorClasses(),
              ),
              for (final name in const ['person', 'vehicle', 'bike', 'animal'])
                FilterChip(
                  key: ValueKey('recordings.sheet.actor.$name'),
                  label: Text(_actorLabel(l10n, name)),
                  selected: c.filter.actorClasses.contains(name),
                  onSelected: (_) => c.toggleActorClass(name),
                ),
            ]),
            const SizedBox(height: 16),
            Text(l10n.recording_lib_filter_section_severity, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilterChip(
                key: const ValueKey('recordings.sheet.sevAny'),
                label: Text(l10n.recording_lib_chip_any),
                selected: c.filter.severities.isEmpty,
                onSelected: (_) => c.resetSeverities(),
              ),
              for (final name in const ['ALERT', 'CRITICAL'])
                FilterChip(
                  key: ValueKey('recordings.sheet.sev.$name'),
                  label: Text(name == 'ALERT' ? l10n.recording_lib_chip_alert : l10n.recording_lib_chip_critical),
                  selected: c.filter.severities.contains(name),
                  onSelected: (_) => c.toggleSeverity(name),
                ),
            ]),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  key: const ValueKey('recordings.sheet.reset'),
                  onPressed: c.resetChips,
                  child: Text(l10n.recording_lib_filter_reset),
                ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('recordings.sheet.apply'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.recording_lib_filter_apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _actorLabel(AppLocalizations l10n, String name) => switch (name) {
        'person' => l10n.recording_lib_chip_person,
        'vehicle' => l10n.recording_lib_chip_vehicle,
        'bike' => l10n.recording_lib_chip_bike,
        _ => l10n.recording_lib_chip_animal,
      };
}

class _SelectToolbar extends StatelessWidget {
  final RecordingsController controller;
  const _SelectToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    return BottomAppBar(
      child: Row(
        children: [
          TextButton(
            key: const ValueKey('recordings.select.cancel'),
            onPressed: c.exitSelectMode,
            child: Text(l10n.action_cancel),
          ),
          Text(l10n.recording_lib_selected_count(c.selected.length)),
          const Spacer(),
          TextButton(
            key: const ValueKey('recordings.select.all'),
            onPressed: c.selectAllVisible,
            child: Text(l10n.action_select_all),
          ),
          FilledButton.tonal(
            key: const ValueKey('recordings.select.delete'),
            onPressed: c.selected.isEmpty ? null : () => _confirmBatchDelete(context, c),
            child: Text(l10n.action_delete),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBatchDelete(BuildContext context, RecordingsController c) async {
    final l10n = AppLocalizations.of(context)!;
    final count = c.selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.delete_recordings_title(count)),
        content: Text(l10n.delete_recordings_message(count)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
          FilledButton(
            key: const ValueKey('recordings.confirmBatchDelete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final outcome = await c.deleteSelected();
    if (!context.mounted) return;
    final message = outcome.failed > 0
        ? l10n.toast_batch_delete_partial(outcome.deleted, outcome.failed)
        : l10n.recordings_deleted_count(outcome.deleted);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecordingsGrid extends StatelessWidget {
  final RecordingsController controller;
  final List<RecordingItem> items;
  final String? jwt;
  final ValueChanged<RecordingItem> onTapItem;

  /// Which clip the detail pane is showing, so the list can mark it. Null in
  /// the narrow layout, where there is no pane to be in sync with.
  final String? selectedFilename;

  const _RecordingsGrid({
    required this.controller,
    required this.items,
    required this.jwt,
    required this.onTapItem,
    required this.selectedFilename,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final groups = groupIntoSections(items, controller.filter.dateNarrowed, controller.nowMs);

    return CustomScrollView(
      key: const ValueKey('recordings.grid'),
      slivers: [
        for (final group in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeaderDelegate(_sectionLabel(l10n, group.section), theme),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = group.items[index];
                  return _RecordingCard(
                    key: ValueKey('recordings.card.${item.filename}'),
                    controller: controller,
                    item: item,
                    jwt: jwt,
                    isPlaying: selectedFilename == item.filename,
                    onTap: () => onTapItem(item),
                  );
                },
                childCount: group.items.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _sectionLabel(AppLocalizations l10n, RecordingSection section) => switch (section) {
        TimeOfDaySection(:final bucket) => switch (bucket) {
            TimeOfDayBucket.morning => l10n.recording_lib_section_morning,
            TimeOfDayBucket.afternoon => l10n.recording_lib_section_afternoon,
            TimeOfDayBucket.evening => l10n.recording_lib_section_evening,
            TimeOfDayBucket.night => l10n.recording_lib_section_night,
          },
        DateSection(:final relativeDay, :final dayStartMs) => switch (relativeDay) {
            RelativeDay.today => l10n.recording_lib_date_today,
            RelativeDay.yesterday => l10n.recording_lib_date_yesterday,
            RelativeDay.other => _formatSectionDate(dayStartMs),
          },
      };

  String _formatSectionDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final ThemeData theme;
  const _SectionHeaderDelegate(this.label, this.theme);

  @override
  double get minExtent => 32;
  @override
  double get maxExtent => 32;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) =>
      oldDelegate.label != label || oldDelegate.theme != theme;
}

class _RecordingCard extends StatelessWidget {
  final RecordingsController controller;
  final RecordingItem item;
  final String? jwt;
  final VoidCallback onTap;

  /// True when this clip is the one in the detail pane — native outlines the
  /// playing card so the list and the pane stay visually connected.
  final bool isPlaying;

  const _RecordingCard({
    super.key,
    required this.controller,
    required this.item,
    required this.jwt,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = controller;
    final selected = c.selected.contains(item.filename);
    // Local so the null check below promotes — `jwt` is a public final field,
    // which Dart's field promotion does not cover.
    final jwt = this.jwt;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isPlaying
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: c.selectMode ? () => c.toggleSelected(item.filename) : onTap,
        onLongPress: () {
          if (!c.selectMode) c.enterSelectMode();
          c.toggleSelected(item.filename);
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                      if (jwt != null)
                        // Not Image.network: the daemon answers an uncached
                        // thumbnail with 202 + Retry-After while it generates
                        // one in the background. See thumbnail_image.dart.
                        ThumbnailImage(filename: item.filename, jwt: jwt),
                      if (item.severity != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            color: item.severity == 'CRITICAL' ? const Color(0xFFEF4444) : const Color(0xFFFF9B3D),
                          ),
                        ),
                      // Native overlays a circular play button so the card
                      // reads as playable; without it a thumbnail looks inert.
                      if (!c.selectMode)
                        Center(
                          child: Container(
                            decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _Badge(text: l10n.recording_lib_camera_badge(item.cameraId)),
                      ),
                      if (item.severity != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _Badge(
                            text: item.severity == 'CRITICAL' ? l10n.rec_severity_critical : l10n.rec_severity_alert,
                            color: item.severity == 'CRITICAL'
                                ? const Color(0xCCEF4444)
                                : const Color(0xCCFF8800),
                          ),
                        ),
                      if (c.selectMode)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Checkbox(
                            value: selected,
                            onChanged: (_) => c.toggleSelected(item.filename),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.timeLabel, style: theme.textTheme.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${item.formattedDuration} · ${item.formattedSize}',
                        style: theme.textTheme.labelSmall,
                      ),
                      if (item.detectedClasses.isNotEmpty || item.proximityLabel != null)
                        Text(
                          [
                            ...item.detectedClasses,
                            if (item.proximityLabel != null) _proximityText(l10n, item.proximityLabel!),
                          ].join(' · '),
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!c.selectMode)
              Positioned(
                bottom: 4,
                right: 4,
                child: IconButton(
                  key: ValueKey('recordings.delete.${item.filename}'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(context, c, item),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _proximityText(AppLocalizations l10n, ProximityLabel label) => switch (label) {
        ProximityLabel.veryClose => l10n.recording_lib_proximity_very_close,
        ProximityLabel.close => l10n.recording_lib_proximity_close,
        ProximityLabel.mid => l10n.recording_lib_proximity_mid,
        ProximityLabel.far => l10n.recording_lib_proximity_far,
      };

  Future<void> _confirmDelete(BuildContext context, RecordingsController c, RecordingItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dialog_delete_recording_title),
        content: Text(l10n.dialog_delete_recording_message(item.filename)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
          FilledButton(
            key: const ValueKey('recordings.confirmDelete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await c.deleteRecording(item.filename);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? l10n.toast_recording_deleted : l10n.toast_recording_delete_failed),
    ));
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  const _Badge({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
