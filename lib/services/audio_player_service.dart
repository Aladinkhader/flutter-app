import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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

  Future<void> init() async {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
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

  // دالة تشغيل المحاضرة وربطها بشرائط إشعارات النظام مباشرة
  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    _currentLecture = lecture;
    _lectureQueue = (queue != null && queue.isNotEmpty) ? queue : [lecture];
    _currentIndex = _lectureQueue.indexOf(lecture);
    if (_currentIndex == -1) _currentIndex = 0;

    final audioSources = _lectureQueue.map((lec) {
      return AudioSource.uri(
        Uri.parse(lec.audioUrl),
        tag: MediaItem(
          id: lec.id.toString(),
          album: lec.section,
          title: lec.title,
          artist: lec.sheikhName ?? 'الشيخ د. محمد الأمين إسماعيل',
          artUri: lec.imageUrl != null ? Uri.parse(lec.imageUrl!) : null,
        ),
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

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Duration get currentPosition => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
