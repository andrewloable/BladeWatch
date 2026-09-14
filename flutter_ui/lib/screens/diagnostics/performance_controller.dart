import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';

import 'performance_models.dart';
import '../../shell/disposed_safe_notifier.dart';

enum PerformanceViewState { connecting, ready }

/// Controller behind the Performance dashboard — BladeWatch-yz1e.4. Ground
/// truth: `app/src/main/java/com/loabletech/bladewatch/ui/fragment/performance/PerformanceController.kt`.
///
/// Deliberate transport split, not a simplification of native's own
/// behaviour: [poll] uses the typed [SystemServiceClient.getPerformance] RPC
/// (which wraps the same `GET /api/performance` handler natively hits with
/// raw `HttpURLConnection`) since that RPC already exists — no reason to
/// duplicate a second raw-HTTP GET path when a typed one is available. But
/// [connect]/[disconnect]/the per-poll heartbeat have NO RPC equivalent
/// (`PerformanceApiHandler`'s "SOTA on-demand" `/connect`/`/heartbeat`/
/// `/disconnect` client-registration endpoints are plain REST, not wrapped
/// by any `SystemService` RPC) — skipping them is not an option: without a
/// registered client, `PerformanceMonitor.clientConnected()` never fires,
/// `isRunning()` stays false, and every poll would return the "no_data"
/// wrapper forever (verified by reading `PerformanceMonitor.java` directly,
/// not assumed) — so those 3 calls go over raw HTTP via [RawHttpSender],
/// same as native, with a JWT from [JwtSource] exactly like [ConnectClient]
/// mints one.
///
/// The 3-second poll timer itself is owned by the screen widget, not this
/// controller — same convention as every other periodic-refresh screen in
/// this port.
class PerformanceController extends ChangeNotifier with DisposedSafeNotifier {
  final SystemServiceClient _systemService;
  final JwtSource _jwtSource;
  final RawHttpSender _send;
  final Uri _baseUrl;

  PerformanceController({
    required SystemServiceClient systemService,
    required JwtSource jwtSource,
    RawHttpSender? send,
    Uri? baseUrl,
  })  : _systemService = systemService, // ignore: prefer_initializing_formals
        _jwtSource = jwtSource, // ignore: prefer_initializing_formals
        _send = send ?? createIoHttpSender(),
        _baseUrl = baseUrl ?? Uri.parse('http://127.0.0.1:8080');

  PerformanceViewState _state = PerformanceViewState.connecting;
  PerformanceViewState get state => _state;

  PerformanceSnapshot? _snapshot;
  PerformanceSnapshot? get snapshot => _snapshot;

  String? _clientId;

  Future<void> connect() async {
    final response = await _postJson('/api/performance/connect', {
      'clientId': 'bladewatch-flutter-${DateTime.now().millisecondsSinceEpoch}',
    });
    final id = response?['clientId'];
    if (id is String && id.isNotEmpty) _clientId = id;
  }

  Future<void> poll() async {
    final GetPerformanceResponse response;
    try {
      response = await _systemService.getPerformance(GetPerformanceRequest());
    } catch (_) {
      return;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.performanceJson) as Map<String, dynamic>;
    } catch (_) {
      data = const {};
    }

    _snapshot = PerformanceSnapshot(
      cpu: _cpuFrom(data['cpu']),
      memory: _memoryFrom(data['memory']),
      gpu: _gpuFrom(data['gpu']),
      app: _appFrom(data['app']),
    );
    _state = PerformanceViewState.ready;
    notifyListeners();

    final id = _clientId;
    if (id != null) {
      await _postJson('/api/performance/heartbeat', {'clientId': id});
    }
  }

  Future<void> disconnect() async {
    final id = _clientId;
    if (id == null) return;
    await _postJson('/api/performance/disconnect', {'clientId': id});
    _clientId = null;
  }

  Future<Map<String, dynamic>?> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final jwt = await _jwtSource.mintJwt();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (jwt != null) 'Authorization': 'Bearer $jwt',
      };
      final response = await _send(_baseUrl.replace(path: path), headers, jsonEncode(body));
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.isEmpty) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static CpuMetrics? _cpuFrom(Object? json) {
    if (json is! Map) return null;
    return CpuMetrics(
      systemUsagePercent: _num(json['system']),
      appUsagePercent: _num(json['app']),
      freqMhz: _num(json['freqMhz']).toInt(),
      tempC: _num(json['tempC']),
    );
  }

  static MemoryMetrics? _memoryFrom(Object? json) {
    if (json is! Map) return null;
    return MemoryMetrics(
      usagePercent: _num(json['usagePercent']),
      totalMb: _num(json['totalMb']),
      usedMb: _num(json['usedMb']),
      appMb: _num(json['appMb']),
    );
  }

  static GpuMetrics? _gpuFrom(Object? json) {
    if (json is! Map) return null;
    return GpuMetrics(
      usagePercent: _num(json['usage']),
      freqMhz: _num(json['freqMhz']).toInt(),
      tempC: _num(json['tempC']),
    );
  }

  static AppProcessMetrics? _appFrom(Object? json) {
    if (json is! Map) return null;
    return AppProcessMetrics(
      threadCount: _num(json['threadCount']).toInt(),
      gcCount: _num(json['gcCount']).toInt(),
      openFds: _num(json['openFds']).toInt(),
    );
  }

  static double _num(Object? value) => (value is num) ? value.toDouble() : 0.0;
}
