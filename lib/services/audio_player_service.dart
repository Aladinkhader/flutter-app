import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import '../models/lecture.dart';
import 'downloads_service.dart';

class DebugLog {
  static final List<String> entries = [];
  static void add(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    entries.add('[$time] $message');
    if (entries.length > 100) entries.removeAt(0);
  }
}

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  Lecture? _currentLecture;
  List<Lecture> _queue = [];
  bool _repeat = false;
  bool _nativePlaying = false;

  static const MethodChannel _nativeChannel =
      MethodChannel('com.sheikhapp.temp_scaffold/native_media');

  AudioPlayerHandler() {
    DebugLog.add('AudioPlayerHandler created');
    _player.playbackEventStream.listen(_broadcastState, onError: (e) {
      DebugLog.add('playbackEventStream ERROR: $e');
    });
    _player.processingStateStream.listen((state) {
      DebugLog.add('processingState: $state');
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
  bool get isPlaying => _nativePlaying || _player.playing;
  bool get isRepeat => _repeat;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  AudioPlayer get player => _player;

  void _broadcastState(PlaybackEvent event) {
    try {
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
      DebugLog.add('broadcastState OK: playing=${_player.playing}');
    } catch (e) {
      DebugLog.add('broadcastState ERROR: $e');
    }
  }

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    DebugLog.add('playLecture called: ${lecture.title}');
    if (queue != null) {
      _queue = queue;
      this.queue.add(
        _queue
            .map(
              (item) => MediaItem(
                id: item.audioUrl,
                title: item.title,
                artist: item.section,
                album: 'الشيخ د. محمد الأمين إسماعيل',
                artUri: Uri.parse(
                  'android.resource://com.sheikhapp.temp_scaffold/mipmap/ic_launcher',
                ),
              ),
            )
            .toList(),
      );
    }

    if (_currentLecture?.audioUrl == lecture.audioUrl) {
      await togglePlayPause();
      return;
    }
    _currentLecture = lecture;
    notifyListeners();

    try {
      final item = MediaItem(
        id: lecture.audioUrl,
        title: lecture.title,
        artist: lecture.section,
        album: 'الشيخ د. محمد الأمين إسماعيل',
        artUri: Uri.parse(
          'android.resource://com.sheikhapp.temp_scaffold/mipmap/ic_launcher',
        ),
      );
      mediaItem.add(item);
      DebugLog.add('mediaItem.add OK');
    } catch (e) {
      DebugLog.add('mediaItem.add ERROR: $e');
    }

    try {
      await _nativeChannel.invokeMethod('nativePlay', {
        'url': lecture.audioUrl,
        'title': lecture.title,
        'artist': lecture.section,
      });
      _nativePlaying = true;
      playbackState.add(
        playbackState.value.copyWith(
          controls: const [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          processingState: AudioProcessingState.ready,
          playing: true,
          updatePosition: Duration.zero,
          speed: 1.0,
        ),
      );
      DebugLog.add('nativePlay called successfully');
    } catch (e) {
      DebugLog.add('NATIVE PLAY ERROR: $e');
    }
    notifyListeners();
  }

  @override
  Future<void> play() async {
    try {
      await _nativeChannel.invokeMethod('nativePlay', {
        'url': _currentLecture?.audioUrl,
        'title': _currentLecture?.title ?? '',
        'artist': _currentLecture?.section ?? '',
      });
      _nativePlaying = true;
    } catch (e) {
      DebugLog.add('NATIVE RESUME ERROR: $e');
    }
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    try {
      await _nativeChannel.invokeMethod('nativePause');
      _nativePlaying = false;
      playbackState.add(
        playbackState.value.copyWith(
          controls: const [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          playing: false,
        ),
      );
    } catch (e) {
      DebugLog.add('NATIVE PAUSE ERROR: $e');
    }
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
    try {
      await _nativeChannel.invokeMethod('nativeStop');
    } catch (e) {
      DebugLog.add('NATIVE STOP ERROR: $e');
    }
    _nativePlaying = false;
    await _player.stop();
    _currentLecture = null;
    mediaItem.add(null);
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
