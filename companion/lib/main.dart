import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'car/car_store.dart';
import 'i18n.dart';
import 'screens/pairing/qr_scan_page.dart';

/// The BladeWatch companion: reach the car from a phone or desktop, over Pear from anywhere or
/// directly over the LAN when on the same network (epic BladeWatch-rdtj).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final store = CarStore(File('${(await getApplicationSupportDirectory()).path}/companion.json'));
  await store.load();
  runApp(CompanionApp(
    store: store,
    loadTr: (lang) => Tr.load(rootBundle, lang),
    // mobile_scanner has a camera path on these three only; the others paste the code's text.
    scan: Platform.isAndroid || Platform.isIOS || Platform.isMacOS ? scanPairingQr : null,
  ));
}
