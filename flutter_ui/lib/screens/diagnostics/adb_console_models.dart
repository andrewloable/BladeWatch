/// A preset ADB command for quick execution — ported 1:1 from
/// `app/src/main/java/com/loabletech/bladewatch/ui/model/PresetCommand.kt`.
class AdbPresetCommand {
  final String label;
  final String command;
  final String category;

  const AdbPresetCommand({required this.label, required this.command, required this.category});
}

/// Ported from `PresetCommands.ALL` — same labels, commands and categories,
/// same order.
const List<AdbPresetCommand> adbPresetCommands = [
  AdbPresetCommand(label: 'Process Status', command: "ps -ef | grep -E 'daemon|zrok'", category: 'Status'),
  AdbPresetCommand(label: 'Port Status', command: "netstat -tlnp | grep -E '8080|8554'", category: 'Status'),
  AdbPresetCommand(label: 'Zrok Logs', command: 'cat /data/local/tmp/zrok.log | tail -50', category: 'Logs'),
  AdbPresetCommand(label: 'Camera Logs', command: 'cat /data/local/tmp/byd_cam_daemon.log | tail -50', category: 'Logs'),
  AdbPresetCommand(label: 'Sentry Logs', command: 'cat /data/local/tmp/sentry_daemon.log | tail -50', category: 'Logs'),
  AdbPresetCommand(
    label: 'Kill Camera',
    command: 'pkill -9 -f start_cam_daemon; '
        'rm -f /data/local/tmp/start_cam_daemon.sh; '
        'sleep 1; '
        'pkill -9 -f byd_cam_daemon; '
        'killall -9 byd_cam_daemon 2>/dev/null; '
        'rm -f /data/local/tmp/camera_daemon.lock',
    category: 'Control',
  ),
  AdbPresetCommand(label: 'Kill Sentry', command: 'pkill -9 -f sentry_daemon', category: 'Control'),
  AdbPresetCommand(label: 'Storage', command: 'df -h /data', category: 'System'),
  AdbPresetCommand(label: 'Battery', command: 'dumpsys battery', category: 'System'),
  AdbPresetCommand(label: 'Network', command: 'ip addr', category: 'System'),
  AdbPresetCommand(label: 'Ping Test', command: 'ping -c 3 8.8.8.8', category: 'System'),
  AdbPresetCommand(label: 'Proxy Settings', command: 'settings get global http_proxy', category: 'System'),
  AdbPresetCommand(label: 'Reset Proxy', command: 'settings put global http_proxy :0', category: 'Control'),
  AdbPresetCommand(label: 'ACC Props', command: 'getprop | grep -i acc', category: 'System'),
];
