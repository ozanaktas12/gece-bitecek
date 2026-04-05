import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

import 'package:suggestune/data/liked_tracks_store.dart';
import 'package:suggestune/spotify/spotify_api.dart';
import 'package:suggestune/spotify/spotify_session.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    required this.session,
    required this.likedStore,
  });

  final SpotifySession session;
  final LikedTracksStore likedStore;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<TrackCard> _tracks = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await widget.session.getValidAccessToken();
      if (token == null) {
        setState(() {
          _loading = false;
          _error = 'Oturum yok';
        });
        return;
      }

      final raw = await rootBundle.loadString('assets/suggestions_seed.json');
      final ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
      ids.shuffle(Random());
      final batch = ids.take(20).toList();

      final market =
          ui.PlatformDispatcher.instance.locale.countryCode ?? 'US';

      final tracks = await SpotifyApi.getSeveralTracks(
        accessToken: token,
        ids: batch,
        market: market,
      );
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openSpotify(TrackCard t) async {
    final uri = Uri.parse(t.openInSpotifyUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Spotify açılamadı')),
      );
    }
  }

  Future<void> _onSwipeEnd(
    int previousIndex,
    int targetIndex,
    SwiperActivity activity,
  ) async {
    if (activity is! Swipe) return;
    final t = _tracks[previousIndex];
    if (activity.direction == AxisDirection.right) {
      await widget.likedStore.add(
        LikedTrackEntry(id: t.id, title: t.name, subtitle: t.artistsLabel),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedildi: ${t.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Yeniden dene')),
            ],
          ),
        ),
      );
    }
    if (_tracks.isEmpty) {
      return const Center(child: Text('Gösterilecek şarkı yok'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Sağa kaydır: beğen · Sola: geç',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: AppinioSwiper(
              cardCount: _tracks.length,
              onSwipeEnd: _onSwipeEnd,
              onEnd: () {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liste bitti — yenilemek için aşağı çek')),
                );
              },
              cardBuilder: (context, index) {
                final t = _tracks[index];
                return _TrackCardView(
                  track: t,
                  onOpenSpotify: () => _openSpotify(t),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackCardView extends StatelessWidget {
  const _TrackCardView({
    required this.track,
    required this.onOpenSpotify,
  });

  final TrackCard track;
  final VoidCallback onOpenSpotify;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: track.imageUrl != null
                ? Image.network(
                    track.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF333333),
                      child: Center(
                        child: Icon(Icons.music_note, size: 64, color: Colors.white54),
                      ),
                    ),
                  )
                : const ColoredBox(
                    color: Color(0xFF333333),
                    child: Center(
                      child: Icon(Icons.music_note, size: 64, color: Colors.white54),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artistsLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onOpenSpotify,
                  child: const Text('Spotify’da aç'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
