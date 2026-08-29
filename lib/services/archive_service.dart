import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

class ArchiveService {
  static const Map<String, String> sections = {
    '23-23-mp-3-160-k': 'برنامج ليتفقهوا',
    '20260814_20260814_2109': 'مواعظ',
    'mp-3-160-k_20260814': 'خطب الجمعة',
  };

  static Future<List<Lecture>> fetchAllLectures() async {
    final List<Lecture> all = [];
    for (final entry in sections.entries) {
      try {
        final sectionLectures =
            await fetchSectionLectures(entry.key, entry.value);
        all.addAll(sectionLectures);
      } catch (_) {
        // نتجاهل القسم اللي فشل تحميله ونكمل الباقي
      }
    }
    return all;
  }

  static Future<List<Lecture>> fetchSectionLectures(
      String identifier, String sectionTitle) async {
    final url = Uri.parse('https://archive.org/metadata/$identifier');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('تعذر الاتصال بالأرشيف');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final files = (data['files'] as List<dynamic>? ?? []);

    final lectures = <Lecture>[];
    for (final f in files) {
      final name = f['name'] as String? ?? '';
      if (!name.toLowerCase().endsWith('.mp3')) continue;

      final title = name.substring(0, name.length - 4);
      final audioUrl =
          Uri.https('archive.org', '/download/$identifier/$name').toString();

      lectures.add(Lecture(
        title: title,
        section: sectionTitle,
        audioUrl: audioUrl,
        identifier: identifier,
      ));
    }
    return lectures;
  }
}
