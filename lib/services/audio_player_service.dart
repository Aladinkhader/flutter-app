import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';

// ================================
// AudioPlayerHandler
// ================================
class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  List<MediaItem> _queue = [];

  AudioPlayerHandler() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: _computeControls(),
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
      ));
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  @override
  Future<void> play() async {
    await _player.play();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      controls: _computeControls(),
    ));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: _computeControls(),
    ));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      controls: const [],
    ));
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    final index = _player.currentIndex ?? 0;
    if (index < _queue.length) {
      mediaItem.add(_queue[index]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    final index = _player.currentIndex ?? 0;
    if (index < _queue.length) {
      mediaItem.add(_queue[index]);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setQueue(List<MediaItem> queue) async {
    _queue = queue;
    final sources = queue.map((item) {
      final url = item.extras?['url'] as String?;
      if (url == null) throw Exception('URL missing for media item');
      return AudioSource.uri(
        Uri.parse(url),
        tag: item,
      );
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: 0,
    );

    if (queue.isNotEmpty) {
      mediaItem.add(queue.first);
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(_queue[index]);
  }

  List<MediaControl> _computeControls() {
    final isPlaying = playbackState.value.playing;
    if (isPlaying) {
      return [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.stop,
      ];
    } else {
      return [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ];
    }
  }

  @override
  Future<void> onDestroy() async {
    await _player.dispose();
  }

  Duration get duration => _player.duration ?? Duration.zero;
  Duration get position => _player.position;
}

// ================================
// AudioPlayerService (يورث ChangeNotifier)
// ================================
class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  static AudioPlayerService get instance => _instance;

  late AudioPlayerHandler _handler;
  bool _isPlaying = false;

  Future<void> init(AudioPlayerHandler handler) async {
    _handler = handler;
    _handler.playbackState.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  Duration get duration => _handler.duration;
  Duration get position => _handler.position;

  void togglePlayPause() {
    if (_isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    final items = <MediaItem>[];

    if (queue != null && queue.isNotEmpty) {
      items.addAll(queue.map((lec) => MediaItem(
            id: lec.identifier,
            title: lec.title,
            artist: 'الشيخ د. محمد الأمين إسماعيل',
            album: lec.section.isNotEmpty ? lec.section : 'محاضرات',
            extras: {'url': lec.audioUrl},
          )));
    } else {
      items.add(MediaItem(
        id: lecture.identifier,
        title: lecture.title,
        artist: 'الشيخ د. محمد الأمين إسماعيل',
        album: lecture.section.isNotEmpty ? lecture.section : 'محاضرات',
        extras: {'url': lecture.audioUrl},
      ));
    }

    await _handler.setQueue(items);

    int startIndex = 0;
    if (queue != null && queue.isNotEmpty) {
      startIndex = queue.indexWhere((lec) => lec.identifier == lecture.identifier);
      if (startIndex == -1) startIndex = 0;
    }

    if (startIndex > 0) {
      await _handler.skipToQueueItem(startIndex);
    }
    await _handler.play();
  }

  Future<void> pause() async => _handler.pause();
  Future<void> stop() async => _handler.stop();
  Future<void> play() async => _handler.play();
  Future<void> next() async => _handler.skipToNext();
  Future<void> previous() async => _handler.skipToPrevious();

  Lecture? get currentLecture {
    final item = _handler.mediaItem.value;
    if (item == null) return null;
    return Lecture(
      title: item.title,
      section: item.album ?? '',
      audioUrl: item.extras?['url'] as String? ?? '',
      identifier: item.id,
    );
  }
}
