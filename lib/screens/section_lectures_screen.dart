import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/archive_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';

class SectionLecturesScreen extends StatefulWidget {
  final String identifier;
  final String sectionTitle;

  const SectionLecturesScreen({
    super.key,
    required this.identifier,
    required this.sectionTitle,
  });

  @override
  State<SectionLecturesScreen> createState() => _SectionLecturesScreenState();
}

class _SectionLecturesScreenState extends State<SectionLecturesScreen> {
  List<Lecture>? _lectures;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final lectures = await ArchiveService.fetchSectionLectures(
          widget.identifier, widget.sectionTitle);
      setState(() {
        _lectures = lectures;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios,
                color: AppColors.secondaryText, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.sectionTitle,
            style: const TextStyle(
              color: AppColors.mainText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return ListView(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    if (_error || _lectures == null || _lectures!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.secondaryText.withOpacity(0.6), size: 32),
            const SizedBox(height: 10),
            Text(
              'تعذر تحميل المحاضرات',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _lectures!.length,
      itemBuilder: (context, index) {
        final lecture = _lectures![index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LectureRow(lecture: lecture),
        );
      },
    );
  }
}

class _LectureRow extends StatelessWidget {
  final Lecture lecture;
  const _LectureRow({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final favoritesService = FavoritesService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([audioService, favoritesService]),
      builder: (context, _) {
        final isThisPlaying =
            audioService.currentLecture?.audioUrl == lecture.audioUrl &&
                audioService.isPlaying;
        final isFav = favoritesService.isFavorite(lecture);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isThisPlaying
                  ? AppColors.primaryTeal
                  : AppColors.cardGradientStart.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => audioService.playLecture(lecture),
                child: Icon(
                  isThisPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: AppColors.primaryTeal,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => audioService.playLecture(lecture),
                  child: Text(
                    lecture.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => favoritesService.toggleFavorite(lecture),
                child: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  color: isFav
                      ? AppColors.primaryTeal
                      : AppColors.secondaryText.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
