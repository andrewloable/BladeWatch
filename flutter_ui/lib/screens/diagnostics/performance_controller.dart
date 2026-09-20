import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';

import 'performance_models.dart';
import '../../shell/disposed_safe_notifier.dart';

enum PerformanceViewState { connecting, ready }

/// Controller behind the Performance dashboard — BladeWatch-yz1e.4. Ground
/// truth: `app/src/main/java/com/loabletech/bladewatch/ui/fragment/performance/PerformanceController.kt`.
///
/// Every call goes over ConnectRPC. This used to be a deliberate transport
/// split: [connect]/[disconnect]/the per-poll heartbeat had no RPC equivalent
/// and went over raw HTTP to `PerformanceApiHandler`'s REST endpoints, while
/// [poll] used the typed RPC. BladeWatch-qwqq added
/// `PerformanceConnect`/`PerformanceHeartbeat`/`PerformanceDisconnect`, so the
/// split is gone.
///
/// Skipping the session calls is still not an option: without a registered
/// client, `PerformanceMonitor.clientConnected()` never fires, `isRunning()`
/// stays false, and every poll returns the "no_data" wrapper forever.
///
/// The 3-second poll timer itself is owned by the screen widget, not this
/// controller — same convention as every other periodic-refresh screen in
/// this port.
class PerformanceController extends ChangeNotifier with DisposedSafeNotifier {
  final SystemServiceClient _systemService;

  // jwtSource / send / baseUrl used to be required here for the raw-HTTP REST calls
  // (BladeWatch-qwqq). Every call now goes through SystemServiceClient, which mints its own
  // JWT and owns the transport, so they are gone rather than kept as dead parameters.
  PerformanceController({
    required SystemServiceClient systemService,
  }) : _systemService = systemService; // ignore: prefer_initializing_formals

  PerformanceViewState _state = PerformanceViewState.connecting;
  PerformanceViewState get state => _state;

  PerformanceSnapshot? _snapshot;
  PerformanceSnapshot? get snapshot => _snapshot;

  String? _clientId;

  Future<void> connect() async {
    try {
      final response = await _systemService.performanceConnect(
        PerformanceConnectRequest(
          clientId: 'bladewatch-flutter-${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      // Keep the id the SERVER registered, not the one we asked for — heartbeats
      // that do not match it would let the session time out under an open panel.
      if (response.clientId.isNotEmpty) _clientId = response.clientId;
    } catch (_) {
      // Best-effort: a failed registration must not break the screen.
    }
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
      try {
        await _systemService.performanceHeartbeat(
          PerformanceHeartbeatRequest(clientId: id),
        );
      } catch (_) {
        // A missed heartbeat is recoverable: the next poll sends another.
      }
    }
  }

  Future<void> disconnect() async {
    final id = _clientId;
    if (id == null) return;
    try {
      await _systemService.performanceDisconnect(
        PerformanceDisconnectRequest(clientId: id),
      );
    } catch (_) {
      // The monitor times the session out on its own if this never lands.
    }
    _clientId = null;
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
