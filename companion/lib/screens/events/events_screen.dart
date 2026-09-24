import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_theme/color_tokens.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../alerts/alerts_controller.dart';
import '../common/format.dart';
import '../common/loader.dart';
import '../recordings/clips.dart';

/// What happened to the car: the alerts it kept for this companion (store and forward), and the
/// surveillance and proximity clips -- the web events page plus the alert inbox that replaces
/// Web Push.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key, required this.alerts});

  final AlertsController alerts;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [
          Tab(text: tr('companion.alerts')),
          Tab(text: tr('events.badge_sentry')),
          Tab(text: tr('events.badge_proximity')),
        ]),
        Expanded(
          child: TabBarView(children: [
            _Alerts(alerts: alerts),
            const _Clips(type: 'sentry', key: ValueKey('events.sentry')),
            const _Clips(type: 'proximity', key: ValueKey('events.proximity')),
          ]),
        ),
      ]),
    );
  }
}

class _Alerts extends StatefulWidget {
  const _Alerts({required this.alerts});

  final AlertsController alerts;

  @override
  State<_Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<_Alerts> {
  final _shownNew = <int>{};

  @override
  void initState() {
    super.initState();
    widget.alerts.addListener(_seen);
    _seen();
  }

  // What arrives while this list is on screen has been seen too: highlight it, then count it.
  void _seen() {
    final fresh = widget.alerts.entries.where(widget.alerts.isNew).map((e) => e.id.toInt());
    if (fresh.isEmpty) return;
    _shownNew.addAll(fresh);
    unawaited(widget.alerts.markSeen());
  }

  @override
  void dispose() {
    widget.alerts.removeListener(_seen);
    super.dispose();
  }

  static String? clipOf(InboxEntry e) => e.clickUrl.isEmpty ? null : Uri.tryParse(e.clickUrl)?.queryParameters['file'];

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = Theme.of(context).extension<BwStatusColors>()!;
    return ListenableBuilder(
      listenable: widget.alerts,
      builder: (context, _) {
        final list = widget.alerts.entries;
        return RefreshIndicator(
          onRefresh: widget.alerts.refresh,
          child: list.isEmpty
              ? ListView(children: [
                  Padding(padding: const EdgeInsets.all(32), child: Text(tr('companion.alerts_empty'), textAlign: TextAlign.center)),
                ])
              : ListView(children: [
                  for (final e in list)
                    ListTile(
                      key: ValueKey('alert.${e.id}'),
                      leading: Icon(
                        switch (e.severity) {
                          NotificationSeverity.NOTIFICATION_SEVERITY_CRITICAL => Icons.error,
                          NotificationSeverity.NOTIFICATION_SEVERITY_ALERT => Icons.warning_amber,
                          _ => Icons.info_outline,
                        },
                        color: switch (e.severity) {
                          NotificationSeverity.NOTIFICATION_SEVERITY_CRITICAL => colors.danger,
                          NotificationSeverity.NOTIFICATION_SEVERITY_ALERT => colors.warning,
                          _ => colors.info,
                        },
                      ),
                      title: Text(e.title, style: _shownNew.contains(e.id.toInt()) ? const TextStyle(fontWeight: FontWeight.bold) : null),
                      subtitle: Text('${e.body}${e.body.isEmpty ? '' : '\n'}${Fmt.dateTime(e.timestampMs, tr.lang)}'),
                      isThreeLine: e.body.isNotEmpty,
                      trailing: clipOf(e) == null ? null : const Icon(Icons.play_circle_outline),
                      onTap: clipOf(e) == null ? null : () => openClip(context, clipOf(e)!),
                    ),
                ]),
        );
      },
    );
  }
}

class _Clips extends StatefulWidget {
  const _Clips({super.key, required this.type});

  final String type;

  @override
  State<_Clips> createState() => _ClipsState();
}

class _ClipsState extends State<_Clips> with LoadersState {
  late final _list = loader(
    () => RecordingsServiceClient(context.session.rpc).listRecordings(ListRecordingsRequest(type: widget.type, pageSize: 200)),
  );

  @override
  Widget build(BuildContext context) => LoaderView(
        loader: _list,
        builder: (context, r) => r.recordings.isEmpty
            ? ListView(children: [
                Padding(padding: const EdgeInsets.all(32), child: Text(context.tr('events.empty_none_title'), textAlign: TextAlign.center)),
              ])
            : ListView(children: [for (final c in r.recordings) ClipTile(clip: c)]),
      );
}
