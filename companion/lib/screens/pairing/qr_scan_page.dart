import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../i18n.dart';

/// Opens the camera and resolves to the first QR's text, or null when closed.
Future<String?> scanPairingQr(BuildContext context) {
  final tr = context.tr;
  return Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => TrScope(tr: tr, child: const QrScanPage())));
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key, this.scanner});

  /// Test seam: the camera view, given the callback it reports a code to.
  final Widget Function(void Function(String text) onCode)? scanner;

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  // A camera reports the same code many times a second: only the first one counts.
  void _onCode(String text) {
    if (_done) return;
    _done = true;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('companion.pair_scan'))),
        body: widget.scanner?.call(_onCode) ??
            MobileScanner(
              onDetect: (capture) {
                final text = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                if (text != null) _onCode(text);
              },
            ),
      );
}
