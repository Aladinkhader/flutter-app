import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/lecture.dart';

// ================================
// تعريف AudioPlayerHandler داخل نفس الملف
// ================================
class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: _computeControls(),
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactDeviceActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
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
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> setQueue(List<MediaItem> queue) async {
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

    super.setQueue(queue);
    if (queue.isNotEmpty) {
      mediaItem.add(queue.first);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    final queue = this.queue.value;
    if (index >= 0 && index < queue.length) {
      mediaItem.add(queue[index]);
    }
  }

  Set<MediaControl> _computeControls() {
    final isPlaying = playbackState.value.playing;
    if (isPlaying) {
      return {
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.stop,
      };
    } else {
      return {
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      };
    }
  }

  @override
  Future<void> onDestroy() async {
    await _player.dispose();
    super.onDestroy();
  }
}

// ================================
// AudioPlayerService
// ================================
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  static AudioPlayerService get instance => _instance;

  late AudioPlayerHandler _handler;

  Future<void> init(AudioPlayerHandler handler) async {
    _handler = handler;
  }

  // دالة تشغيل محاضرة متوافقة مع Lecture الحالي
  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    final items = <MediaItem>[];

    if (queue != null && queue.isNotEmpty) {
      items.addAll(queue.map((lec) => MediaItem(
            id: lec.identifier,  // استخدام identifier كـ id
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

    // تحديد الفهرس الصحيح
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

  // دوال إضافية للتحكم
  bool get isPlaying => _handler.playbackState.value.playing;
  Duration get currentPosition => _handler.playbackState.value.position;
  Duration get duration => _handler.playbackState.value.duration ?? Duration.zero;

  // الحصول على المحاضرة الحالية
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
