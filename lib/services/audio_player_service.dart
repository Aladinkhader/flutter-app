import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';
import 'downloads_service.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  Lecture? _currentLecture;
  List<Lecture> _queue = [];
  bool _repeat = false;

  AudioPlayerHandler() {
    _player.playbackEventStream.listen(_broadcastState);
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

  Lecture? get currentLecture => _currentLecture;
  bool get isPlaying => _player.playing;
  bool get isRepeat => _repeat;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  AudioPlayer get player => _player;

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      speed: _player.speed,
    ));
  }

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

    mediaItem.add(MediaItem(
      id: lecture.audioUrl,
      title: lecture.title,
      artist: lecture.section,
      album: 'الشيخ د. محمد الأمين إسماعيل',
    ));

    try {
      final localPath = DownloadsService.instance.localPathFor(lecture);
      if (localPath != null) {
        await _player.setFilePath(localPath);
      } else {
        await _player.setUrl(lecture.audioUrl);
      }
      await _player.play();
    } catch (_) {}
    notifyListeners();
  }

  @override
  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentLecture = null;
    notifyListeners();
    await super.stop();
  }

  Future<void> skipForward() async {
    final newPosition = position + const Duration(seconds: 10);
    await _player.seek(newPosition > duration ? duration : newPosition);
  }

  Future<void> skipBackward() async {
    final newPosition = position - const Duration(seconds: 10);
    await _player
        .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index =
        _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return index != -1 && index < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index =
        _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    return index > 0;
  }

  @override
  Future<void> skipToNext() => playNext();

  @override
  Future<void> skipToPrevious() => playPrevious();

  Future<void> playNext() async {
    if (!hasNext) return;
    final index =
        _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    final next = _queue[index + 1];
    await playLecture(next, queue: _queue);
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    final index =
        _queue.indexWhere((l) => l.audioUrl == _currentLecture!.audioUrl);
    final prev = _queue[index - 1];
    await playLecture(prev, queue: _queue);
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._internal();
  static final AudioPlayerService instance = AudioPlayerService._internal();

  late AudioPlayerHandler _handler;
  bool _initialized = false;

  Future<void> init(AudioPlayerHandler handler) async {
    _handler = handler;
    _handler.addListener(notifyListeners);
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Lecture? get currentLecture => _initialized ? _handler.currentLecture : null;
  bool get isPlaying => _initialized ? _handler.isPlaying : false;
  bool get isRepeat => _initialized ? _handler.isRepeat : false;
  Duration get position => _initialized ? _handler.position : Duration.zero;
  Duration get duration => _initialized ? _handler.duration : Duration.zero;
  bool get hasNext => _initialized ? _handler.hasNext : false;
  bool get hasPrevious => _initialized ? _handler.hasPrevious : false;

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) =>
      _handler.playLecture(lecture, queue: queue);
  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> skipForward() => _handler.skipForward();
  Future<void> skipBackward() => _handler.skipBackward();
  void toggleRepeat() => _handler.toggleRepeat();
  Future<void> playNext() => _handler.playNext();
  Future<void> playPrevious() => _handler.playPrevious();
}
