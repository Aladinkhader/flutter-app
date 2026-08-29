import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/lecture.dart';
import '../services/favorites_service.dart';
import '../services/audio_player_service.dart';

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesService = FavoritesService.instance;

    return AnimatedBuilder(
      animation: favoritesService,
      builder: (context, _) {
        final favorites = favoritesService.favorites;

        if (favorites.isEmpty) {
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
                  child: Icon(Icons.bookmark_border,
                      color: AppColors.primaryTeal, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'لا توجد مفضلة',
                  style: TextStyle(
                    color: AppColors.mainText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أضف المحاضرات إلى المفضلة للرجوع إليها لاحقاً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.secondaryText.withOpacity(0.7),
                      fontSize: 11),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
