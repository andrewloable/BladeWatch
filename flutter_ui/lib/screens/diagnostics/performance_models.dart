/// Mirrors `PerformanceController.kt`'s `renderData(JSONObject)` — one
/// section per top-level key in the daemon's `/api/performance` JSON, each
/// independently optional (a section simply isn't rendered when absent, the
/// same as native's `data.optJSONObject("cpu")` etc.).
class PerformanceSnapshot {
  final CpuMetrics? cpu;
  final MemoryMetrics? memory;
  final GpuMetrics? gpu;
  final AppProcessMetrics? app;

  const PerformanceSnapshot({this.cpu, this.memory, this.gpu, this.app});

  bool get isEmpty => cpu == null && memory == null && gpu == null && app == null;
}

class CpuMetrics {
  final double systemUsagePercent;
  final double appUsagePercent;
  final int freqMhz;
  final double tempC;

  const CpuMetrics({required this.systemUsagePercent, required this.appUsagePercent, required this.freqMhz, required this.tempC});
}

class MemoryMetrics {
  final double usagePercent;
  final double totalMb;
  final double usedMb;
  final double appMb;

  const MemoryMetrics({required this.usagePercent, required this.totalMb, required this.usedMb, required this.appMb});
}

class GpuMetrics {
  final double usagePercent;
  final int freqMhz;
  final double tempC;

  const GpuMetrics({required this.usagePercent, required this.freqMhz, required this.tempC});
}

class AppProcessMetrics {
  final int threadCount;
  final int gcCount;
  final int openFds;

  const AppProcessMetrics({required this.threadCount, required this.gcCount, required this.openFds});
}
