import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';

class ArchiveService {
  static const Map<String, String> sections = {
    '23-23-mp-3-160-k': 'برنامج ليتفقهوا',
    '20260814_20260814_2109': 'مواعظ',
    'mp-3-160-k_20260814': 'خطب الجمعة',
    'mp-3-16_202609': 'فتاوي',
    '19-.-m-4-a-128-k': 'برنامج ليدبروا',
  };

  static const _cacheKey = 'lectures_cache_v1';

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
    } catch (_) {}
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
    final response =
        await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];
    final lectures = <Lecture>[];

    for (final file in files) {
      final name = file['name'] as String? ?? '';
      final lowerName = name.toLowerCase();
      if (!lowerName.endsWith('.mp3') && !lowerName.endsWith('.m4a')) {
        continue;
      }

      final rawTitle = name.substring(0, name.length - 4);
      final displayTitle =
          sectionTitle == 'فتاوي' ? _cleanFatawaTitle(rawTitle) : rawTitle;

      final audioUrl = Uri.https(
        'archive.org',
        '/download/$identifier/$name',
      ).toString();

      lectures.add(
        Lecture(
          title: displayTitle,
          section: sectionTitle,
          audioUrl: audioUrl,
          identifier: identifier,
        ),
      );
    }

    // نرتب حسب رقم الحلقة المستخرج من الاسم الأصلي (البرومو أولًا، ثم تصاعديًا)
    lectures.sort((a, b) {
      final numA = _extractEpisodeNumber(a.title);
      final numB = _extractEpisodeNumber(b.title);
      if (numA != null && numB != null) return numA.compareTo(numB);
      if (numA != null) return -1;
      if (numB != null) return 1;
      return a.title.compareTo(b.title);
    });

    return lectures;
  }

  /// يستخرج رقم الحلقة (البرومو يعتبر صفر عشان يطلع أول واحد)
  static int? _extractEpisodeNumber(String title) {
    if (title.contains('برومو')) return 0;
    final match = RegExp(r'\d+').firstMatch(title);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  /// ينظف عناوين الفتاوى: يشيل اسم الشيخ والفواصل والأرقام الزائدة بالآخر
  static String _cleanFatawaTitle(String raw) {
    var t = raw;

    final namePatterns = [
      RegExp(r'الشيخ\s*الدكتور\s*محمد\s*الأمين\s*إسماعيل'),
      RegExp(r'الشيخ\s*د\.?\s*محمد\s*الأمين\s*إسماعيل'),
      RegExp(r'د\.?\s*محمد\s*الأمين\s*إسماعيل'),
      RegExp(r'محمد\s*الأمين\s*إسماعيل'),
      RegExp(r'برنامج\s*إفادة\s*السائلين'),
    ];
    for (final p in namePatterns) {
      t = t.replaceAll(p, '');
    }

    t = t.replaceAll('||', ' ');
    t = t.replaceAll('|', ' ');
    t = t.replaceAll('🔹', ' ');
    t = t.replaceAll('__', ' ');
    t = t.replaceAll(RegExp(r'\bI\b'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

    // إزالة أي أرقام زايدة بآخر العنوان (زي "؟2" أو "3")
    t = t.replaceAll(RegExp(r'\d+$'), '').trim();

    return t.isEmpty ? raw : t;
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
    } catch (_) {}
  }

  /// يجيب تشكيلة متنوعة ومتداخلة: عدد مخصص من كل قسم، بترتيب ممزوج بينهم
  static Future<List<Lecture>> fetchFeaturedMix() async {
    final all = await fetchAllLectures();
    final Map<String, int> countPerSection = {
      'برنامج ليتفقهوا': 4,
      'مواعظ': 3,
      'خطب الجمعة': 3,
    };

    final Map<String, List<Lecture>> bySection = {};
    for (final lecture in all) {
      bySection.putIfAbsent(lecture.section, () => []).add(lecture);
    }

    final Map<String, List<Lecture>> picked = {};
    countPerSection.forEach((section, count) {
      final list = bySection[section] ?? [];
      picked[section] = list.take(count).toList();
    });

    final List<Lecture> mix = [];
    int index = 0;
    bool addedAny = true;
    while (addedAny) {
      addedAny = false;
      for (final section in countPerSection.keys) {
        final list = picked[section]!;
        if (index < list.length) {
          mix.add(list[index]);
          addedAny = true;
        }
      }
      index++;
    }

    return mix;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
