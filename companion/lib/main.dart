import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'car/car_store.dart';
import 'font_licence.dart';
import 'i18n.dart';
import 'screens/pairing/qr_scan_page.dart';
import 'screens/recordings/video_capability.dart';
import 'tv.dart';

/// The BladeWatch companion: reach the car from a phone or desktop, over Pear from anywhere or
/// directly over the LAN when on the same network (epic BladeWatch-rdtj).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicence();
  // BladeWatch-rdtj.73: started here, not when a clip is first opened, so the platform-channel
  // round-trip has finished long before anyone can tap a clip -- ClipPlayerScreen reads the
  // result synchronously and cannot itself wait on it (see video_capability.dart).
  VideoCapability.ensureStarted();
  await initializeDateFormatting();
  final store = CarStore(File('${(await getApplicationSupportDirectory()).path}/companion.json'));
  await store.load();
  final tv = await isAndroidTv();
  runApp(CompanionApp(
    store: store,
    loadTr: (lang) => Tr.load(rootBundle, lang),
    // Phones scan the car's QR; TVs and desktops pair by number over Wi-Fi instead, and can still
    // paste the code's text (the owner, 2026-10-04).
    scan: (Platform.isAndroid && !tv) || Platform.isIOS ? scanPairingQr : null,
    wifiPairing: tv || Platform.isMacOS || Platform.isWindows || Platform.isLinux,
    tv: tv,
  ));
}
