import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';

class DebugLog {
  static final List<String> entries = [];

  static void add(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    entries.add('[$time] $message');

    if (entries.length > 100) {
      entries.removeAt(0);
    }
  }
}

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  Lecture? _currentLecture;
  List<Lecture> _queue = [];
  bool _repeat = false;

  AudioPlayerHandler() {
    DebugLog.add('AudioPlayerHandler created');

    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (e) {
        DebugLog.add('playbackEventStream ERROR: $e');
      },
    );

    _player.processingStateStream.listen((state) async {
      DebugLog.add('processingState: $state');

      if (state == ProcessingState.completed) {
        if (_repeat) {
          await _player.seek(Duration.zero);
          await _player.play();
        } else {
          await playNext();
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
    try {
      final processingState = {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState];

      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing)
              MediaControl.pause
            else
              MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState:
              processingState ?? AudioProcessingState.idle,
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
        ),
      );

      DebugLog.add(
        'broadcastState OK: playing=${_player.playing}, '
        'position=${_player.position}',
      );
    } catch (e) {
      DebugLog.add('broadcastState ERROR: $e');
    }
  }

  Future<void> playLecture(
    Lecture lecture, {
    List<Lecture>? queue,
  }) async {
    DebugLog.add('playLecture called: ${lecture.title}');

    if (queue != null && queue.isNotEmpty) {
      _queue = List<Lecture>.from(queue);

      final mediaItems = _queue.map((item) {
        return MediaItem(
          id: item.audioUrl,
          title: item.title,
          artist: item.section,
          album: 'الشيخ د. محمد الأمين إسماعيل',
          artUri: Uri.parse(
            'android.resource://com.sheikhapp.temp_scaffold/mipmap/ic_launcher',
          ),
        );
      }).toList();

      this.queue.add(mediaItems);
    }

    if (_currentLecture?.audioUrl == lecture.audioUrl) {
      await togglePlayPause();
      return;
    }

    _currentLecture = lecture;
    notifyListeners();

    final item = MediaItem(
      id: lecture.audioUrl,
      title: lecture.title,
      artist: lecture.section,
      album: 'الشيخ د. محمد الأمين إسماعيل',
      artUri: Uri.parse(
        'android.resource://com.sheikhapp.temp_scaffold/mipmap/ic_launcher',
      ),
    );

    try {
      mediaItem.add(item);
      DebugLog.add('mediaItem.add OK');

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(lecture.audioUrl),
          tag: item,
        ),
      );

      DebugLog.add('AudioSource set successfully');

      await _player.play();

      DebugLog.add('just_audio play successfully');
    } catch (e) {
      DebugLog.add('JUST AUDIO PLAY ERROR: $e');
    }

    notifyListeners();
  }

  @override
  Future<void> play() async {
    try {
      if (_player.audioSource == null) {
        DebugLog.add('PLAY: no audio source');
        return;
      }

      await _player.play();

      DebugLog.add('PLAY successfully');
    } catch (e) {
      DebugLog.add('PLAY ERROR: $e');
    }

    notifyListeners();
  }

  @override
  Future<void> pause() async {
    try {
      await _player.pause();

      DebugLog.add('PAUSE successfully');
    } catch (e) {
      DebugLog.add('PAUSE ERROR: $e');
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
    try {
      await _player.seek(position);
      DebugLog.add('SEEK: $position');
    } catch (e) {
      DebugLog.add('SEEK ERROR: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();

      DebugLog.add('STOP successfully');
    } catch (e) {
      DebugLog.add('STOP ERROR: $e');
    }

    _currentLecture = null;
    mediaItem.add(null);

    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.play,
        ],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
      ),
    );

    notifyListeners();

    await super.stop();
  }

  Future<void> skipForward() async {
    try {
      final newPosition =
          _player.position + const Duration(seconds: 10);

      final target = newPosition > duration ? duration : newPosition;

      await _player.seek(target);

      DebugLog.add('SKIP FORWARD: $target');
    } catch (e) {
      DebugLog.add('SKIP FORWARD ERROR: $e');
    }
  }

  Future<void> skipBackward() async {
    try {
      final newPosition =
          _player.position - const Duration(seconds: 10);

      final target =
          newPosition < Duration.zero ? Duration.zero : newPosition;

      await _player.seek(target);

      DebugLog.add('SKIP BACKWARD: $target');
    } catch (e) {
      DebugLog.add('SKIP BACKWARD ERROR: $e');
    }
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();

    DebugLog.add('REPEAT: $_repeat');
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) {
      return false;
    }

    final index = _queue.indexWhere(
      (lecture) =>
          lecture.audioUrl == _currentLecture!.audioUrl,
    );

    return index != -1 && index < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) {
      return false;
    }

    final index = _queue.indexWhere(
      (lecture) =>
          lecture.audioUrl == _currentLecture!.audioUrl,
    );

    return index > 0;
  }

  @override
  Future<void> skipToNext() async {
    await playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await playPrevious();
  }

  Future<void> playNext() async {
    if (!hasNext) {
      DebugLog.add('NEXT: no next lecture');
      return;
    }

    final index = _queue.indexWhere(
      (lecture) =>
          lecture.audioUrl == _currentLecture!.audioUrl,
    );

    final next = _queue[index + 1];

    DebugLog.add('NEXT: ${next.title}');

    await playLecture(
      next,
      queue: _queue,
    );
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) {
      DebugLog.add('PREVIOUS: no previous lecture');
      return;
    }

    final index = _queue.indexWhere(
      (lecture) =>
          lecture.audioUrl == _currentLecture!.audioUrl,
    );

    final previous = _queue[index - 1];

    DebugLog.add('PREVIOUS: ${previous.title}');

    await playLecture(
      previous,
      queue: _queue,
    );
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}

class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._internal();

  static final AudioPlayerService instance =
      AudioPlayerService._internal();

  late AudioPlayerHandler _handler;

  bool _initialized = false;

  Future<void> init(AudioPlayerHandler handler) async {
    _handler = handler;

    _handler.addListener(notifyListeners);

    _initialized = true;

    notifyListeners();
  }

  bool get isInitialized => _initialized;

  Lecture? get currentLecture =>
      _initialized ? _handler.currentLecture : null;

  bool get isPlaying =>
      _initialized ? _handler.isPlaying : false;

  bool get isRepeat =>
      _initialized ? _handler.isRepeat : false;

  Duration get position =>
      _initialized ? _handler.position : Duration.zero;

  Duration get duration =>
      _initialized ? _handler.duration : Duration.zero;

  bool get hasNext =>
      _initialized ? _handler.hasNext : false;

  bool get hasPrevious =>
      _initialized ? _handler.hasPrevious : false;

  Future<void> playLecture(
    Lecture lecture, {
    List<Lecture>? queue,
  }) =>
      _handler.playLecture(
        lecture,
        queue: queue,
      );

  Future<void> togglePlayPause() =>
      _handler.togglePlayPause();

  Future<void> seek(Duration position) =>
      _handler.seek(position);

  Future<void> skipForward() =>
      _handler.skipForward();

  Future<void> skipBackward() =>
      _handler.skipBackward();

  void toggleRepeat() =>
      _handler.toggleRepeat();

  Future<void> playNext() =>
      _handler.playNext();

  Future<void> playPrevious() =>
      _handler.playPrevious();
}
