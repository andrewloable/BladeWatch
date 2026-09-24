import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/loader.dart';

/// The head unit's CPU, memory and GPU, polled every 3 s -- the web performance page's
/// counterpart. The car only measures while a client holds a session (PerformanceConnect, then
/// a heartbeat inside its 10 s timeout), so this screen holds one for as long as it is open.
class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with LoadersState {
  late final _system = SystemServiceClient(context.session.rpc);
  final _clientId = 'companion-${Random().nextInt(1 << 31)}';
  late final _perf = loader(() => _system.getPerformance(GetPerformanceRequest()), poll: const Duration(seconds: 3));
  Timer? _heartbeat;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_system.performanceConnect(PerformanceConnectRequest(clientId: _clientId)).catchError((_) => PerformanceConnectResponse()));
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_system.performanceHeartbeat(PerformanceHeartbeatRequest(clientId: _clientId)).catchError((_) => PerformanceHeartbeatResponse()));
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    unawaited(_system.performanceDisconnect(PerformanceDisconnectRequest(clientId: _clientId)).catchError((_) => PerformanceDisconnectResponse()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _perf,
      builder: (context, r) {
        Map<String, dynamic> d;
        try {
          d = jsonDecode(r.performanceJson) as Map<String, dynamic>;
        } catch (_) {
          d = const {};
        }
        String n(String group, String key, {int digits = 0, String unit = ''}) {
          final v = (d[group] as Map<String, dynamic>?)?[key];
          return v is num ? '${v.toStringAsFixed(digits)}$unit' : '—';
        }

        return PageList(children: [
          Section(title: 'CPU', children: [
            InfoRow(tr('companion.perf_system'), n('cpu', 'system', digits: 1, unit: '%')),
            InfoRow(tr('companion.perf_app'), n('cpu', 'app', digits: 1, unit: '%')),
            InfoRow(tr('companion.perf_freq'), n('cpu', 'freqMhz', unit: ' MHz')),
            InfoRow(tr('companion.perf_temp'), n('cpu', 'tempC', digits: 1, unit: ' °C')),
          ]),
          Section(title: tr('companion.perf_memory'), children: [
            InfoRow(tr('companion.perf_used'), '${n('memory', 'usedMb')} / ${n('memory', 'totalMb', unit: ' MB')}'),
            InfoRow(tr('companion.perf_app'), n('memory', 'appTotalMb', unit: ' MB')),
          ]),
          Section(title: 'GPU', children: [
            InfoRow(tr('companion.perf_usage'), n('gpu', 'usage', digits: 1, unit: '%')),
            InfoRow(tr('companion.perf_freq'), n('gpu', 'freqMhz', unit: ' MHz')),
            InfoRow(tr('companion.perf_temp'), n('gpu', 'tempC', digits: 1, unit: ' °C')),
          ]),
          OutlinedButton(
            key: const ValueKey('perf.audio'),
            onPressed: () => act(context, () => _system.playAudioTest(PlayAudioTestRequest(durationMs: 3000)),
                done: tr('companion.audio_test_sent'), failed: tr('errors.generic')),
            child: Text(tr('companion.audio_test')),
          ),
        ]);
      },
    );
  }
}
