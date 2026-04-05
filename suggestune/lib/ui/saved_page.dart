import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:suggestune/data/liked_tracks_store.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key, required this.likedStore});

  final LikedTracksStore likedStore;

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<LikedTrackEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.likedStore.addListener(_onLikedChanged);
    _reload(initial: true);
  }

  @override
  void dispose() {
    widget.likedStore.removeListener(_onLikedChanged);
    super.dispose();
  }

  void _onLikedChanged() {
    _reload(initial: false);
  }

  Future<void> _reload({required bool initial}) async {
    if (initial) {
      setState(() => _loading = true);
    }
    final list = await widget.likedStore.load();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _open(String id) async {
    final uri = Uri.parse('https://open.spotify.com/track/$id');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _remove(String id) async {
    await widget.likedStore.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Henüz beğenilen şarkı yok.\nKeşfet sekmesinde sağa kaydır.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _reload(initial: false),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = _items[i];
          return ListTile(
            title: Text(e.title),
            subtitle: Text(e.subtitle),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(e.id),
            ),
            onTap: () => _open(e.id),
          );
        },
      ),
    );
  }
}
