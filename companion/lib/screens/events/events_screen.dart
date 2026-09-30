import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_theme/color_tokens.dart';
import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../alerts/alerts_controller.dart';
import '../common/format.dart';
import '../common/loader.dart';
import '../recordings/clip_pages.dart';
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
      // As wide as a page's content, not the window (BladeWatch-rdtj.56).
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: BwDimens.pagePaddingHorizontal), child: ContentWidth(child: Column(children: [
        // BladeWatch-rdtj.72.2, found on a real phone: TabBar splits its width equally across
        // the 3 tabs regardless of label length, and `Tab(text: ...)`'s label has no
        // overflow/maxLines control -- "Surveillance" (12 characters, the longest of these
        // three labels in every one of the 17 languages checked) was hard-clipped mid-word to
        // "Surveillanc", no ellipsis, on a 412dp-wide phone. `Tab(child:)` takes an arbitrary
        // widget in place of the bare string, so a Text with overflow handling degrades to an
        // ellipsis on a device too narrow for the label whole, instead of a broken clip.
        TabBar(tabs: [
          Tab(child: Text(tr('companion.alerts'), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Tab(child: Text(tr('events.badge_sentry'), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Tab(child: Text(tr('events.badge_proximity'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        Expanded(
          child: TabBarView(children: [
            _Alerts(alerts: alerts),
            const _Clips(type: 'sentry', key: ValueKey('events.sentry')),
            const _Clips(type: 'proximity', key: ValueKey('events.proximity')),
          ]),
        ),
      ]))),
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
                  Padding(padding: const EdgeInsets.all(32), child: HudEmptyState(icon: Icons.notifications_none, message: tr('companion.alerts_empty'))),
                ])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, BwDimens.pagePaddingBottom),
                  children: [
                    for (final e in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        // A row that arrived since the list was last seen is the accent-bordered one (its state is real:
                        // it is in `_shownNew`); the rest are plain. The title is bold either way, as every HUD row's is.
                        child: HudListRow(
                          key: ValueKey('alert.${e.id}'),
                          leading: Icon(
                            switch (e.severity) {
                              NotificationSeverity.NOTIFICATION_SEVERITY_CRITICAL => Icons.error,
                              NotificationSeverity.NOTIFICATION_SEVERITY_ALERT => Icons.warning_amber,
                              _ => Icons.info_outline,
                            },
                            size: 20,
                            color: switch (e.severity) {
                              NotificationSeverity.NOTIFICATION_SEVERITY_CRITICAL => colors.danger,
                              NotificationSeverity.NOTIFICATION_SEVERITY_ALERT => colors.warning,
                              _ => colors.info,
                            },
                          ),
                          title: e.title,
                          subtitle: '${e.body}${e.body.isEmpty ? '' : '\n'}${Fmt.dateTime(e.timestampMs, tr.lang)}',
                          selected: _shownNew.contains(e.id.toInt()),
                          trailing: clipOf(e) == null ? null : const Icon(Icons.play_circle_outline, size: 20),
                          onTap: clipOf(e) == null ? null : () => openClip(context, clipOf(e)!),
                        ),
                      ),
                  ],
                ),
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

class _ClipsState extends State<_Clips> {
  // A page at a time, like the Recordings page (BladeWatch-rdtj.42): 200 in one request left the
  // rest out of reach.
  late final _pages = ClipPages((page, size) => RecordingsServiceClient(context.session.rpc)
      .listRecordings(ListRecordingsRequest(type: widget.type, page: page, pageSize: size)))
    ..more();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipPageList(pages: _pages);
}
