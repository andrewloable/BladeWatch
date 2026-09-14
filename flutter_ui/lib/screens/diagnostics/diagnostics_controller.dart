import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';

import 'diagnostics_models.dart';

/// Matches native's exact command string — see
/// `MainActivity.kt.checkTrafficMonitorStatus()`. `pm` exit codes vary by
/// Android build, so native pipes through `|| echo NOT_DISABLED` to force
/// success regardless of `grep`'s result.
const _trafficMonitorStatusCommand =
    'pm list packages -d 2>/dev/null | grep com.byd.trafficmonitor || echo NOT_DISABLED';

/// Controller behind the Diagnostics hub's 4 Health tiles — BladeWatch-yz1e.4.
/// Ground truth: `DiagnosticsFragment.kt`. Each tile's data source is
/// independent (a failure in one never blocks the others — [refresh] awaits
/// all 4 probes together but each swallows its own error into an honest
/// default, mirroring native's own per-tile `try { } catch (Throwable) { }`
/// defensiveness). ADB Console, Traffic Monitor, Camera probe, Battery
/// health and Performance are separate screens/dialogs
/// ([AdbConsoleController] etc.), not part of this controller.
///
/// [tunnelUrlSource] (BladeWatch-m1po) and [cameraConfigSource]
/// (BladeWatch-hygs) are the same class of injected, currently-unresolved
/// IPC gap as elsewhere in this port — both default to native's own
/// fallback values.
///
/// [tunnelState] simplifies native's 3-way daemon status (STOPPED/STARTING/
/// RUNNING) to what `DaemonChannel.processStatus()` actually reports
/// (running or not): "connecting" here means the tunnel daemon process is up
/// but hasn't minted a URL yet, not literally adbd's STARTING status value,
/// which this port has no channel to read.
class DiagnosticsController extends ChangeNotifier {
  final DaemonChannel _daemonChannel;
  final StorageServiceClient _storageService;
  final SystemServiceClient _systemService;
  final NetworkChannel _networkChannel;
  final SurveillanceServiceClient _surveillanceService;
  final AdbConnection Function() _adbConnectionFactory;
  final Future<String?> Function() _tunnelUrlSource;
  final Future<CameraProbeConfig> Function() _cameraConfigSource;
  final Future<int?> Function() _batterySocSource;

  DiagnosticsController({
    required DaemonChannel daemonChannel,
    required StorageServiceClient storageService,
    required SystemServiceClient systemService,
    required NetworkChannel networkChannel,
    required SurveillanceServiceClient surveillanceService,
    required AdbConnection Function() adbConnectionFactory,
    Future<String?> Function() tunnelUrlSource = _noTunnelUrl,
    Future<CameraProbeConfig> Function() cameraConfigSource = _defaultCameraConfig,
    Future<int?> Function() batterySocSource = _noBatterySoc,
  })  : _daemonChannel = daemonChannel, // ignore: prefer_initializing_formals
        _storageService = storageService, // ignore: prefer_initializing_formals
        _systemService = systemService, // ignore: prefer_initializing_formals
        _networkChannel = networkChannel, // ignore: prefer_initializing_formals
        _surveillanceService = surveillanceService, // ignore: prefer_initializing_formals
        _adbConnectionFactory = adbConnectionFactory, // ignore: prefer_initializing_formals
        _tunnelUrlSource = tunnelUrlSource, // ignore: prefer_initializing_formals
        _cameraConfigSource = cameraConfigSource, // ignore: prefer_initializing_formals
        _batterySocSource = batterySocSource; // ignore: prefer_initializing_formals

  static Future<String?> _noTunnelUrl() async => null;
  static Future<CameraProbeConfig> _defaultCameraConfig() async => const CameraProbeConfig();
  static Future<int?> _noBatterySoc() async => null;

  bool _loading = true;
  bool get loading => _loading;

  NetworkType _networkType = NetworkType.offline;
  NetworkType get networkType => _networkType;
  String? _ssid;
  String? get ssid => _ssid;
  TunnelState _tunnelState = TunnelState.offline;
  TunnelState get tunnelState => _tunnelState;

  int _storageClipCount = 0;
  int get storageClipCount => _storageClipCount;
  String _storageUsedFormatted = '';
  String get storageUsedFormatted => _storageUsedFormatted;
  String _storageFreeFormatted = '';
  String get storageFreeFormatted => _storageFreeFormatted;

  CameraTileStatus _cameraStatus = CameraTileStatus.offline;
  CameraTileStatus get cameraStatus => _cameraStatus;
  int _cameraProbedId = -1;
  int get cameraProbedId => _cameraProbedId;
  bool _cameraManualOverride = false;
  bool get cameraManualOverride => _cameraManualOverride;


  Future<void> refresh() async {
    final daemons = await _safeProcessStatus();
    await Future.wait([
      _refreshNetwork(daemons),
      _refreshStorage(),
      _refreshCamera(daemons),
      _refreshBattery(),
    ]);
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, bool>> _safeProcessStatus() async {
    try {
      return await _daemonChannel.processStatus();
    } catch (_) {
      return const {};
    }
  }

  Future<void> _refreshNetwork(Map<String, bool> daemons) async {
    try {
      final current = await _networkChannel.currentNetwork();
      _networkType = current.type;
      _ssid = current.ssid;
    } catch (_) {
      _networkType = NetworkType.offline;
      _ssid = null;
    }

    final tunnelUrl = await _safeTunnelUrl();
    if (tunnelUrl != null && tunnelUrl.isNotEmpty) {
      _tunnelState = TunnelState.online;
    } else if (daemons['ZROK_TUNNEL'] == true) {
      _tunnelState = TunnelState.connecting;
    } else {
      _tunnelState = TunnelState.offline;
    }
  }

  Future<String?> _safeTunnelUrl() async {
    try {
      return await _tunnelUrlSource();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshStorage() async {
    try {
      final resp = await _storageService.getStorageSettings(GetStorageSettingsRequest());
      final usedBytes = resp.recordingsSizeBytes.toInt() + resp.surveillanceSizeBytes.toInt();
      _storageClipCount = resp.recordingsCount + resp.surveillanceCount;
      _storageUsedFormatted = _formatBytes(usedBytes);
      _storageFreeFormatted =
          resp.recordingsStorageType == 'SD_CARD' ? resp.sdCardFreeFormatted : resp.internalFreeFormatted;
    } catch (_) {
      _storageClipCount = 0;
      _storageUsedFormatted = '';
      _storageFreeFormatted = '';
    }
  }

  Future<void> _refreshCamera(Map<String, bool> daemons) async {
    if (daemons['CAMERA_DAEMON'] != true) {
      _cameraStatus = CameraTileStatus.offline;
      return;
    }

    CameraProbeConfig config;
    try {
      config = await _cameraConfigSource();
    } catch (_) {
      config = const CameraProbeConfig();
    }

    _cameraProbedId = config.probedCameraId;
    _cameraManualOverride = config.manualOverride;
    _cameraStatus = config.probedCameraId < 0 ? CameraTileStatus.probing : CameraTileStatus.active;
  }

  /// Battery state of CHARGE, 0-100, or null when it could not be read.
  ///
  /// BladeWatch-1ovy. Not to be confused with state of HEALTH, which
  /// BladeWatch-p7vi removed from the daemon and which is NOT coming back —
  /// SoH is how degraded the pack is, this is how full it is right now.
  int? _batterySoc;
  int? get batterySoc => _batterySoc;

  /// BladeWatch-1ovy: the tile used to say "Not available" unconditionally,
  /// left over from the SoH removal, while the Vehicle screen displayed the
  /// charge percentage on the same device at the same moment. Same source as
  /// Vehicle uses (`VehicleService.GetVehicleState` -> `battery.soc`).
  ///
  /// Null on any failure, which the tile renders as "Not available" — never as
  /// 0%, which would be indistinguishable from a flat pack.
  Future<void> _refreshBattery() async {
    try {
      _batterySoc = await _batterySocSource();
    } catch (_) {
      _batterySoc = null;
    }
  }


  /// Camera Selection dialog — ground truth `MainActivity.onReconfigureCameraClicked()`.
  /// [cameraId] null means "Auto"; native's own request omits `config`
  /// entirely for this write, since the server handler only reads
  /// `manual_camera_id`/`clear_manual_camera_id` off it.
  Future<bool> selectCamera(int? cameraId) async {
    try {
      final resp = await _surveillanceService.setConfig(
        cameraId == null
            ? SetSurveillanceConfigRequest(clearManualCameraId_3: true)
            : SetSurveillanceConfigRequest(manualCameraId: cameraId),
      );
      if (!resp.success) return false;
      await _refreshCamera(await _safeProcessStatus());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Battery health dialog's Reset button — ground truth
  /// `MainActivity.performSohReset()` (the RPC branch; the local-file
  /// fallback there needs `/data/local/tmp` access this port doesn't have).
  Future<bool> resetBattery() async {
    try {
      final resp = await _systemService.resetSoh(ResetSohRequest());
      if (!resp.success) return false;
      await _refreshBattery();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool? _trafficMonitorEnabled;
  bool? get trafficMonitorEnabled => _trafficMonitorEnabled;

  /// Traffic monitor dialog — ground truth `MainActivity.checkTrafficMonitorStatus()`.
  /// A fresh [AdbConnection] per call, matching native's own fresh
  /// `AdbDaemonLauncher(this)` per action rather than a persistent one (that
  /// belongs to the ADB Console screen only).
  Future<void> checkTrafficMonitorStatus() async {
    final connection = _adbConnectionFactory();
    try {
      final result = await connection.connect();
      if (result.status != AdbConnectionStatus.connected) {
        _trafficMonitorEnabled = null;
        notifyListeners();
        return;
      }
      final output = await connection.runCommand(_trafficMonitorStatusCommand);
      _trafficMonitorEnabled = !(output.contains('com.byd.trafficmonitor') && !output.contains('NOT_DISABLED'));
    } catch (_) {
      _trafficMonitorEnabled = null;
    } finally {
      unawaited(connection.close());
      notifyListeners();
    }
  }

  /// Ground truth `MainActivity.setTrafficMonitorEnabled()`.
  Future<bool> setTrafficMonitorEnabled(bool enable) async {
    final connection = _adbConnectionFactory();
    try {
      final result = await connection.connect();
      if (result.status != AdbConnectionStatus.connected) return false;
      await connection.runCommand(
        enable ? 'pm enable com.byd.trafficmonitor 2>&1' : 'pm disable-user --user 0 com.byd.trafficmonitor 2>&1',
      );
      _trafficMonitorEnabled = enable;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      unawaited(connection.close());
    }
  }

  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return unitIndex == 0 ? '${value.toInt()} ${units[unitIndex]}' : '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
