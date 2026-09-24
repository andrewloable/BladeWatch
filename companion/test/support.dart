import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/car/car_page.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// English, from the real catalog: a test that finds `tr('x')` text proves the key exists.
final Tr testTr = Tr.english(jsonDecode(File('assets/i18n/en.json').readAsStringSync()) as Map<String, Object?>);

String t(String key, [Map<String, Object?> params = const {}]) => testTr(key, params);

/// A session over [rpc] whose phase the test drives.
class TestSession {
  TestSession({TransportPhase phase = TransportPhase.lan, FakeRpcClient? rpc, Uri? baseUrl}) : rpc = rpc ?? FakeRpcClient() {
    session = CarSession(
      rpc: this.rpc,
      baseUrl: baseUrl ?? Uri.parse('http://127.0.0.1:9'),
      jwt: () async => 'jwt',
      phases: phases.stream,
      initialPhase: phase,
      retry: () => retries++,
      headerTransport: (headers) {
        headerCalls.add(headers);
        return this.rpc;
      },
    );
  }

  final FakeRpcClient rpc;
  final phases = StreamController<TransportPhase>.broadcast();
  late final CarSession session;
  var retries = 0;
  final headerCalls = <Map<String, String>>[];

  Future<void> go(WidgetTester tester, TransportPhase p) async {
    phases.add(p);
    await tester.pump();
  }
}

PairedCar testCar({String cursor = '0'}) => PairedCar.fromJson({
      'deviceId': 'dev-1',
      'pearTopic': 'a' * 64,
      'tlsFingerprint': 'b' * 64,
      'probeKey': 'c' * 64,
      'companionId': 'cid',
      'token': 'tok',
      'inboxCursor': cursor,
    });

CarStore testStore({PairedCar? car}) {
  final dir = Directory.systemTemp.createTempSync('companion-store');
  return CarStore(File('${dir.path}/companion.json'))..car = car;
}

const testCredential = CompanionCredential('cid', 'tok');

/// [child] as a screen of the app: theme, strings, session, a scaffold for snackbars.
Future<void> pumpScreen(WidgetTester tester, TestSession s, Widget child, {Size size = const Size(420, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Strings above the Navigator (as CompanionApp does), so dialogs and pushed routes see them;
  // the session inside the page only, as HomeShell has it.
  await tester.pumpWidget(MaterialApp(
    theme: BladeWatchTheme.light(),
    builder: (context, nav) => TrScope(tr: testTr, child: nav!),
    home: SessionScope(session: s.session, child: Scaffold(body: child)),
  ));
  await tester.pump();
  await tester.pump();
}

/// Unmounts the screen so its timers are cancelled before the test ends.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

// A 1x1 transparent PNG: the smallest thing Image.memory will decode.
final testPng = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, //
  13, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]);

/// [testPng] as proto3 JSON writes `bytes`.
final String base64Png = base64Encode(testPng);
