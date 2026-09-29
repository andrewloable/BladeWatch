/// Mints and versions the JWT used to authenticate every Connect RPC.
///
/// The real implementation (BladeWatch-ncbb.2, the privileged-operations
/// layer) fetches the device secret over loopback IPC (`secret_get` on port
/// 19876, allowed because the Flutter and native APKs share a UID — see
/// docs/ipc-auth-and-secrets.md) and signs the JWT locally, mirroring
/// AuthManager on the native side. **Never read
/// /data/local/tmp/bladewatch_secrets.json directly from Dart — it is mode
/// 600, shell-only.**
abstract class JwtSource {
  /// Mints a fresh JWT. Returns null if minting isn't currently possible
  /// (e.g. the daemon isn't up yet) — [ConnectClient] proceeds without a
  /// token rather than throwing, mirroring
  /// ConnectClientProvider.kt's `catch (e: Exception) { null }`.
  Future<String?> mintJwt();

  /// A value that changes whenever the underlying device secret rotates, so
  /// [ConnectClient] drops a stale cached JWT immediately instead of waiting
  /// out the cache TTL. Mirrors `AuthManager.getStateVersion()`.
  Future<int> stateVersion();
}
