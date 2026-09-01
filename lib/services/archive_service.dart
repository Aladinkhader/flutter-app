import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';
import 'downloads_service.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  Lecture? _currentLecture;
  List<Lecture> _queue = [];
  bool _repeat = false;
  bool _listenersAttached = false;

  AudioPlayerHandler() {
    _attachPlayerListeners();
  }

  void _attachPlayerListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _player.playbackEventStream.listen(_broadcastState);

    _player.processingStateStream.listen((state) async {
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
    final processingState = <ProcessingState, AudioProcessingState>{
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState];

    if (processingState == null) return;

    final currentIndex = _currentLecture == null
        ? null
        : _queue.indexWhere(
            (lecture) => lecture.audioUrl == _currentLecture!.audioUrl,
          );

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: currentIndex == null || currentIndex < 0
            ? null
            : currentIndex,
      ),
    );

    notifyListeners();
  }

  MediaItem _buildMediaItem(Lecture lecture, {Duration? duration}) {
    return MediaItem(
      id: lecture.audioUrl,
      title: lecture.title,
      artist: lecture.section,
      album: 'الشيخ د. محمد الأمين إسماعيل',
      duration: duration,
      artUri: Uri.parse(
        'android.resource://com.sheikhapp.temp_scaffold/mipmap/ic_launcher',
      ),
    );
  }

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    if (queue != null) {
      _queue = queue;
      this.queue.add(
        _queue
            .map(
              (item) => _buildMediaItem(item),
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

    final item = _buildMediaItem(lecture);
    mediaItem.add(item);

    try {
      final localPath = DownloadsService.instance.localPathFor(lecture);

      if (localPath != null) {
        await _player.setFilePath(localPath);
      } else {
        await _player.setUrl(lecture.audioUrl);
      }

      final loadedDuration = _player.duration;
      if (loadedDuration != null) {
        mediaItem.add(item.copyWith(duration: loadedDuration));
      }

      _broadcastState(_player.playbackEvent);
      await _player.play();
      _broadcastState(_player.playbackEvent);
    } catch (error) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: error.toString(),
        ),
      );
      notifyListeners();
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    _broadcastState(_player.playbackEvent);
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState(_player.playbackEvent);
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
    _broadcastState(_player.playbackEvent);
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _currentLecture = null;
    mediaItem.add(null);
    notifyListeners();
    await super.stop();
  }

  @override
  Future<void> fastForward() async {
    final newPosition = position + const Duration(seconds: 10);
    await _player.seek(newPosition > duration ? duration : newPosition);
    _broadcastState(_player.playbackEvent);
  }

  @override
  Future<void> rewind() async {
    final newPosition = position - const Duration(seconds: 10);
    await _player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
    _broadcastState(_player.playbackEvent);
  }

  Future<void> skipForward() => fastForward();

  Future<void> skipBackward() => rewind();

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index = _queue.indexWhere(
      (lecture) => lecture.audioUrl == _currentLecture!.audioUrl,
    );
    return index != -1 && index < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) return false;
    final index = _queue.indexWhere(
      (lecture) => lecture.audioUrl == _currentLecture!.audioUrl,
    );
    return index > 0;
  }

  @override
  Future<void> skipToNext() => playNext();

  @override
  Future<void> skipToPrevious() => playPrevious();

  Future<void> playNext() async {
    if (!hasNext) return;
    final index = _queue.indexWhere(
      (lecture) => lecture.audioUrl == _currentLecture!.audioUrl,
    );
    await playLecture(_queue[index + 1], queue: _queue);
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) return;
    final index = _queue.indexWhere(
      (lecture) => lecture.audioUrl == _currentLecture!.audioUrl,
    );
    await playLecture(_queue[index - 1], queue: _queue);
  }

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
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
