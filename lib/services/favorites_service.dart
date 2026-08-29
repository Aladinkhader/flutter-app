import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  static const _key = 'favorites_list';

  List<Lecture> _favorites = [];
  bool _loaded = false;

  List<Lecture> get favorites => _favorites;

  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        _favorites = list
            .map((e) => Lecture(
                  title: e['title'],
                  section: e['section'],
                  audioUrl: e['audioUrl'],
                  identifier: e['identifier'],
                ))
            .toList();
      } catch (_) {
        _favorites = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  bool isFavorite(Lecture lecture) {
    return _favorites.any((l) => l.audioUrl == lecture.audioUrl);
  }

  Future<void> toggleFavorite(Lecture lecture) async {
    if (isFavorite(lecture)) {
      _favorites.removeWhere((l) => l.audioUrl == lecture.audioUrl);
    } else {
      _favorites.add(lecture);
    }
    notifyListeners();
    await _save();
  }

  Future<void> removeFavorite(Lecture lecture) async {
    _favorites.removeWhere((l) => l.audioUrl == lecture.audioUrl);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_favorites
        .map((l) => {
              'title': l.title,
              'section': l.section,
              'audioUrl': l.audioUrl,
              'identifier': l.identifier,
            })
        .toList());
    await prefs.setString(_key, raw);
  }
}
