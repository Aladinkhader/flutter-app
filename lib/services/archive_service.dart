import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';

class ArchiveService {
  static const Map<String, String> sections = {
    '23-23-mp-3-160-k': 'برنامج ليتفقهوا',
    '20260814_20260814_2109': 'مواعظ',
    'mp-3-160-k_20260814': 'خطب الجمعة',
  };

  static const _cacheKey = 'lectures_cache_v2';

  /// يجلب كل المحاضرات من الكاش إن وُجد، ثم يحدّث الكاش من الإنترنت في الخلفية.
  static Future<List<Lecture>> fetchAllLectures({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null && cached.isNotEmpty) {
        _refreshCacheInBackground();
        return cached;
      }
    }

    final fresh = await _fetchFromNetwork();
    await _writeCache(fresh);
    return fresh;
  }

  static Future<void> _refreshCacheInBackground() async {
    try {
      final fresh = await _fetchFromNetwork();
      await _writeCache(fresh);
    } catch (_) {
      // إبقاء الكاش القديم عند فشل التحديث.
    }
  }

  static Future<List<Lecture>> _fetchFromNetwork() async {
    final List<Lecture> all = [];
    final List<String> errors = [];

    for (final entry in sections.entries) {
      try {
        final sectionLectures = await fetchSectionLectures(
          entry.key,
          entry.value,
        );
        all.addAll(sectionLectures);
      } catch (e) {
        errors.add('${entry.value}: $e');
      }
    }

    if (all.isEmpty) {
      throw Exception(errors.join(' | '));
    }

    return all;
  }

  static Future<List<Lecture>> fetchSectionLectures(
    String identifier,
    String sectionTitle,
  ) async {
    final url = Uri.parse('https://archive.org/metadata/$identifier');
    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];
    final lectures = <Lecture>[];

    for (final file in files) {
      final name = file['name'] as String? ?? '';
      if (!name.toLowerCase().endsWith('.mp3')) continue;

      final title = name.substring(0, name.length - 4);
      final audioUrl = Uri.https(
        'archive.org',
        '/download/$identifier/$name',
      ).toString();

      lectures.add(
        Lecture(
          title: title,
          section: sectionTitle,
          audioUrl: audioUrl,
          identifier: '$identifier:$name',
        ),
      );
    }

    return lectures;
  }

  static Future<List<Lecture>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (item) => Lecture(
              title: item['title'] as String,
              section: item['section'] as String,
              audioUrl: item['audioUrl'] as String,
              identifier: item['identifier'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(List<Lecture> lectures) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(
        lectures
            .map(
              (lecture) => {
                'title': lecture.title,
                'section': lecture.section,
                'audioUrl': lecture.audioUrl,
                'identifier': lecture.identifier,
              },
            )
            .toList(),
      );
      await prefs.setString(_cacheKey, raw);
    } catch (_) {
      // تجاهل خطأ الكاش، فالتطبيق يستطيع العمل من الإنترنت.
    }
  }

  /// يمسح الكاش المحفوظ.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
