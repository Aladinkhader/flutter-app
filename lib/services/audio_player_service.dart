import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._internal() {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
    _player.durationStream.listen((_) => notifyListeners());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_repeat) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          playNext();
        }
      }
    });
  }

  static final AudioPlayerService instance = AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  Lecture? _currentLecture;
  List<Lecture> _queue = [];
  bool _repeat = false;

  Lecture? get currentLecture => _currentLecture;
  bool get isPlaying => _player.playing;
  bool get isRepeat => _repeat;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  AudioPlayer get player => _player;

  /// يشغل محاضرة، مع تحديد قائمة (Queue) اختيارية عشان يقدر يشغل "التالي"
  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    if (queue != null) {
      _queue = queue;
    }

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

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return index != -1 && index < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return index > 0;
  }

  Future<void> playNext() async {
    if (!hasNext) return;
    final index = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    final next = _queue[index + 1];
    _currentLecture = next;
    notifyListeners();
    try {
      await _player.setUrl(next.audioUrl);
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    final index = _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    final prev = _queue[index - 1];
    _currentLecture = prev;
    notifyListeners();
    try {
      await _player.setUrl(prev.audioUrl);
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }
}
