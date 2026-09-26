import 'platform_channel.dart';

/// Dart side of the `daemon.*` channel group (BladeWatch-ncbb.2) — for the
/// Daemons settings screen. `start`/`stop`/`status` thin-wrap the Kotlin
/// `DaemonControl` class, which itself thin-wraps the same-named commands on
/// `TcpCommandServer` (port 19876). Any [PlatformChannelError] /
/// [ChannelTimeoutException] from the underlying channel propagates
/// unchanged — this class adds no error handling of its own.
class DaemonChannel {
  final PlatformChannel _channel;

  const DaemonChannel(this._channel);

  Future<Map<String, dynamic>> start() => _asStringMap(_channel.invoke('daemon', 'start'));

  Future<Map<String, dynamic>> stop() => _asStringMap(_channel.invoke('daemon', 'stop'));

  Future<Map<String, dynamic>> status() => _asStringMap(_channel.invoke('daemon', 'status'));

  /// BladeWatch-1xt9: real daemon-*process* liveness (CAMERA_DAEMON/SENTRY_DAEMON/
  /// ACC_SENTRY_DAEMON/PEAR_PEER) — not to be confused with [status] above, which
  /// reports camera *recording* state. Unlike the other three methods, this one
  /// unwraps the response's nested `daemons` object into a flat, typed map, since
  /// every caller wants exactly that shape (see the Startup screen).
  Future<Map<String, bool>> processStatus() async => (await daemonStatus()).running;

  /// BladeWatch-dh1r: liveness AND the user's enabled intent, which are different
  /// questions and were conflated until a bug on the head unit made that obvious.
  ///
  /// Enabling a daemon only RECORDS INTENT — the daemon's health check performs the
  /// launch on its next cycle, so the process appears some seconds later. A UI
  /// bound to liveness therefore shows a switch springing back to off, and the user's
  /// natural second tap disables the daemon they just enabled, because the disable path
  /// also kills the process.
  ///
  /// [DaemonStatus.enabled] carries entries only for daemons that can actually be
  /// toggled; the rest are started by the service host and have no such state.
  Future<DaemonStatus> daemonStatus() async {
    final response = await _asStringMap(_channel.invoke('daemon', 'processStatus'));
    final daemons = Map<String, dynamic>.from(response['daemons'] as Map);
    final running = daemons.map((key, value) => MapEntry(key, value == true));
    // Absent entirely on a daemon that predates this field. Both APKs share a UID and
    // install together so that pair should not occur, but if it ever does, fall back to
    // liveness: that is the OLD behaviour, which is merely imperfect. Defaulting to
    // "nothing is enabled" would be actively worse — every switch would read off, and
    // flipping one on would spring back exactly as in BladeWatch-dh1r.
    final enabledRaw = response['enabled'];
    final enabled = enabledRaw == null
        ? running
        : Map<String, dynamic>.from(enabledRaw as Map)
            .map((key, value) => MapEntry(key, value == true));
    return DaemonStatus(running: running, enabled: enabled);
  }

  /// BladeWatch-rdtj.17: the Pear peer -- whether it runs, whether the owner switched it on,
  /// and whether the car can actually be found right now ([PearStatus.reachable]). Never a
  /// topic or key: the daemon does not send any.
  Future<PearStatus> pearStatus() async {
    final r = await _asStringMap(_channel.invoke('daemon', 'pearStatus'));
    final last = r['lastCompanionAt'];
    return PearStatus(
      running: r['running'] as bool? ?? false,
      enabled: r['enabled'] as bool? ?? false,
      reachable: r['reachable'] as bool?,
      devicesConnected: (r['companions'] as num?)?.toInt() ?? 0,
      lastConnection: last is num ? DateTime.fromMillisecondsSinceEpoch(last.toInt()) : null,
    );
  }

  /// BladeWatch-abcx: enable or disable an optional daemon, returning true only if
  /// the daemon accepted it. Anything outside its allow-list (currently PEAR_PEER
  /// alone) comes back false rather than silently doing nothing — see
  /// [SettingsDaemonsController] for why the other three are not toggleable.
  Future<bool> setDaemonEnabled(String nativeKey, bool enabled) async {
    final response = await _asStringMap(
      _channel.invoke('daemon', 'setEnabled', {'type': nativeKey, 'enabled': enabled}),
    );
    return response['status'] == 'ok';
  }

  // The real MethodChannel's standard codec deserializes a Kotlin Map as
  // Map<Object?, Object?>, not Map<String, dynamic> — Map.from() copies
  // entries into the right static type regardless of which PlatformChannel
  // implementation produced the result (real channel or the fake).
  static Future<Map<String, dynamic>> _asStringMap(Future<dynamic> result) async {
    return Map<String, dynamic>.from(await result as Map);
  }
}

/// What the daemon reports about every background service: whether each process is
/// alive, and — for the toggleable ones only — whether the user has asked for it.
class DaemonStatus {
  /// Process liveness, keyed by native daemon name. Every daemon appears.
  final Map<String, bool> running;

  /// The user's recorded intent, keyed the same way. Only toggleable daemons appear;
  /// a missing key means "not toggleable", and a false value means "switched off".
  final Map<String, bool> enabled;

  const DaemonStatus({required this.running, required this.enabled});
}

/// What the daemon reports about the Pear peer (BladeWatch-rdtj.17).
class PearStatus {
  /// The pear_daemon process is alive. Says nothing about reachability on its own.
  final bool running;

  /// The owner has switched remote access on (pairing does it too).
  final bool enabled;

  /// Whether the car can be found right now: running, joined to its topic, and HyperDHT
  /// online. Null when the car's pear-end cannot tell (older than flutter_pear 0.4.4).
  final bool? reachable;

  /// Paired devices connected over Pear at the moment.
  final int devicesConnected;

  /// When a paired device last connected over Pear; null if none has since pear_daemon started.
  final DateTime? lastConnection;

  const PearStatus({
    required this.running,
    required this.enabled,
    this.reachable,
    this.devicesConnected = 0,
    this.lastConnection,
  });

  /// Nothing known yet: before the first read, or when the daemon cannot be reached.
  static const unknown = PearStatus(running: false, enabled: false);
}
