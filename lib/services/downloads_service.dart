import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../models/lecture.dart';

class DownloadsService extends ChangeNotifier {
  DownloadsService._();

  static final DownloadsService instance =
      DownloadsService._();

  static const String _storageKey = 'downloads_v1';

  final Dio _dio = Dio();

  final List<Lecture> _downloads = [];

  final Map<String, double> _progress = {};

  final Set<String> _downloading = {};

  List<Lecture> get downloads =>
      List.unmodifiable(_downloads);

  bool isDownloaded(Lecture lecture) {
    return _downloads.any(
      (item) => item.audioUrl == lecture.audioUrl,
    );
  }

  bool isDownloading(Lecture lecture) {
    return _downloading.contains(lecture.audioUrl);
  }

  double progressFor(Lecture lecture) {
    return _progress[lecture.audioUrl] ?? 0.0;
  }

  String? localPathFor(Lecture lecture) {
    for (final item in _downloads) {
      if (item.audioUrl == lecture.audioUrl) {
        return item.identifier;
      }
    }

    return null;
  }

  Future<void> init() async {
    final prefs =
        await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final List<dynamic> data =
          jsonDecode(raw) as List<dynamic>;

      _downloads.clear();

      for (final item in data) {
        final map =
            Map<String, dynamic>.from(item as Map);

        final path =
            map['localPath']?.toString();

        if (path == null || path.isEmpty) {
          continue;
        }

        if (File(path).existsSync()) {
          _downloads.add(
            Lecture(
              title:
                  map['title']?.toString() ?? '',
              section:
                  map['section']?.toString() ?? '',
              audioUrl:
                  map['audioUrl']?.toString() ?? '',
              identifier: path,
            ),
          );
        }
      }

      notifyListeners();
    } catch (_) {
      _downloads.clear();
    }
  }

  Future<void> downloadLecture(
    Lecture lecture,
  ) async {
    final url = lecture.audioUrl;

    if (isDownloaded(lecture) ||
        isDownloading(lecture)) {
      return;
    }

    _downloading.add(url);
    _progress[url] = 0.0;
    notifyListeners();

    try {
      final directory =
          await getApplicationDocumentsDirectory();

      final extension =
          _fileExtension(url);

      final fileName =
          '${lecture.identifier}_${DateTime.now().millisecondsSinceEpoch}$extension';

      final filePath =
          '${directory.path}/$fileName';

      await _dio.download(
        url,
        filePath,
        onReceiveProgress:
            (received, total) {
          if (total > 0) {
            _progress[url] =
                (received / total)
                    .clamp(0.0, 1.0);

            notifyListeners();
          }
        },
      );

      // إظهار 100% للمستخدم قبل تحويل الزر
      // إلى علامة الاكتمال.
      _progress[url] = 1.0;
      notifyListeners();

      await Future.delayed(
        const Duration(milliseconds: 350),
      );

      _downloads.add(
        Lecture(
          title: lecture.title,
          section: lecture.section,
          audioUrl: lecture.audioUrl,
          identifier: filePath,
        ),
      );

      _progress.remove(url);

      await _save();

      notifyListeners();
    } catch (_) {
      _progress.remove(url);
      notifyListeners();
    } finally {
      _downloading.remove(url);
      notifyListeners();
    }
  }

  Future<void> deleteDownload(
    Lecture lecture,
  ) async {
    final index = _downloads.indexWhere(
      (item) => item.audioUrl == lecture.audioUrl,
    );

    if (index == -1) {
      return;
    }

    final item = _downloads[index];

    try {
      final file =
          File(item.identifier);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    _downloads.removeAt(index);

    await _save();

    notifyListeners();
  }

  Future<void> _save() async {
    final prefs =
        await SharedPreferences.getInstance();

    final data = _downloads
        .map(
          (lecture) => {
            'title': lecture.title,
            'section': lecture.section,
            'audioUrl': lecture.audioUrl,
            'localPath': lecture.identifier,
          },
        )
        .toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  String _fileExtension(String url) {
    final cleanUrl =
        url.split('?').first.toLowerCase();

    if (cleanUrl.endsWith('.m4a')) {
      return '.m4a';
    }

    if (cleanUrl.endsWith('.mp3')) {
      return '.mp3';
    }

    return '.mp3';
  }
}
