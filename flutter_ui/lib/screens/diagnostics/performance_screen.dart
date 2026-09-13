import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'performance_controller.dart';
import 'performance_models.dart';

/// Ground truth: `PerformanceFragment.kt` + `PerformanceController.kt` (a
/// hand-rolled programmatic-View Kotlin controller, like Recording's — no
/// XML layout to port from). This screen owns the 3-second poll timer
/// (matching [PerformanceController]'s `scheduleAtFixedRate(0, 3, SECONDS)`)
/// and the connect/disconnect lifecycle around it.
class PerformanceScreen extends StatefulWidget {
  final PerformanceController controller;

  const PerformanceScreen({super.key, required this.controller});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _start();
  }

  Future<void> _start() async {
    await widget.controller.connect();
    await widget.controller.poll();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => widget.controller.poll());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChanged);
    unawaited(widget.controller.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    if (c.state == PerformanceViewState.connecting) {
      return Center(
        key: const ValueKey('perf.connecting'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.performance_connecting),
          ],
        ),
      );
    }

    final snapshot = c.snapshot!;
    return ListView(
      key: const ValueKey('perf.ready'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.performance_hero_title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        if (snapshot.cpu != null) _cpuCard(theme, l10n, snapshot.cpu!),
        if (snapshot.memory != null) _memoryCard(theme, l10n, snapshot.memory!),
        if (snapshot.gpu != null) _gpuCard(theme, l10n, snapshot.gpu!),
        if (snapshot.app != null) _appCard(theme, l10n, snapshot.app!),
        const SizedBox(height: 12),
        Center(
          child: Text(
            l10n.performance_refreshing_footer,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _card(ThemeData theme, {required String key, required String title, required List<Widget> children}) {
    return Card(
      key: ValueKey(key),
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _bar(ThemeData theme, String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text('${percent.toStringAsFixed(1)}%', style: theme.textTheme.labelMedium),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(ThemeData theme, List<(String, String)> pairs) {
    return Row(
      children: pairs
          .map((pair) => Expanded(
                child: Column(children: [
                  Text(pair.$2, style: theme.textTheme.titleMedium),
                  Text(pair.$1, style: theme.textTheme.labelMedium),
                ]),
              ))
          .toList(),
    );
  }

  String _temp(AppLocalizations l10n, double tempC) => tempC > 0 ? '${tempC.toStringAsFixed(1)}°C' : l10n.performance_temperature_na;

  Widget _cpuCard(ThemeData theme, AppLocalizations l10n, CpuMetrics cpu) {
    return _card(theme, key: 'perf.cpu', title: l10n.performance_cpu_title, children: [
      _bar(theme, l10n.performance_cpu_system_usage, cpu.systemUsagePercent, theme.colorScheme.primary),
      _bar(theme, l10n.performance_cpu_app_usage, cpu.appUsagePercent, theme.colorScheme.secondary),
      const SizedBox(height: 4),
      _grid(theme, [
        ('${cpu.freqMhz} MHz', l10n.performance_frequency_label),
        (_temp(l10n, cpu.tempC), l10n.performance_temperature_label),
      ]),
    ]);
  }

  Widget _memoryCard(ThemeData theme, AppLocalizations l10n, MemoryMetrics mem) {
    return _card(theme, key: 'perf.memory', title: l10n.performance_memory_title, children: [
      _bar(theme, l10n.performance_usage_label, mem.usagePercent, theme.colorScheme.tertiary),
      const SizedBox(height: 4),
      _grid(theme, [
        ('${mem.totalMb.toStringAsFixed(0)} MB', l10n.performance_memory_total),
        ('${mem.usedMb.toStringAsFixed(0)} MB', l10n.performance_memory_used),
        ('${mem.appMb.toStringAsFixed(1)} MB', l10n.performance_memory_app),
      ]),
    ]);
  }

  Widget _gpuCard(ThemeData theme, AppLocalizations l10n, GpuMetrics gpu) {
    return _card(theme, key: 'perf.gpu', title: l10n.performance_gpu_title, children: [
      _bar(theme, l10n.performance_usage_label, gpu.usagePercent, theme.colorScheme.error),
      const SizedBox(height: 4),
      _grid(theme, [
        ('${gpu.freqMhz} MHz', l10n.performance_frequency_label),
        (_temp(l10n, gpu.tempC), l10n.performance_temperature_label),
      ]),
    ]);
  }

  Widget _appCard(ThemeData theme, AppLocalizations l10n, AppProcessMetrics app) {
    return _card(theme, key: 'perf.app', title: l10n.performance_app_process_title, children: [
      _grid(theme, [
        ('${app.threadCount}', l10n.performance_threads_label),
        ('${app.gcCount}', l10n.performance_gc_cycles_label),
        ('${app.openFds}', l10n.performance_open_fds_label),
      ]),
    ]);
  }
}
