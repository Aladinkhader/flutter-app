import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/lecture.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<MediaItem> _queue = const [];
  StreamSubscription<PlaybackEvent>? _playbackSubscription;
  StreamSubscription<ProcessingState>? _processingSubscription;

  AudioPlayerHandler() {
    _playbackSubscription = _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: _controls,
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 2],
          processingState: _mapProcessingState(event.processingState),
          playing: _player.playing,
          updatePosition: event.updatePosition,
          bufferedPosition: event.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });

    _processingSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        final index = _player.currentIndex ?? 0;
        if (index < _queue.length - 1) {
          unawaited(skipToNext());
        } else {
          playbackState.add(
            playbackState.value.copyWith(
              playing: false,
              processingState: AudioProcessingState.completed,
              controls: _controls,
            ),
          );
        }
      }
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  List<MediaControl> get _controls => _player.playing
      ? const [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.stop,
        ]
      : const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ];

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty || (_player.currentIndex ?? 0) >= _queue.length - 1) {
      return;
    }
    await _player.seekToNext();
    _publishCurrentItem();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.isEmpty || (_player.currentIndex ?? 0) <= 0) {
      return;
    }
    await _player.seekToPrevious();
    _publishCurrentItem();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setQueue(
    List<MediaItem> items, {
    int initialIndex = 0,
  }) async {
    _queue = List<MediaItem>.unmodifiable(items);

    if (_queue.isEmpty) {
      await _player.stop();
      mediaItem.add(null);
      return;
    }

    final sources = _queue.map((item) {
      final url = item.extras?['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('URL missing for media item');
      }
      return AudioSource.uri(
        Uri.parse(url),
        tag: item,
      );
    }).toList();

    final safeIndex = initialIndex.clamp(0, _queue.length - 1).toInt();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: safeIndex,
      preload: true,
    );
    _publishCurrentItem();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    _publishCurrentItem();
  }

  void _publishCurrentItem() {
    final index = _player.currentIndex ?? 0;
    if (index >= 0 && index < _queue.length) {
      mediaItem.add(_queue[index]);
    }
  }

  Duration get duration => _player.duration ?? Duration.zero;
  Duration get position => _player.position;
  int get currentIndex => _player.currentIndex ?? 0;
}

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal();

  static AudioPlayerService get instance => _instance;

  late AudioPlayerHandler _handler;
  bool _isPlaying = false;
  MediaItem? _currentItem;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;

  Future<void> init(AudioPlayerHandler handler) async {
    await _playbackSubscription?.cancel();
    await _mediaItemSubscription?.cancel();
    _handler = handler;

    _playbackSubscription = _handler.playbackState.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _mediaItemSubscription = _handler.mediaItem.listen((item) {
      _currentItem = item;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  Duration get duration => _handler.duration;
  Duration get position => _handler.position;

  void togglePlayPause() {
    if (_isPlaying) {
      unawaited(_handler.pause());
    } else {
      unawaited(_handler.play());
    }
  }

  Future<void> playLecture(
    Lecture lecture, {
    List<Lecture>? queue,
  }) async {
    final lectures = queue == null || queue.isEmpty ? [lecture] : queue;

    final items = lectures
        .map(
          (item) => MediaItem(
            id: item.identifier,
            title: item.title,
            artist: 'الشيخ د. محمد الأمين إسماعيل',
            album: item.section.isEmpty ? 'محاضرات' : item.section,
            extras: {'url': item.audioUrl},
          ),
        )
        .toList();

    final startIndex = lectures.indexWhere(
      (item) => item.audioUrl == lecture.audioUrl,
    );

    await _handler.setQueue(
      items,
      initialIndex: startIndex < 0 ? 0 : startIndex,
    );
    await _handler.play();
  }

  Future<void> pause() => _handler.pause();
  Future<void> stop() => _handler.stop();
  Future<void> play() => _handler.play();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();
  Future<void> playPrevious() => previous();

  bool get hasPrevious => _handler.currentIndex > 0;

  Future<void> skipBackward() async {
    final target = _handler.position - const Duration(seconds: 10);
    await _handler.seek(target.isNegative ? Duration.zero : target);
  }

  Future<void> skipForward() async {
    final target = _handler.position + const Duration(seconds: 10);
    final max = _handler.duration;
    await _handler.seek(target > max ? max : target);
  }

  Lecture? get currentLecture {
    final item = _currentItem ?? _handler.mediaItem.value;
    if (item == null) return null;

    return Lecture(
      title: item.title,
      section: item.album ?? '',
      audioUrl: item.extras?['url'] as String? ?? '',
      identifier: item.id,
    );
  }

  @override
  void dispose() {
    unawaited(_playbackSubscription?.cancel());
    unawaited(_mediaItemSubscription?.cancel());
    super.dispose();
  }
}
