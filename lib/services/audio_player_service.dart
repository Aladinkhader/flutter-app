import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._internal() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());
  }

  static final AudioPlayerService instance = AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  Lecture? _currentLecture;

  Lecture? get currentLecture => _currentLecture;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  AudioPlayer get player => _player;

  Future<void> playLecture(Lecture lecture) async {
    if (_currentLecture?.audioUrl == lecture.audioUrl) {
      await togglePlayPause();
      return;
    }
    _currentLecture = lecture;
    notifyListeners();
    try {
      await _player.setUrl(lecture.audioUrl);
      await _player.play();
    } catch (_) {
      // ممكن نعرض توست خطأ هنا لاحقًا
    }
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipForward() async {
    final newPosition = position + const Duration(seconds: 10);
    await _player.seek(newPosition > duration ? duration : newPosition);
  }

  Future<void> skipBackward() async {
    final newPosition = position - const Duration(seconds: 10);
    await _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }
}
