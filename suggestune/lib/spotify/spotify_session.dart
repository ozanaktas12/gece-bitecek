import 'package:suggestune/spotify/spotify_auth.dart';
import 'package:suggestune/spotify/token_store.dart';

/// Loads stored tokens and refreshes the access token when near expiry.
class SpotifySession {
  SpotifySession({SpotifyTokenStore? store})
      : _store = store ?? SpotifyTokenStore();

  final SpotifyTokenStore _store;

  static const _skew = Duration(seconds: 60);

  Future<String?> getValidAccessToken() async {
    var tokens = await _store.load();
    if (tokens == null) return null;

    if (tokens.expiresIn <= _skew) {
      tokens = await SpotifyAuth.refreshWithRefreshToken(tokens.refreshToken);
      await _store.save(tokens);
    }

    return tokens.accessToken;
  }

  Future<void> saveFromSignIn(SpotifyTokens tokens) => _store.save(tokens);

  Future<void> signOut() => _store.clear();

  Future<bool> hasStoredSession() async {
    final t = await _store.load();
    return t != null;
  }
}
