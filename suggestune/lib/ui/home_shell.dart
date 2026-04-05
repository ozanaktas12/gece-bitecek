import 'package:flutter/material.dart';

import 'package:suggestune/data/liked_tracks_store.dart';
import 'package:suggestune/spotify/spotify_session.dart';
import 'package:suggestune/ui/discover_page.dart';
import 'package:suggestune/ui/saved_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final SpotifySession session;
  final Future<void> Function() onSignOut;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _liked = LikedTracksStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestune'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await widget.onSignOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          DiscoverPage(session: widget.session, likedStore: _liked),
          SavedPage(likedStore: _liked),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Beğeniler',
          ),
        ],
      ),
    );
  }
}
