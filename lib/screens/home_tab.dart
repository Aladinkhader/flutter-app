import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/archive_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../widgets/shimmer_lecture_card.dart';
import '../widgets/pulsing_border.dart';
import 'full_player.dart';

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

  void _openLecture(Lecture lecture, List<Lecture> queue) {
    AudioPlayerService.instance.playLecture(lecture, queue: queue);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _WelcomeCard(),
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
      return const ShimmerLectureList(count: 4);
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
                child: _LectureCard(
                  lecture: lecture,
                  onTap: () => _openLecture(lecture, preview),
                ),
              ))
          .toList(),
    );
  }
}

class _WelcomeCard extends StatefulWidget {
  const _WelcomeCard();

  @override
  State<_WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<_WelcomeCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() => _pressed = value);
    if (!value) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _pressed ? -3 : 0, 0),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? AppColors.primaryTeal
                  : AppColors.primaryTeal.withOpacity(0.4),
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.25),
                      blurRadius: 15,
                    ),
                  ]
                : [
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
        ),
      ),
    );
  }
}

class _LectureCard extends StatefulWidget {
  final Lecture lecture;
  final VoidCallback onTap;
  const _LectureCard({required this.lecture, required this.onTap});

  @override
  State<_LectureCard> createState() => _LectureCardState();
}

class _LectureCardState extends State<_LectureCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() => _pressed = value);
    if (!value) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final favoritesService = FavoritesService.instance;
    final downloadsService = DownloadsService.instance;

    return AnimatedBuilder(
      animation:
          Listenable.merge([audioService, favoritesService, downloadsService]),
      builder: (context, _) {
        final isThisPlaying = audioService.currentLecture?.audioUrl ==
                widget.lecture.audioUrl &&
            audioService.isPlaying;
        final isFav = favoritesService.isFavorite(widget.lecture);
        final isDownloaded = downloadsService.isDownloaded(widget.lecture);
        final isDownloading = downloadsService.isDownloading(widget.lecture);
        final progress = downloadsService.progressFor(widget.lecture);

        return PulsingGlow(
          active: isThisPlaying,
          child: GestureDetector(
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                transform:
                    Matrix4.translationValues(0, _pressed ? -3 : 0, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pressed
                      ? const Color(0xFF165652)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _pressed || isThisPlaying
                        ? AppColors.primaryTeal
                        : AppColors.cardGradientStart.withOpacity(0.5),
                  ),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.25),
                            blurRadius: 15,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isDownloaded || isDownloading
                          ? null
                          : () => downloadsService
                              .downloadLecture(widget.lecture),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: isDownloading
                            ? CircularProgressIndicator(
                                value: progress > 0 ? progress : null,
                                strokeWidth: 2,
                                color: AppColors.primaryTeal,
                              )
                            : Icon(
                                isDownloaded
                                    ? Icons.check_circle
                                    : Icons.download_rounded,
                                color: isDownloaded
                                    ? AppColors.primaryTeal
                                    : AppColors.secondaryText
                                        .withOpacity(0.7),
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lecture.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainText,
                            ),
                          ),
                          Text(
                            widget.lecture.section,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondaryText.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          favoritesService.toggleFavorite(widget.lecture),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
