import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/lecture.dart';
import 'downloads_service.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance =
      AudioPlayerService._internal();

  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal();

  static AudioPlayerService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  Lecture? _currentLecture;
  Lecture? get currentLecture => _currentLecture;

  List<Lecture> _queue = [];
  bool _repeat = false;

  bool get isPlaying => _player.playing;

  bool get isRepeat => _repeat;

  Duration get position => _player.position;

  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> stop() async {
    try {
      debugPrint('MEDIA: stop requested');

      await _player.stop();

      _currentLecture = null;

      debugPrint('MEDIA: player stopped');
    } catch (e, st) {
      debugPrint('MEDIA STOP ERROR: $e');
      debugPrint('$st');
    }

    notifyListeners();
  }

  Future<void> next() => playNext();

  Future<void> init() async {
    debugPrint('MEDIA: AudioPlayerService.init()');

    _player.playerStateStream.listen((state) {
      debugPrint(
        'MEDIA STATE: '
        'playing=${state.playing}, '
        'processing=${state.processingState}',
      );

      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        if (_repeat) {
          debugPrint('MEDIA: repeat enabled');

          _player.seek(Duration.zero);
          _player.play();
        } else {
          debugPrint('MEDIA: playback completed, moving to next');

          playNext();
        }
      }
    });

    _player.positionStream.listen((position) {
      notifyListeners();
    });

    _player.durationStream.listen((duration) {
      debugPrint('MEDIA DURATION: $duration');
      notifyListeners();
    });

    _player.sequenceStateStream.listen((sequenceState) {
      debugPrint(
        'MEDIA SEQUENCE: '
        'index=${sequenceState.currentIndex}, '
        'length=${sequenceState.sequence.length}',
      );
    });

    _player.playbackEventStream.listen(
      (event) {
        debugPrint(
          'MEDIA EVENT: '
          'processing=${event.processingState}, '
          'position=${event.position}',
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('MEDIA PLAYBACK EVENT ERROR: $error');
        debugPrint('$stackTrace');
      },
    );

    debugPrint('MEDIA: AudioPlayerService initialized');
  }

  Future<void> playLecture(
    Lecture lecture, {
    List<Lecture>? queue,
  }) async {
    if (queue != null) {
      _queue = queue;
    }

    if (_currentLecture?.audioUrl == lecture.audioUrl) {
      debugPrint(
        'MEDIA: same lecture selected, toggling play/pause',
      );

      await togglePlayPause();
      return;
    }

    _currentLecture = lecture;
    notifyListeners();

    try {
      final localPath =
          DownloadsService.instance.localPathFor(lecture);

      final Uri audioUri = localPath != null
          ? Uri.file(localPath)
          : Uri.parse(lecture.audioUrl);

      debugPrint('MEDIA: preparing lecture');
      debugPrint('MEDIA TITLE: ${lecture.title}');
      debugPrint('MEDIA URI: $audioUri');

      final mediaItem = MediaItem(
        id: lecture.audioUrl,
        album: 'الشيخ د. محمد الأمين إسماعيل',
        title: lecture.title,
        artist: 'د. محمد الأمين إسماعيل',
      );

      final audioSource = AudioSource.uri(
        audioUri,
        tag: mediaItem,
      );

      debugPrint('MEDIA: setting audio source');

      await _player.setAudioSource(audioSource);

      debugPrint('MEDIA: audio source loaded');

      debugPrint('MEDIA: calling play()');

      await _player.play();

      debugPrint(
        'MEDIA: play() completed, '
        'playing=${_player.playing}',
      );
    } on PlayerException catch (e, st) {
      debugPrint(
        'MEDIA PLAYER EXCEPTION: '
        'code=${e.code}, message=${e.message}',
      );
      debugPrint('$st');
    } catch (e, st) {
      debugPrint('MEDIA GENERAL ERROR: $e');
      debugPrint('$st');
    }

    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    try {
      if (_player.playing) {
        debugPrint('MEDIA: pause requested');

        await _player.pause();

        debugPrint('MEDIA: paused');
      } else {
        debugPrint('MEDIA: play requested');

        await _player.play();

        debugPrint(
          'MEDIA: resumed, playing=${_player.playing}',
        );
      }
    } catch (e, st) {
      debugPrint('MEDIA PLAY/PAUSE ERROR: $e');
      debugPrint('$st');
    }

    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e, st) {
      debugPrint('MEDIA SEEK ERROR: $e');
      debugPrint('$st');
    }
  }

  Future<void> skipForward() async {
    try {
      final p = position + const Duration(seconds: 10);

      await _player.seek(
        p > duration ? duration : p,
      );
    } catch (e, st) {
      debugPrint('MEDIA FORWARD ERROR: $e');
      debugPrint('$st');
    }
  }

  Future<void> skipBackward() async {
    try {
      final p = position - const Duration(seconds: 10);

      await _player.seek(
        p < Duration.zero ? Duration.zero : p,
      );
    } catch (e, st) {
      debugPrint('MEDIA BACKWARD ERROR: $e');
      debugPrint('$st');
    }
  }

  void toggleRepeat() {
    _repeat = !_repeat;

    debugPrint('MEDIA: repeat=$_repeat');

    notifyListeners();
  }

  bool get hasNext {
    if (_currentLecture == null || _queue.isEmpty) {
      return false;
    }

    final i = _queue.indexWhere(
      (l) => l.audioUrl == _currentLecture!.audioUrl,
    );

    return i != -1 && i < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_currentLecture == null || _queue.isEmpty) {
      return false;
    }

    final i = _queue.indexWhere(
      (l) => l.audioUrl == _currentLecture!.audioUrl,
    );

    return i > 0;
  }

  Future<void> playNext() async {
    if (!hasNext) {
      debugPrint('MEDIA: no next lecture');
      return;
    }

    final i = _queue.indexWhere(
      (l) => l.audioUrl == _currentLecture!.audioUrl,
    );

    debugPrint('MEDIA: playing next lecture');

    await playLecture(
      _queue[i + 1],
      queue: _queue,
    );
  }

  Future<void> playPrevious() async {
    if (!hasPrevious) {
      debugPrint('MEDIA: no previous lecture');
      return;
    }

    final i = _queue.indexWhere(
      (l) => l.audioUrl == _currentLecture!.audioUrl,
    );

    debugPrint('MEDIA: playing previous lecture');

    await playLecture(
      _queue[i - 1],
      queue: _queue,
    );
  }
}
