import 'dart:convert';

import 'package:http/http.dart' as http;

/// Spotify Web API — uses paths from the official OpenAPI schema.
/// https://developer.spotify.com/reference/web-api/open-api-schema.yaml
class SpotifyApi {
  SpotifyApi._();

  static const _apiHost = 'api.spotify.com';

  static Future<List<TrackCard>> getSeveralTracks({
    required String accessToken,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return [];
    final uri = Uri.https(_apiHost, '/v1/tracks', {'ids': ids.join(',')});
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (res.statusCode == 401) {
      throw SpotifyApiException('Unauthorized (401)');
    }
    if (res.statusCode == 429) {
      final retry = res.headers['retry-after'];
      throw SpotifyApiException('Rate limited (429)${retry != null ? ', Retry-After: $retry' : ''}');
    }
    if (res.statusCode != 200) {
      throw SpotifyApiException('Tracks failed (${res.statusCode}): ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = json['tracks'] as List<dynamic>? ?? [];
    final out = <TrackCard>[];
    for (final item in list) {
      if (item == null) continue;
      final m = item as Map<String, dynamic>;
      final id = m['id'] as String?;
      final name = m['name'] as String?;
      if (id == null || name == null) continue;
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
      out.add(TrackCard(
        id: id,
        name: name,
        artistsLabel: artists,
        imageUrl: imageUrl,
      ));
    }
    return out;
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
