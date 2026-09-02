import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/lecture.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  static AudioPlayerService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  Lecture? _currentLecture;
  Lecture? get currentLecture => _currentLecture;

  List<Lecture> _lectureQueue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  int get currentIndex => _currentIndex;

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  Future<void> init() async {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((_) {
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _next();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && _lectureQueue.isNotEmpty && index < _lectureQueue.length) {
        _currentIndex = index;
        _currentLecture = _lectureQueue[index];
        notifyListeners();
      }
    });
  }

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    _currentLecture = lecture;
    _lectureQueue = (queue != null && queue.isNotEmpty) ? queue : [lecture];
    _currentIndex = _lectureQueue.indexOf(lecture);
    if (_currentIndex == -1) _currentIndex = 0;

    final audioSources = _lectureQueue.map((lec) {
      return AudioSource.uri(
        Uri.parse(lec.audioUrl),
      );
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: _currentIndex,
    );

    await play();
    notifyListeners();
  }

  Future<void> play() async {
    await _player.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> _next() async {
    if (_currentIndex < _lectureQueue.length - 1) {
      _currentIndex++;
      _currentLecture = _lectureQueue[_currentIndex];
      await _player.seekToNext();
      notifyListeners();
    } else {
      await stop();
    }
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> playNext() async => next();

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> playPrevious() async => previous();

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
