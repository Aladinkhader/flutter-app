import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import '../models/lecture.dart';
import 'downloads_service.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();
  static AudioPlayerService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  Lecture? _currentLecture;
  Lecture? get currentLecture => _currentLecture;

  List<Lecture> _queue = [];
  bool _repeat = false;

  bool get isPlaying => _player.playing;
  bool get isRepeat => _repeat;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> init() async {
    _player.playerStateStream.listen((state) {
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        if (_repeat) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          playNext();
        }
      }
    });
    _player.positionStream.listen((_) => notifyListeners());
  }

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    if (queue != null) _queue = queue;

    if (_currentLecture?.audioUrl == lecture.audioUrl) {
      await togglePlayPause();
      return;
    }
    _currentLecture = lecture;
    notifyListeners();

    try {
      final localPath = DownloadsService.instance.localPathFor(lecture);
      final tag = MediaItem(
        id: lecture.audioUrl,
        title: lecture.title,
        artist: lecture.section,
        album: 'الشيخ د. محمد الأمين إسماعيل',
      );

      if (localPath != null) {
        await _player.setAudioSource(
          AudioSource.file(localPath, tag: tag),
        );
      } else {
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(lecture.audioUrl), tag: tag),
        );
      }
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipForward() async {
    final p = position + const Duration(seconds: 10);
    await _player.seek(p > duration ? duration : p);
  }

  Future<void> skipBackward() async {
    final p = position - const Duration(seconds: 10);
    await _player.seek(p < Duration.zero ? Duration.zero : p);
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final i = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return i != -1 && i < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final i = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return i > 0;
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    final i = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    await playLecture(_queue[i + 1], queue: _queue);
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    final i = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    await playLecture(_queue[i - 1], queue: _queue);
  }
}
