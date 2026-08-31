import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/favorites_service.dart';
import '../services/downloads_service.dart';
import '../services/audio_player_service.dart';
import 'full_player.dart';

class DownloadsFavoritesTab extends StatefulWidget {
  const DownloadsFavoritesTab({super.key});

  @override
  State<DownloadsFavoritesTab> createState() => _DownloadsFavoritesTabState();
}

class _DownloadsFavoritesTabState extends State<DownloadsFavoritesTab> {
  int _subTab = 0; // 0 = تنزيلات، 1 = مفضلة

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _SubTabButton(
                  label: 'التنزيلات',
                  icon: Icons.download_rounded,
                  selected: _subTab == 0,
                  onTap: () => setState(() => _subTab = 0),
                ),
              ),
              Expanded(
                child: _SubTabButton(
                  label: 'المفضلة',
                  icon: Icons.bookmark_rounded,
                  selected: _subTab == 1,
                  onTap: () => setState(() => _subTab = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _subTab == 0
                ? const _DownloadsList(key: ValueKey('downloads'))
                : const _FavoritesList(key: ValueKey('favorites')),
          ),
        ),
      ],
    );
  }
}

class _SubTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? AppColors.primaryTeal
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? AppColors.mainText
                    : AppColors.secondaryText.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected
                    ? AppColors.mainText
                    : AppColors.secondaryText.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadsList extends StatelessWidget {
  const _DownloadsList({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadsService = DownloadsService.instance;

    return AnimatedBuilder(
      animation: downloadsService,
      builder: (context, _) {
        final downloads = downloadsService.downloads;

        if (downloads.isEmpty) {
          return _EmptyState(
            icon: Icons.download_rounded,
            title: 'لا توجد محاضرات محملة',
            subtitle: 'قم بتنزيل المحاضرات من خلال الضغط على علامة التحميل',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: downloads.length,
          itemBuilder: (context, index) {
            final item = downloads[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DownloadRow(lecture: item.lecture),
            );
          },
        );
      },
    );
  }
}

class _DownloadRow extends StatelessWidget {
  final Lecture lecture;
  const _DownloadRow({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;

    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final isThisPlaying =
            audioService.currentLecture?.audioUrl == lecture.audioUrl &&
                audioService.isPlaying;

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
                onTap: () {
                  AudioPlayerService.instance
                      .playLecture(lecture, queue: [lecture]);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                  );
                },
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primaryTeal.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'أوفلاين',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    DownloadsService.instance.deleteDownload(lecture),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService.instance;

    return AnimatedBuilder(
      animation: favoritesService,
      builder: (context, _) {
        final favorites = favoritesService.favorites;

        if (favorites.isEmpty) {
          return _EmptyState(
            icon: Icons.bookmark_border,
            title: 'لا توجد مفضلة',
            subtitle: 'أضف المحاضرات إلى المفضلة للرجوع إليها لاحقاً',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final lecture = favorites[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FavoriteRow(lecture: lecture),
            );
          },
        );
      },
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final Lecture lecture;
  const _FavoriteRow({required this.lecture});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;

    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final isThisPlaying =
            audioService.currentLecture?.audioUrl == lecture.audioUrl &&
                audioService.isPlaying;

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
                onTap: () {
                  AudioPlayerService.instance
                      .playLecture(lecture, queue: [lecture]);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                  );
                },
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
              IconButton(
                onPressed: () =>
                    FavoritesService.instance.removeFavorite(lecture),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardDark,
            ),
            child: Icon(icon, color: AppColors.primaryTeal, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: AppColors.mainText,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.secondaryText.withOpacity(0.7),
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
