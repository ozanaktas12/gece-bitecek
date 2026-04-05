import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:suggestune/spotify/spotify_auth.dart';

/// Persists OAuth tokens on-device. Refresh token is sensitive — keep in Keychain/Keystore.
class SpotifyTokenStore {
  SpotifyTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'spotify_access_token';
  static const _kRefresh = 'spotify_refresh_token';
  static const _kExpiresAtMs = 'spotify_access_expires_at_ms';

  final FlutterSecureStorage _storage;

  Future<void> save(SpotifyTokens tokens) async {
    final expiresAt = DateTime.now().add(tokens.expiresIn);
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
    await _storage.write(
      key: _kExpiresAtMs,
      value: expiresAt.millisecondsSinceEpoch.toString(),
    );
  }

  Future<SpotifyTokens?> load() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    final expRaw = await _storage.read(key: _kExpiresAtMs);
    if (access == null || refresh == null || expRaw == null) return null;
    final expMs = int.tryParse(expRaw);
    if (expMs == null) return null;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expMs);
    final remaining = expiresAt.difference(DateTime.now());
    return SpotifyTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiresAtMs);
  }
}
