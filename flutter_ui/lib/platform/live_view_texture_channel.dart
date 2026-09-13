import 'dart:typed_data';

import 'platform_channel.dart';

/// Dart side of the `liveView.*` channel group (BladeWatch-yz1e.10) — thin
/// wrapper over the Kotlin `LiveViewTexturePlugin`
/// (`flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/liveview/`),
/// which owns the actual `TextureRegistry`/`MediaCodec` calls. All decode
/// pipeline behaviour (WebSocket connection, retry, frame-vs-codec-config
/// detection) lives in `LiveViewController`, not here — this class only
/// carries raw bytes and ids across the platform boundary.
///
/// Unlike every other `platform/*.dart` wrapper, the [PlatformChannel]
/// passed in here must be backed by a *separate* underlying `MethodChannel`
/// (`"net.bladewatch.flutter/live_view_texture"`, not the shared
/// `"net.bladewatch.flutter/privileged"` one) — see `MainActivity.kt`'s
/// `configureFlutterEngine()` for why: this channel runs on its own
/// background `TaskQueue` so a `MediaCodec` call never blocks the platform/
/// UI thread, which the shared privileged channel's handlers are not set up
/// for. `main.dart` constructs the distinct `MethodChannelBridge` instance
/// this needs.
class LiveViewTextureChannel {
  final PlatformChannel _channel;

  const LiveViewTextureChannel(this._channel);

  /// Registers a new texture and returns its id, for `Texture(textureId:)`.
  Future<int> createTexture() => _channel.invoke<int>('liveView', 'createTexture');

  /// Configures and starts the decoder once the stream's real dimensions
  /// are known (mirrors native calling this only after `GetQuality`
  /// resolves, not at connect time).
  Future<void> configure({required int textureId, required int width, required int height}) => _channel.invoke<void>(
        'liveView',
        'configure',
        {'textureId': textureId, 'width': width, 'height': height},
      );

  /// Feeds one complete H.264 access unit — Dart has already reassembled
  /// any WebSocket fragmentation via `dart:io`'s own `WebSocket`, which
  /// (per RFC 6455) always delivers complete messages regardless of how
  /// many wire frames they were split across, so no fragment-reassembly
  /// logic is ported into Kotlin at all (see `LiveViewController`'s doc
  /// comment for the full architecture note).
  Future<void> feedFrame({required int textureId, required Uint8List bytes, required bool isCodecConfig}) => _channel.invoke<void>(
        'liveView',
        'feedFrame',
        {'textureId': textureId, 'bytes': bytes, 'isCodecConfig': isCodecConfig},
      );

  /// Releases the decoder and the texture. Safe to call even if setup never
  /// completed (mirrors `LiveViewTexturePlugin.dispose`'s own idempotency).
  Future<void> dispose(int textureId) => _channel.invoke<void>('liveView', 'dispose', {'textureId': textureId});
}
