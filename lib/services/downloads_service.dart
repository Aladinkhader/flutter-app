import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/lecture.dart';

class DownloadItem {
  final Lecture lecture;
  final String localPath;

  DownloadItem({required this.lecture, required this.localPath});
}

class DownloadsService extends ChangeNotifier {
  DownloadsService._internal();
  static final DownloadsService instance = DownloadsService._internal();

  static const _key = 'downloads_list_v1';
  final Dio _dio = Dio();

  List<DownloadItem> _downloads = [];
  final Map<String, double> _progress = {}; // audioUrl -> 0.0-1.0
  final Set<String> _downloading = {};

  List<DownloadItem> get downloads => _downloads;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        _downloads = list
            .map((e) => DownloadItem(
                  lecture: Lecture(
                    title: e['title'],
                    section: e['section'],
                    audioUrl: e['audioUrl'],
                    identifier: e['identifier'],
                  ),
                  localPath: e['localPath'],
                ))
            .where((d) => File(d.localPath).existsSync())
            .toList();
      } catch (_) {
        _downloads = [];
      }
    }
    notifyListeners();
  }

  bool isDownloaded(Lecture lecture) {
    return _downloads.any((d) => d.lecture.audioUrl == lecture.audioUrl);
  }

  bool isDownloading(Lecture lecture) {
    return _downloading.contains(lecture.audioUrl);
  }

  double progressFor(Lecture lecture) {
    return _progress[lecture.audioUrl] ?? 0.0;
  }

  String? localPathFor(Lecture lecture) {
    final match = _downloads.firstWhere(
      (d) => d.lecture.audioUrl == lecture.audioUrl,
      orElse: () => DownloadItem(lecture: lecture, localPath: ''),
    );
    return match.localPath.isEmpty ? null : match.localPath;
  }

  Future<bool> downloadLecture(Lecture lecture) async {
    if (isDownloaded(lecture) || isDownloading(lecture)) return false;

    _downloading.add(lecture.audioUrl);
    _progress[lecture.audioUrl] = 0.0;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeFileName =
          '${lecture.identifier}_${lecture.title.hashCode}.mp3';
      final savePath = '${dir.path}/$safeFileName';

      await _dio.download(
        lecture.audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _progress[lecture.audioUrl] = received / total;
            notifyListeners();
          }
        },
      );

      _downloads.add(DownloadItem(lecture: lecture, localPath: savePath));
      _downloading.remove(lecture.audioUrl);
      _progress.remove(lecture.audioUrl);
      notifyListeners();
      await _save();
      return true;
    } catch (_) {
      _downloading.remove(lecture.audioUrl);
      _progress.remove(lecture.audioUrl);
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDownload(Lecture lecture) async {
    final match = _downloads.firstWhere(
      (d) => d.lecture.audioUrl == lecture.audioUrl,
      orElse: () => DownloadItem(lecture: lecture, localPath: ''),
    );
    if (match.localPath.isNotEmpty) {
      final file = File(match.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _downloads.removeWhere((d) => d.lecture.audioUrl == lecture.audioUrl);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_downloads
        .map((d) => {
              'title': d.lecture.title,
              'section': d.lecture.section,
              'audioUrl': d.lecture.audioUrl,
              'identifier': d.lecture.identifier,
              'localPath': d.localPath,
            })
        .toList());
    await prefs.setString(_key, raw);
  }
}
