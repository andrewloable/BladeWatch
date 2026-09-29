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
  AdbPresetCommand(label: 'Process Status', command: "ps -ef | grep -E 'daemon'", category: 'Status'),
  AdbPresetCommand(label: 'Port Status', command: "netstat -tlnp | grep -E '8080|8554'", category: 'Status'),
  AdbPresetCommand(label: 'Camera Logs', command: 'cat /data/local/tmp/byd_cam_daemon.log | tail -50', category: 'Logs'),
  AdbPresetCommand(label: 'Sentry Logs', command: 'cat /data/local/tmp/sentry_daemon.log | tail -50', category: 'Logs'),
  // BladeWatch-6jj1: these run in THIS app's ADB console, so the old `pkill -f` forms
  // killed the user's own console session rather than the daemon — toybox matches the
  // pattern as a substring of every cmdline, and the console shell's cmdline is the
  // command you just typed. Verified on the head unit: a marker matching no process at
  // all still killed the shell (exit 137).
  //
  // killall matches comm/argv[0], both "sh" for the console, so it cannot self-match.
  // The watchdog SCRIPT runs as plain "sh" and needs a cmdline match, which is safe only
  // because grep -E takes a regex and the pattern is bracketed — and the rm must glob
  // start_cam_*.sh, because spelling the literal out would re-arm that regex against this
  // very command line.
  //
  // Mirrors PresetCommands.ALL on the service host; keep the two in step.
  AdbPresetCommand(
    label: 'Kill Camera',
    command: r"for p in $(ps -A -o PID,ARGS 2>/dev/null | grep -E '[s]tart_cam_daemon' | "
        r"awk '{print $1}'); do kill -9 $p 2>/dev/null; done; "
        'rm -f /data/local/tmp/start_cam_*.sh; '
        'sleep 1; '
        'killall -9 byd_cam_daemon 2>/dev/null; '
        'rm -f /data/local/tmp/camera_daemon.lock',
    category: 'Control',
  ),
  AdbPresetCommand(
      label: 'Kill Sentry',
      command: 'killall -9 sentry_daemon acc_sentry_daemon 2>/dev/null',
      category: 'Control'),
  AdbPresetCommand(label: 'Storage', command: 'df -h /data', category: 'System'),
  AdbPresetCommand(label: 'Battery', command: 'dumpsys battery', category: 'System'),
  AdbPresetCommand(label: 'Network', command: 'ip addr', category: 'System'),
  AdbPresetCommand(label: 'Ping Test', command: 'ping -c 3 8.8.8.8', category: 'System'),
  AdbPresetCommand(label: 'Proxy Settings', command: 'settings get global http_proxy', category: 'System'),
  AdbPresetCommand(label: 'Reset Proxy', command: 'settings put global http_proxy :0', category: 'Control'),
  AdbPresetCommand(label: 'ACC Props', command: 'getprop | grep -i acc', category: 'System'),
];
