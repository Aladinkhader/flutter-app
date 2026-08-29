import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/archive_service.dart';
import '../services/audio_player_service.dart';

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

    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final isThisPlaying =
            audioService.currentLecture?.audioUrl == lecture.audioUrl &&
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
                        style: const TextStyle(
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
