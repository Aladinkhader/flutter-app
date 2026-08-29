import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/archive_service.dart';
import '../services/audio_player_service.dart';
import '../services/favorites_service.dart';
import '../widgets/shimmer_lecture_card.dart';
import 'full_player.dart';

class AllLecturesTab extends StatefulWidget {
  const AllLecturesTab({super.key});

  @override
  State<AllLecturesTab> createState() => _AllLecturesTabState();
}

class _AllLecturesTabState extends State<AllLecturesTab> {
  List<Lecture>? _lectures;
  List<Lecture> _filtered = [];
  bool _loading = true;
  bool _error = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filterLectures);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _filtered = lectures;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _filterLectures() {
    final query = _searchController.text.trim().toLowerCase();
    if (_lectures == null) return;
    setState(() {
      _filtered = _lectures!
          .where((l) =>
              l.title.toLowerCase().contains(query) ||
              l.section.toLowerCase().contains(query))
          .toList();
    });
  }

  void _openLecture(Lecture lecture) {
    AudioPlayerService.instance.playLecture(lecture, queue: _filtered);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'جميع المحاضرات',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightText,
                ),
              ),
              if (_lectures != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.cardGradientStart.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${_filtered.length} محاضرة',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.secondaryText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.mainText, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'بحث في كافة المحاضرات...',
              hintStyle: TextStyle(
                  color: AppColors.secondaryText.withOpacity(0.6),
                  fontSize: 12),
              filled: true,
              fillColor: AppColors.cardDark,
              prefixIcon: Icon(Icons.search,
                  color: AppColors.secondaryText.withOpacity(0.6), size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.cardGradientStart.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColors.cardGradientStart.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryTeal),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return ListView(
        children: List.generate(
          6,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerLectureCard(),
          ),
        ),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.secondaryText.withOpacity(0.6), size: 32),
            const SizedBox(height: 10),
            Text(
              'تعذر الاتصال بالإنترنت',
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

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج تطابق بحثك',
          style: TextStyle(
              color: AppColors.secondaryText.withOpacity(0.7), fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final lecture = _filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LectureRow(
            lecture: lecture,
            onTap: () => _openLecture(lecture),
          ),
        );
      },
    );
  }
}

class _LectureRow extends StatefulWidget {
  final Lecture lecture;
  final VoidCallback onTap;
  const _LectureRow({required this.lecture, required this.onTap});

  @override
  State<_LectureRow> createState() => _LectureRowState();
}

class _LectureRowState extends State<_LectureRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final favoritesService = FavoritesService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([audioService, favoritesService]),
      builder: (context, _) {
        final isThisPlaying = audioService.currentLecture?.audioUrl ==
                widget.lecture.audioUrl &&
            audioService.isPlaying;
        final isFav = favoritesService.isFavorite(widget.lecture);

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isThisPlaying
                      ? AppColors.primaryTeal
                      : AppColors.cardGradientStart.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_pressed ? 0.1 : 0.2),
                    blurRadius: _pressed ? 4 : 8,
                    offset: Offset(0, _pressed ? 1 : 3),
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
                  const SizedBox(width: 10),
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
        );
      },
    );
  }
}
