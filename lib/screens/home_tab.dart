import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/archive_service.dart';
import '../services/audio_player_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
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
      final lectures = await ArchiveService.fetchAllLectures();
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _WelcomeCard(),
        const SizedBox(height: 24),
        Text(
          'مختارات من المحاضرات',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.lightText,
          ),
        ),
        const SizedBox(height: 12),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Column(
        children: List.generate(
          3,
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
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.secondaryText.withOpacity(0.6), size: 32),
            const SizedBox(height: 10),
            Text(
              'تعذر الاتصال بالإنترنت',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'تأكد من اتصالك وحاول مرة أخرى',
              style: TextStyle(
                  color: AppColors.secondaryText.withOpacity(0.6),
                  fontSize: 10),
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

    final preview = _lectures!.take(6).toList();

    return Column(
      children: preview
          .map((lecture) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LectureCard(lecture: lecture),
              ))
          .toList(),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'استمع إلى أحدث المواعظ والبرامج والخطب العلمية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'تصفح كل الأقسام',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final Lecture lecture;
  const _LectureCard({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;

    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final isThisPlaying = audioService.currentLecture?.audioUrl ==
                lecture.audioUrl &&
            audioService.isPlaying;

        return GestureDetector(
          onTap: () => audioService.playLecture(lecture),
          child: Container(
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
                Icon(
                  isThisPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: AppColors.primaryTeal,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainText,
                        ),
                      ),
                      Text(
                        lecture.section,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondaryText.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.bookmark_border,
                    color: AppColors.secondaryText.withOpacity(0.7),
                    size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
