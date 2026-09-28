import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// This device's own video decode ceiling (BladeWatch-rdtj.73), probed once in the background and
/// read synchronously everywhere else -- a hardware decoder's capability table cannot change at
/// runtime, and a video player screen's timing (creating its player as soon as it can, the way
/// clip_player_recovery_test.dart pins) must not wait on a platform channel round-trip.
///
/// Android only: every other companion platform (iOS, macOS, Windows, Linux) plays the car's
/// native 2560x1920 mosaic fine, so the channel is never opened there. The car's own
/// ClipCapability.parseHint treats a request with no `maxW`/`maxH` as "serve native" -- exactly
/// the behaviour before this feature existed -- so [known] being null (probe still running, not
/// yet started, or this platform needs no hint) is always a safe default, never a broken one.
class VideoCapability {
  VideoCapability._();

  static const _channel = MethodChannel('net.bladewatch.companionapp/video_capability');

  static (int, int)? _known;
  static bool _started = false;

  /// The most recently known (width, height) ceiling, or null. Synchronous on purpose.
  static (int, int)? get known => _known;

  /// Starts the one-time probe if it hasn't run yet (idempotent; cheap to call on every screen
  /// open). Fire-and-forget -- callers read [known] later, once it's ready.
  static void ensureStarted() {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    unawaited(_probe());
  }

  static Future<void> _probe() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('maxDecodeSize');
      if (result == null || result.length != 2) return;
      final w = result[0] as int?;
      final h = result[1] as int?;
      if (w != null && h != null) _known = (w, h);
    } catch (_) {
      // stays null -- the car serves native, same as before this feature existed
    }
  }
}
