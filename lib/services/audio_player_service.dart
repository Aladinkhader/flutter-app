import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';

// كلاس مخصص لبيانات الصوت (بديل MediaItem)
class AudioItem {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? artUrl;
  final String url;

  AudioItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.artUrl,
    required this.url,
  });
}

// كلاس Lecture مؤقت للتوافق (سيتم استيراده من models لاحقاً)
// لكننا سنعرفه هنا لتجنب أخطاء الاستيراد
class Lecture {
  final int id;
  final String title;
  final String? sheikhName;
  final String? imageUrl;
  final String audioUrl;

  Lecture({
    required this.id,
    required this.title,
    this.sheikhName,
    this.imageUrl,
    required this.audioUrl,
  });
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // إضافة getter instance للتوافق مع الكود القديم
  static AudioPlayerService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  List<AudioItem> _queue = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  final StreamController<bool> _playbackStateController = StreamController<bool>.broadcast();
  final StreamController<int> _currentIndexController = StreamController<int>.broadcast();

  Stream<bool> get playbackStateStream => _playbackStateController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  bool get isPlaying => _isPlaying;
  int get currentIndex => _currentIndex;
  List<AudioItem> get queue => _queue;

  // دالة playLecture للتوافق مع الكود القديم
  Future<void> playLecture(Lecture lecture, {List<Lecture>? queue}) async {
    if (queue != null && queue.isNotEmpty) {
      // تحويل القائمة إلى AudioItem
      final items = queue.map((lec) => AudioItem(
        id: lec.id.toString(),
        title: lec.title,
        artist: lec.sheikhName ?? 'الشيخ د. محمد الأمين إسماعيل',
        album: 'محاضرات',
        artUrl: lec.imageUrl,
        url: lec.audioUrl,
      )).toList();
      final startIndex = queue.indexOf(lecture);
      setQueue(items, startIndex: startIndex);
    } else {
      // تشغيل محاضرة واحدة فقط
      final item = AudioItem(
        id: lecture.id.toString(),
        title: lecture.title,
        artist: lecture.sheikhName ?? 'الشيخ د. محمد الأمين إسماعيل',
        album: 'محاضرات',
        artUrl: lecture.imageUrl,
        url: lecture.audioUrl,
      );
      setQueue([item], startIndex: 0);
    }
    await play();
  }

  Future<void> init() async {
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [],
      ),
    );

    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        _playbackStateController.add(_isPlaying);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _next();
      }
    });
  }

  void setQueue(List<AudioItem> items, {int startIndex = 0}) {
    _queue = items;
    _currentIndex = startIndex.clamp(0, items.length - 1);

    final audioSources = items.map((item) {
      return AudioSource.uri(
        Uri.parse(item.url),
        tag: AudioMetadata(
          id: item.id,
          title: item.title,
          artist: item.artist ?? 'الشيخ د. محمد الأمين إسماعيل',
          album: item.album ?? 'محاضرات',
          artUri: item.artUrl != null ? Uri.parse(item.artUrl!) : null,
        ),
      );
    }).toList();

    _player.setAudioSource(
      ConcatenatingAudioSource(
        children: audioSources,
      ),
      initialIndex: _currentIndex,
    );

    _currentIndexController.add(_currentIndex);
  }

  Future<void> play() async {
    if (_queue.isEmpty) return;
    await _player.play();
    _isPlaying = true;
    _playbackStateController.add(true);
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _playbackStateController.add(false);
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _playbackStateController.add(false);
  }

  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    _currentIndexController.add(_currentIndex);
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  Future<void> _next() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
      await _player.seekToNext();
    } else {
      await stop();
    }
  }

  Future<void> next() async {
    if (_currentIndex < _queue.length - 1) {
      await _player.seekToNext();
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
    }
  }

  Future<void> previous() async {
    if (_currentIndex > 0) {
      await _player.seekToPrevious();
      _currentIndex--;
      _currentIndexController.add(_currentIndex);
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Duration get currentPosition => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  void dispose() {
    _player.dispose();
    _playbackStateController.close();
    _currentIndexController.close();
  }
}
