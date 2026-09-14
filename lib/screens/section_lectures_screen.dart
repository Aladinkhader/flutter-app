import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../services/share_service.dart';
import '../widgets/pulsing_border.dart';
import 'full_player.dart';

class SectionLecturesScreen extends StatefulWidget {
  final String sectionTitle;
  final List<Lecture> lectures;

  const SectionLecturesScreen({
    super.key,
    required this.sectionTitle,
    required this.lectures,
  });

  @override
  State<SectionLecturesScreen> createState() =>
      _SectionLecturesScreenState();
}

class _SectionLecturesScreenState
    extends State<SectionLecturesScreen> {
  late List<Lecture> _lectures;
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _lectures = List<Lecture>.from(widget.lectures);
    _searchController.addListener(_filterLectures);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLectures() {
    final query =
        _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _lectures = List<Lecture>.from(widget.lectures);
      } else {
        _lectures = widget.lectures
            .where(
              (lecture) =>
                  lecture.title
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
      }
    });
  }

  void _openLecture(Lecture lecture) {
    AudioPlayerService.instance.playLecture(
      lecture,
      queue: _lectures,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FullPlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.sectionTitle,
          style: const TextStyle(
            color: AppColors.mainText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.mainText,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.mainText,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'بحث في المحاضرات...',
                hintStyle: TextStyle(
                  color: AppColors.secondaryText
                      .withOpacity(0.6),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.cardDark,
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.secondaryText
                      .withOpacity(0.6),
                  size: 18,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors
                        .cardGradientStart
                        .withOpacity(0.5),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors
                        .cardGradientStart
                        .withOpacity(0.5),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _lectures.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          color: AppColors
                              .secondaryText
                              .withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.only(
                        bottom: 90,
                      ),
                      itemCount: _lectures.length,
                      itemBuilder:
                          (context, index) {
                        final lecture =
                            _lectures[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child: _LectureRow(
                            lecture: lecture,
                            onTap: () =>
                                _openLecture(
                              lecture,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectureRow extends StatefulWidget {
  final Lecture lecture;
  final VoidCallback onTap;

  const _LectureRow({
    required this.lecture,
    required this.onTap,
  });

  @override
  State<_LectureRow> createState() =>
      _LectureRowState();
}

class _LectureRowState
    extends State<_LectureRow> {
  bool _pressed = false;

  static const Color _gold =
      Color(0xFFD6B56E);

  @override
  Widget build(BuildContext context) {
    final audioService =
        AudioPlayerService.instance;
    final favoritesService =
        FavoritesService.instance;
    final downloadsService =
        DownloadsService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([
        audioService,
        favoritesService,
        downloadsService,
      ]),
      builder: (context, _) {
        final isThisPlaying =
            audioService.currentLecture?.audioUrl ==
                    widget.lecture.audioUrl &&
                audioService.isPlaying;

        final isFav =
            favoritesService.isFavorite(
          widget.lecture,
        );

        final isDownloaded =
            downloadsService.isDownloaded(
          widget.lecture,
        );

        final isDownloading =
            downloadsService.isDownloading(
          widget.lecture,
        );

        final progress =
            downloadsService
                .progressFor(widget.lecture)
                .clamp(0.0, 1.0);

        return PulsingGlow(
          active: isThisPlaying,
          child: GestureDetector(
            onTapDown: (_) =>
                setState(() => _pressed = true),
            onTapUp: (_) =>
                setState(() => _pressed = false),
            onTapCancel: () =>
                setState(() => _pressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _pressed ? 1.02 : 1.0,
              duration:
                  const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration:
                    const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                transform:
                    Matrix4.translationValues(
                  0,
                  _pressed ? -3 : 0,
                  0,
                ),
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  16,
                  14,
                  16,
                ),
                decoration: BoxDecoration(
                  color: _pressed
                      ? const Color(0xFF165652)
                      : AppColors.cardDark,
                  borderRadius:
                      BorderRadius.circular(17),
                  border: Border.all(
                    width:
                        isThisPlaying ? 1.5 : 1,
                    color: isThisPlaying
                        ? _gold
                        : _pressed
                            ? AppColors.primaryTeal
                            : AppColors
                                .cardGradientStart
                                .withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        _pressed ? 0.35 : 0.2,
                      ),
                      blurRadius:
                          _pressed ? 18 : 7,
                      offset: Offset(
                        0,
                        _pressed ? 9 : 3,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            _gold.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _gold.withOpacity(0.35),
                        ),
                      ),
                      child: Icon(
                        isThisPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _gold,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap:
                          isDownloaded ||
                                  isDownloading
                              ? null
                              : () =>
                                  downloadsService
                                      .downloadLecture(
                                    widget.lecture,
                                  ),
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: isDownloading
                            ? Stack(
                                alignment:
                                    Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child:
                                        TweenAnimationBuilder<
                                            double>(
                                      tween:
                                          Tween<double>(
                                        begin: 0,
                                        end: progress,
                                      ),
                                      duration:
                                          const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve:
                                          Curves.easeOut,
                                      builder: (
                                        context,
                                        animatedProgress,
                                        _,
                                      ) {
                                        return CircularProgressIndicator(
                                          value:
                                              animatedProgress,
                                          strokeWidth: 2.5,
                                          backgroundColor:
                                              _gold.withOpacity(
                                            0.18,
                                          ),
                                          color: _gold,
                                        );
                                      },
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(
                                      milliseconds: 180,
                                    ),
                                    child: Text(
                                      '${(progress * 100).round()}%',
                                      key: ValueKey(
                                        (progress * 100)
                                            .round(),
                                      ),
                                      style:
                                          const TextStyle(
                                        fontSize: 7,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: _gold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                isDownloaded
                                    ? Icons.check_circle
                                    : Icons
                                        .download_rounded,
                                color: _gold,
                                size: 22,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lecture.title,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  AppColors.mainText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.lecture.section,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors
                                  .secondaryText
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          favoritesService
                              .toggleFavorite(
                        widget.lecture,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () =>
                          ShareService.shareLecture(
                        widget.lecture,
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        color: AppColors.secondaryText
                            .withOpacity(0.7),
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
