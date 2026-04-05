import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:suggestune/spotify/pkce.dart';

/// Spotify Accounts + Web API (PKCE). See:
/// https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
class SpotifyAuth {
  SpotifyAuth._();

  static const _authHost = 'accounts.spotify.com';
  static const _tokenPath = '/api/token';
  static const _authorizePath = '/authorize';
  static const _callbackUrlScheme = 'suggestune';

  /// Minimum scopes; add more only when a feature needs them.
  static const defaultScopes = <String>[
    'user-read-email',
  ];

  static String get _clientId {
    final v = dotenv.env['SPOTIFY_CLIENT_ID']?.trim() ?? '';
    if (v.isEmpty) {
      throw StateError('SPOTIFY_CLIENT_ID is missing in assets/env');
    }
    return v;
  }

  static String get _redirectUri {
    final v = dotenv.env['SPOTIFY_REDIRECT_URI']?.trim() ?? '';
    if (v.isEmpty) {
      throw StateError('SPOTIFY_REDIRECT_URI is missing in assets/env');
    }
    return v;
  }

  /// Opens Spotify login; returns access + refresh token (PKCE, no client secret).
  static Future<SpotifyTokens> signInWithPkce() async {
    final verifier = generateCodeVerifier();
    final challenge = codeChallengeS256(verifier);
    final state = _randomState();

    final authUri = Uri.https(_authHost, _authorizePath, {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'state': state,
      'scope': defaultScopes.join(' '),
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
    });

    final callback = await FlutterWebAuth2.authenticate(
      url: authUri.toString(),
      callbackUrlScheme: _callbackUrlScheme,
    );

    final returned = Uri.parse(callback);
    final err = returned.queryParameters['error'];
    if (err != null) {
      final desc = returned.queryParameters['error_description'] ?? err;
      throw SpotifyAuthException('$err: $desc');
    }

    final code = returned.queryParameters['code'];
    final returnedState = returned.queryParameters['state'];
    if (code == null || code.isEmpty) {
      throw const SpotifyAuthException('Missing ?code= in callback');
    }
    if (returnedState != state) {
      throw const SpotifyAuthException('Invalid OAuth state');
    }

    final tokenUri = Uri.https(_authHost, _tokenPath);
    final body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': _redirectUri,
      'client_id': _clientId,
      'code_verifier': verifier,
    };

    final res = await http.post(
      tokenUri,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw SpotifyAuthException(
        'Token exchange failed (${res.statusCode}): ${res.body}',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final expiresIn = json['expires_in'] as int?;
    if (access == null || refresh == null || expiresIn == null) {
      throw const SpotifyAuthException('Unexpected token response');
    }

    return SpotifyTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: Duration(seconds: expiresIn),
    );
  }

  /// PKCE public client: [client_secret] is not sent.
  /// See: https://developer.spotify.com/documentation/web-api/tutorials/refreshing-tokens
  static Future<SpotifyTokens> refreshWithRefreshToken(String refreshToken) async {
    final tokenUri = Uri.https(_authHost, _tokenPath);
    final body = <String, String>{
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': _clientId,
    };

    final res = await http.post(
      tokenUri,
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw SpotifyAuthException(
        'Refresh failed (${res.statusCode}): ${res.body}',
      );
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final access = json['access_token'] as String?;
    final expiresIn = json['expires_in'] as int?;
    final newRefresh = json['refresh_token'] as String?;
    if (access == null || expiresIn == null) {
      throw const SpotifyAuthException('Unexpected refresh response');
    }

    return SpotifyTokens(
      accessToken: access,
      refreshToken: newRefresh ?? refreshToken,
      expiresIn: Duration(seconds: expiresIn),
    );
  }

  static String _randomState() {
    final b = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(b).replaceAll('=', '');
  }
}

class SpotifyTokens {
  const SpotifyTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
}

class SpotifyAuthException implements Exception {
  const SpotifyAuthException(this.message);
  final String message;

  @override
  String toString() => 'SpotifyAuthException: $message';
}
