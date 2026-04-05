import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikedTrackEntry {
  const LikedTrackEntry({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

/// Local-only list of liked tracks (not synced to Spotify library).
class LikedTracksStore extends ChangeNotifier {
  LikedTracksStore({this.prefsKey = 'suggestune_liked_tracks_v1'});

  final String prefsKey;

  Future<List<LikedTrackEntry>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(prefsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) {
          final m = e as Map<String, dynamic>;
          return LikedTrackEntry(
            id: m['id'] as String,
            title: m['title'] as String,
            subtitle: m['subtitle'] as String,
          );
        })
        .toList();
  }

  Future<void> add(LikedTrackEntry entry) async {
    final p = await SharedPreferences.getInstance();
    var current = await load();
    current = current.where((e) => e.id != entry.id).toList();
    current.insert(0, entry);
    final encoded = jsonEncode(
      current
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'subtitle': e.subtitle,
            },
          )
          .toList(),
    );
    await p.setString(prefsKey, encoded);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final p = await SharedPreferences.getInstance();
    final current = await load();
    final next = current.where((e) => e.id != id).toList();
    final encoded = jsonEncode(
      next
          .map(
            (e) => {
              'id': e.id,
              'title': e.title,
              'subtitle': e.subtitle,
            },
          )
          .toList(),
    );
    await p.setString(prefsKey, encoded);
    notifyListeners();
  }
}
