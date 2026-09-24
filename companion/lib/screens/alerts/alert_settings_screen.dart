import 'dart:convert';

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/services/notifications_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_store.dart';
import '../../i18n.dart';
import '../common/loader.dart';
import 'alerts_controller.dart';

/// The web notifications page's counterpart. There are no push subscriptions to manage -- the
/// car keeps its alerts and this app collects them when it connects (store and forward,
/// BladeWatch-rdtj.14) -- so what is left is choosing which categories this device shows, and a
/// test alert that travels the whole path from the car's own notification bus.
class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key, required this.alerts, required this.store});

  final AlertsController alerts;
  final CarStore store;

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

/// The registry's categories (GetCategories.categories_json), as `(id, label, group)`.
List<({String id, String label, String group})> parseCategories(String json) {
  try {
    final d = jsonDecode(json) as Map<String, dynamic>;
    return [
      for (final c in (d['categories'] as List? ?? const []).cast<Map<String, dynamic>>())
        (id: c['id'] as String, label: (c['label'] as String?) ?? c['id'] as String, group: (c['group'] as String?) ?? ''),
    ];
  } catch (_) {
    return const [];
  }
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> with LoadersState {
  late final _categories = loader(() => NotificationsServiceClient(context.session.rpc).getCategories(GetCategoriesRequest()));

  Future<void> _mute(String id, bool shown) async {
    setState(() => shown ? widget.store.mutedCategories.remove(id) : widget.store.mutedCategories.add(id));
    widget.alerts.refilter();
    await widget.store.save();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _categories,
      builder: (context, r) {
        final cats = parseCategories(r.categoriesJson);
        return PageList(children: [
          Section(title: tr('companion.alerts'), children: [
            Text(tr('companion.alerts_how')),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('alerts.test'),
              onPressed: () => act(context, widget.alerts.sendTest, done: tr('companion.alerts_test_sent'), failed: tr('errors.generic')),
              child: Text(tr('notif.test_btn')),
            ),
          ]),
          Section(title: tr('notif.categories'), children: [
            Text(tr('companion.alerts_categories')),
            for (final c in cats)
              SwitchListTile(
                key: ValueKey('alerts.cat.${c.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(c.label),
                subtitle: c.group.isEmpty ? null : Text(c.group),
                value: !widget.store.mutedCategories.contains(c.id),
                onChanged: (shown) => _mute(c.id, shown),
              ),
          ]),
        ]);
      },
    );
  }
}
