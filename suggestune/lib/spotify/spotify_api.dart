import 'dart:convert';

import 'package:http/http.dart' as http;

/// Spotify Web API — paths aligned with the OpenAPI schema.
/// https://developer.spotify.com/reference/web-api/open-api-schema.yaml
///
/// Development Mode (Feb 2026+): batch `GET /v1/tracks?ids=` is not available;
/// use `GET /v1/tracks/{id}` per track. See migration guide.
class SpotifyApi {
  SpotifyApi._();

  static const _apiHost = 'api.spotify.com';

  /// Fetches multiple tracks by calling [getTrack] for each id (parallel).
  /// [market]: ISO 3166-1 alpha-2 (e.g. TR, US).
  static Future<List<TrackCard>> getSeveralTracks({
    required String accessToken,
    required List<String> ids,
    String? market,
  }) async {
    final valid = ids.map((e) => e.trim()).where(isValidTrackId).toList();
    if (valid.isEmpty) return [];
    final futures = valid.map(
      (id) => getTrack(
        accessToken: accessToken,
        id: id,
        market: market,
      ),
    );
    final results = await Future.wait(futures);
    return results.whereType<TrackCard>().toList();
  }

  /// Spotify track IDs are base62, 22 chars (see Web API concepts).
  static bool isValidTrackId(String id) {
    final t = id.trim();
    return t.length == 22 && RegExp(r'^[0-9A-Za-z]{22}$').hasMatch(t);
  }

  /// GET /v1/tracks/{id}
  static Future<TrackCard?> getTrack({
    required String accessToken,
    required String id,
    String? market,
  }) async {
    final cleanId = id.trim();
    if (!isValidTrackId(cleanId)) {
      return null;
    }
    final params = <String, String>{};
    if (market != null && market.isNotEmpty) {
      params['market'] = market;
    }
    final uri = Uri.https(_apiHost, '/v1/tracks/$cleanId', params);
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode == 401) {
      throw SpotifyApiException('Unauthorized (401)');
    }
    if (res.statusCode == 403) {
      throw SpotifyApiException(_forbidden403Help(res.body));
    }
    if (res.statusCode == 429) {
      final retry = res.headers['retry-after'];
      throw SpotifyApiException(
        'Rate limited (429)${retry != null ? ', Retry-After: $retry' : ''}',
      );
    }
    if (res.statusCode == 404) {
      return null;
    }
    if (res.statusCode != 200) {
      throw SpotifyApiException('Track failed (${res.statusCode}): ${res.body}');
    }

    final m = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseTrackMap(m);
  }

  static TrackCard? _parseTrackMap(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    final name = m['name'] as String?;
    if (id == null || name == null) return null;
    final artists = (m['artists'] as List<dynamic>? ?? [])
        .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
    final album = m['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List<dynamic>?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = (images.first as Map<String, dynamic>)['url'] as String?;
    }
    return TrackCard(
      id: id,
      name: name,
      artistsLabel: artists,
      imageUrl: imageUrl,
    );
  }

  static String _forbidden403Help(String body) {
    return 'Erişim reddedildi (403). Development modunda toplu şarkı isteği '
        '(?ids=) kapalı olabilir — uygulama tek tek şarkı çağrısına geçti. '
        'Hâlâ 403 ise: Dashboard’da kullanıcı listesi, Premium (uygulama sahibi), '
        'Çıkış → yeniden giriş.\nYanıt: $body';
  }
}

class TrackCard {
  const TrackCard({
    required this.id,
    required this.name,
    required this.artistsLabel,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String artistsLabel;
  final String? imageUrl;

  String get openInSpotifyUrl => 'https://open.spotify.com/track/$id';
}

class SpotifyApiException implements Exception {
  SpotifyApiException(this.message);
  final String message;

  @override
  String toString() => 'SpotifyApiException: $message';
}
