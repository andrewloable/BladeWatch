import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
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

/// The recording library, presented as the companion presents it (BladeWatch-rdtj.70, the
/// owner's choice): a line of totals, type and day filters (who and how bad for sentry clips),
/// a select bar, and one row per clip -- thumbnail, when, type, length, size, what was seen --
/// loaded a page at a time as the list scrolls (see [RecordingsController]).
///
/// What stays the head unit's own: the player pane on the right at head-unit width (the
/// companion, on a phone, opens the player full screen), the Settings shortcut, and a
/// long-press to start selecting.
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
    _paneController?.dispose();
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
    final clips = widget.controller.clips;
    final index = clips.indexWhere((r) => r.filename == item.filename);
    _paneController?.dispose();
    setState(() {
      _selected = item;
      _paneController = RecordingsPlayerController(
        recordingsService: widget.recordingsService,
        playlist: clips,
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
    if (c.failed) return _ErrorView(onRetry: () => c.load());
    if (!c.loaded) return const Center(key: ValueKey('recordings.loading'), child: CircularProgressIndicator());
    if (c.clips.isEmpty) {
      return _EmptyView(
        key: const ValueKey('recordings.empty'),
        text: switch (c.type) {
          'sentry' => l10n.recording_lib_no_recordings_sentry,
          'normal' => l10n.recording_lib_no_recordings_normal,
          'proximity' => l10n.recording_lib_no_recordings_proximity,
          _ => l10n.recording_lib_no_recordings,
        },
      );
    }
    return _ClipList(
      controller: c,
      jwt: _jwt,
      playingFilename: split ? _selected?.filename : null,
      onTapItem: (item) => split ? _selectForPane(item) : _openPlayer(context, item),
    );
  }

  void _openPlayer(BuildContext context, RecordingItem item) {
    final clips = widget.controller.clips;
    final index = clips.indexWhere((r) => r.filename == item.filename);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordingsPlayerScreen(
          controller: RecordingsPlayerController(
            recordingsService: widget.recordingsService,
            playlist: clips,
            initialIndex: index < 0 ? 0 : index,
          ),
          jwtSource: widget.jwtSource,
        ),
      ),
    );
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

String _formatBytes(int bytes) {
  if (bytes >= 1000000000) return '${(bytes / 1000000000).toStringAsFixed(1)} GB';
  if (bytes >= 1000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
  if (bytes >= 1000) return '${(bytes / 1000).toStringAsFixed(1)} KB';
  return '$bytes B';
}

/// Title, totals and Settings; then the companion's filters and select bar, full width so the
/// list and the player below keep all the height they can.
class _Header extends StatelessWidget {
  final RecordingsController controller;
  final VoidCallback onOpenSettings;
  const _Header({required this.controller, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = controller;
    final stats = c.stats;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.recordings_title, style: theme.textTheme.headlineSmall)),
              Text(
                stats == null
                    ? l10n.recordings_summary_pending
                    : '${l10n.recording_lib_clip_count(stats.totalCount)} · ${_formatBytes(stats.totalBytes)}',
                key: const ValueKey('recordings.stats'),
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
          const SizedBox(height: 8),
          // Wrap, not Row: several locales are much longer than English, and at some width the
          // groups stop fitting on one line. Wrapping is the graceful worst case, not an overflow.
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TypeChips(controller: c),
              _DayRow(controller: c),
              if (c.type == 'sentry') _WhoSeverityChips(controller: c),
              _SelectBar(controller: c),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  final RecordingsController controller;
  const _TypeChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      '': l10n.recording_lib_type_all,
      'normal': l10n.recording_lib_chip_type_normal,
      'sentry': l10n.recordings_segment_surveillance,
      'proximity': l10n.recording_lib_chip_type_proximity,
    };
    return Wrap(spacing: 8, children: [
      for (final t in RecordingsController.types)
        ChoiceChip(
          key: ValueKey('recordings.type.$t'),
          label: Text(labels[t]!),
          selected: controller.type == t,
          onSelected: (_) => controller.setType(t),
        ),
    ]);
  }
}

class _DayRow extends StatelessWidget {
  final RecordingsController controller;
  const _DayRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final day = c.day;
    final previous = c.step(-1);
    final next = c.step(1);
    return Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      ChoiceChip(
        key: const ValueKey('recordings.day.today'),
        label: Text(l10n.recording_lib_date_today),
        selected: day == c.todayKey,
        onSelected: (_) => c.setDay(c.todayKey),
      ),
      ChoiceChip(
        key: const ValueKey('recordings.day.yesterday'),
        label: Text(l10n.recording_lib_date_yesterday),
        selected: day == c.yesterdayKey,
        onSelected: (_) => c.setDay(c.yesterdayKey),
      ),
      ChoiceChip(
        key: const ValueKey('recordings.day.all'),
        label: Text(l10n.recording_lib_date_all_days),
        selected: day == null,
        onSelected: (_) => c.setDay(null),
      ),
      if (day != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            key: const ValueKey('recordings.day.previous'),
            tooltip: l10n.cd_previous_day,
            onPressed: previous == null ? null : () => c.setDay(previous),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(DateTime.parse(day)),
            key: const ValueKey('recordings.day.label'),
          ),
          IconButton(
            key: const ValueKey('recordings.day.next'),
            tooltip: l10n.cd_next_day,
            onPressed: next == null ? null : () => c.setDay(next),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
    ]);
  }
}

/// Who was seen and how bad, for sentry clips; the car filters, so paging stays right.
class _WhoSeverityChips extends StatelessWidget {
  final RecordingsController controller;
  const _WhoSeverityChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final names = {
      'person': l10n.recording_lib_chip_person,
      'vehicle': l10n.recording_lib_chip_vehicle,
      'bike': l10n.recording_lib_chip_bike,
      'animal': l10n.recording_lib_chip_animal,
      'ALERT': l10n.recording_lib_chip_alert,
      'CRITICAL': l10n.recording_lib_chip_critical,
    };
    Widget chip(String v, bool selected, void Function(String) toggle) => FilterChip(
          key: ValueKey('recordings.filter.$v'),
          label: Text(names[v]!),
          selected: selected,
          onSelected: (_) => toggle(v),
        );
    final label = Theme.of(context).textTheme.labelMedium;
    return Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(l10n.recording_lib_filter_section_what, style: label),
      for (final v in RecordingsController.actorClasses) chip(v, c.actors.contains(v), c.toggleActor),
      const SizedBox(width: 8),
      Text(l10n.recording_lib_filter_section_severity, style: label),
      for (final v in RecordingsController.severityLevels) chip(v, c.severities.contains(v), c.toggleSeverity),
      if (c.actors.isNotEmpty || c.severities.isNotEmpty)
        ActionChip(
          key: const ValueKey('recordings.filter.reset'),
          label: Text(l10n.recording_lib_filter_reset),
          onPressed: c.resetWhoAndSeverity,
        ),
    ]);
  }
}

class _SelectBar extends StatelessWidget {
  final RecordingsController controller;
  const _SelectBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    if (!c.selectMode) {
      if (c.clips.isEmpty) return const SizedBox.shrink();
      return TextButton(key: const ValueKey('recordings.select'), onPressed: c.enterSelectMode, child: Text(l10n.action_select));
    }
    return Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(l10n.recording_lib_selected_count(c.selected.length), key: const ValueKey('recordings.select.count')),
      TextButton(
        key: const ValueKey('recordings.select.all'),
        onPressed: c.toggleSelectAll,
        child: Text(c.allSelected ? l10n.action_deselect_all : l10n.action_select_all),
      ),
      FilledButton.tonal(
        key: const ValueKey('recordings.select.delete'),
        onPressed: c.selected.isEmpty ? null : () => _confirmBatchDelete(context, c),
        child: Text(l10n.action_delete),
      ),
      TextButton(key: const ValueKey('recordings.select.cancel'), onPressed: c.exitSelectMode, child: Text(l10n.action_cancel)),
    ]);
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

/// The loaded clips, one row each; the next page is fetched when the end of the list is built,
/// and a later page that failed leaves a retry row there.
class _ClipList extends StatelessWidget {
  final RecordingsController controller;
  final String? jwt;
  final ValueChanged<RecordingItem> onTapItem;

  /// Which clip the detail pane is showing, so the list can mark it. Null in
  /// the narrow layout, where there is no pane to be in sync with.
  final String? playingFilename;

  const _ClipList({required this.controller, required this.jwt, required this.onTapItem, required this.playingFilename});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = controller;
    final clips = c.clips;
    final footer = !c.done;
    return ListView.builder(
      key: const ValueKey('recordings.list'),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: clips.length + (footer ? 1 : 0),
      itemBuilder: (context, i) {
        if (i < clips.length) {
          final item = clips[i];
          return _ClipRow(
            key: ValueKey('recordings.row.${item.filename}'),
            controller: c,
            item: item,
            jwt: jwt,
            playing: playingFilename == item.filename,
            onTap: () => onTapItem(item),
          );
        }
        if (c.pageFailed) {
          return Center(
            child: TextButton(key: const ValueKey('recordings.more.retry'), onPressed: c.more, child: Text(l10n.action_retry)),
          );
        }
        // The end of the list came into view: ask for the next page after this frame.
        if (!c.loading) WidgetsBinding.instance.addPostFrameCallback((_) => c.more());
        return const Padding(
          key: ValueKey('recordings.more.loading'),
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// One clip, as the companion's ClipTile shows it: thumbnail, when, type, length, size, and
/// what was seen; delete, or a tick box while selecting.
class _ClipRow extends StatelessWidget {
  final RecordingsController controller;
  final RecordingItem item;
  final String? jwt;
  final VoidCallback onTap;

  /// True when this clip is the one in the detail pane.
  final bool playing;

  const _ClipRow({super.key, required this.controller, required this.item, required this.jwt, required this.onTap, this.playing = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = controller;
    final jwt = this.jwt;
    final locale = Localizations.localeOf(context).toString();
    final type = switch (item.kind) {
      RecordingKind.sentry => l10n.recordings_segment_surveillance,
      RecordingKind.proximity => l10n.recording_lib_chip_type_proximity,
      RecordingKind.normal => l10n.recording_lib_chip_type_normal,
    };
    final seen = item.detectedClasses.isEmpty ? '' : ' · ${item.detectedClasses.join(', ')}';
    return ListTile(
      selected: playing,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 128,
          height: 72,
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            // Not Image.network: the daemon answers an uncached thumbnail with 202 +
            // Retry-After while it generates one. See thumbnail_image.dart.
            child: jwt == null ? null : ThumbnailImage(filename: item.filename, jwt: jwt),
          ),
        ),
      ),
      title: Text(
        DateFormat.yMMMd(locale).add_jm().format(DateTime.fromMillisecondsSinceEpoch(item.timestampMs)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$type · ${item.formattedDuration} · ${item.formattedSize}$seen',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: c.selectMode
          ? Checkbox(
              key: ValueKey('recordings.check.${item.filename}'),
              value: c.selected.contains(item.filename),
              onChanged: (_) => c.toggleSelected(item.filename),
            )
          : IconButton(
              key: ValueKey('recordings.delete.${item.filename}'),
              tooltip: l10n.cd_delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, c, item),
            ),
      onTap: c.selectMode ? () => c.toggleSelected(item.filename) : onTap,
      onLongPress: () {
        if (!c.selectMode) c.enterSelectMode();
        c.toggleSelected(item.filename);
      },
    );
  }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? l10n.toast_recording_deleted : l10n.toast_recording_delete_failed)));
  }
}
