import 'platform_channel.dart';

/// Dart side of the `setup.*` channel group (BladeWatch-yz1e.11) — launches
/// Android Settings screens for the Setup Guide dialog's Auto-start and
/// Overlay-permission steps. A new group, not an extension of an existing
/// one: nothing else in this app launches an Android `Intent`. Ground truth:
/// `SetupGuideDialog.java`'s `openAutoStartSettings()` (a 4-level fallback
/// cascade through BYD's own autostart-management app) and its overlay step
/// (`ACTION_MANAGE_OVERLAY_PERMISSION`, targeted at `net.bladewatch.app`'s
/// package — see `MainActivity.kt`'s `openOverlaySettings()` doc comment for
/// why it is that package, not this Flutter APK's own). Both are
/// best-effort and fire-and-forget: native swallows every failure in the
/// cascade the same way, since there is nothing more the UI can usefully do
/// if every fallback fails.
class SetupChannel {
  final PlatformChannel _channel;

  const SetupChannel(this._channel);

  Future<void> openAutoStartSettings() => _channel.invoke<void>('setup', 'openAutoStartSettings');

  Future<void> openOverlaySettings() => _channel.invoke<void>('setup', 'openOverlaySettings');
}
