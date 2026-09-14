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
  /// ACC_SENTRY_DAEMON/ZROK_TUNNEL) — not to be confused with [status] above, which
  /// reports camera *recording* state. Unlike the other three methods, this one
  /// unwraps the response's nested `daemons` object into a flat, typed map, since
  /// every caller wants exactly that shape (see the Startup screen).
  Future<Map<String, bool>> processStatus() async {
    final response = await _asStringMap(_channel.invoke('daemon', 'processStatus'));
    final daemons = Map<String, dynamic>.from(response['daemons'] as Map);
    return daemons.map((key, value) => MapEntry(key, value as bool));
  }

  /// BladeWatch-m1po: the current Zrok tunnel URL, or null when no tunnel is
  /// serving one. Backs the Dashboard's remote-access tile.
  ///
  /// The daemon gates the URL on the tunnel PROCESS being alive, so a URL left
  /// in zrok's log by a previous session never comes back as a live tunnel. It
  /// also reports a `running` flag, distinguishing "up but has not published a
  /// URL yet" from "offline" — not surfaced here, because the Dashboard renders
  /// only online/offline. Widen the return type if a caller ever needs it.
  Future<String?> tunnelUrl() async {
    final response = await _asStringMap(_channel.invoke('daemon', 'tunnelStatus'));
    final url = response['url'] as String?;
    return (url == null || url.isEmpty) ? null : url;
  }

  /// BladeWatch-abcx: enable or disable an optional daemon, returning true only if
  /// the daemon accepted it. Anything outside its allow-list (currently ZROK_TUNNEL
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
