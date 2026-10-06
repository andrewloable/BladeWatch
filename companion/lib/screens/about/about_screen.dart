import 'dart:io';

import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/loader.dart';

/// Versions on both ends, and the licences of what this app is built from.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, this.appVersion, this.buildNumber});

  /// Test seams; by default read from the platform.
  final Future<String> Function()? appVersion;
  final Future<String> Function()? buildNumber;

  /// This device's OS, as its owner knows it.
  static String platformName(String os) =>
      const {'android': 'Android', 'ios': 'iOS', 'macos': 'macOS', 'windows': 'Windows', 'linux': 'Linux'}[os] ?? os;

  /// The car apps' four-part version (1.4.1.3) on every platform. pub only allows three parts, so
  /// a platform that reads the version from pubspec -- Linux, through version.json -- reports
  /// 1.4.1 with build 14103. The build number encodes all four (major * 10000 + minor * 1000 +
  /// patch * 100 + fourth), so the fourth part comes back from it. Anything else is shown as is.
  static String displayVersion(String version, String build) {
    final parts = version.split('.').map(int.tryParse).toList();
    final number = int.tryParse(build);
    if (parts.length != 3 || parts.contains(null) || number == null) return version;
    final fourth = number - (parts[0]! * 10000 + parts[1]! * 1000 + parts[2]! * 100);
    return fourth >= 0 && fourth < 100 ? '$version.$fourth' : version;
  }

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with LoadersState {
  late final _system = SystemServiceClient(context.session.rpc);
  late final _data = loader(() async => (
        app: await (widget.appVersion ?? () async => (await PackageInfo.fromPlatform()).version)(),
        // Extra, not essential: a platform that cannot say leaves the row out, not the page.
        build: await (widget.buildNumber ?? () async => (await PackageInfo.fromPlatform()).buildNumber)().catchError((Object _) => ''),
        car: await _system.getStatus(GetStatusRequest()),
      ));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _data,
      builder: (context, v) => PageList(children: [
        Section(title: 'BladeWatch', children: [
          InfoRow(tr('companion.app_version'), AboutScreen.displayVersion(v.app, v.build)),
          // The web About's platform and build (BladeWatch-rdtj.57), for a bug report.
          if (v.build.isNotEmpty) InfoRow(tr('companion.build'), v.build),
          InfoRow(tr('companion.platform'), AboutScreen.platformName(Platform.operatingSystem)),
          InfoRow(tr('companion.car_version'), v.car.appVersion.isEmpty ? '—' : v.car.appVersion),
          InfoRow(tr('dashboard.device_id'), v.car.deviceId),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('about.licenses'),
            onPressed: () => showLicensePage(context: context, applicationName: 'BladeWatch', applicationVersion: v.app),
            child: Text(tr('companion.licenses')),
          ),
        ]),
        Section(title: tr('companion.privacy'), children: [Text(tr('companion.privacy_note'), key: const ValueKey('about.privacy'))]),
      ]),
    );
  }
}
