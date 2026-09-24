import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/loader.dart';

/// Versions on both ends, and the licences of what this app is built from.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, this.appVersion});

  /// Test seam; by default read from the platform.
  final Future<String> Function()? appVersion;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with LoadersState {
  late final _system = SystemServiceClient(context.session.rpc);
  late final _data = loader(() async => (
        app: await (widget.appVersion ?? () async => (await PackageInfo.fromPlatform()).version)(),
        car: await _system.getStatus(GetStatusRequest()),
      ));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _data,
      builder: (context, v) => PageList(children: [
        Section(title: 'BladeWatch', children: [
          InfoRow(tr('companion.app_version'), v.app),
          InfoRow(tr('companion.car_version'), v.car.appVersion.isEmpty ? '—' : v.car.appVersion),
          InfoRow(tr('dashboard.device_id'), v.car.deviceId),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('about.licenses'),
            onPressed: () => showLicensePage(context: context, applicationName: 'BladeWatch', applicationVersion: v.app),
            child: Text(tr('companion.licenses')),
          ),
        ]),
      ]),
    );
  }
}
