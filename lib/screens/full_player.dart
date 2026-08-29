import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../services/audio_player_service.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // نحدث الشاشة كل نص ثانية عشان نعرض الوقت والـ Slider بدقة
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;
    final lecture = audioService.currentLecture;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_forward_ios,
                          color: AppColors.secondaryText, size: 18),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardDark,
                    border: Border.all(
                      color: AppColors.primaryTeal.withOpacity(0.4),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: AppColors.cardDark,
                      child: Icon(Icons.person,
                          size: 90,
                          color: AppColors.primaryTeal.withOpacity(0.6)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  lecture?.title ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lecture?.section ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const Spacer(),
                Slider(
                  value: audioService.duration.inMilliseconds > 0
                      ? audioService.position.inMilliseconds
                          .clamp(0, audioService.duration.inMilliseconds)
                          .toDouble()
                      : 0,
                  min: 0,
                  max: audioService.duration.inMilliseconds > 0
                      ? audioService.duration.inMilliseconds.toDouble()
                      : 1,
                  activeColor: AppColors.primaryTeal,
                  inactiveColor: AppColors.cardDark,
                  onChanged: (value) {
                    audioService.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioService.position),
                        style: TextStyle(
                            color: AppColors.secondaryText, fontSize: 11),
                      ),
                      Text(
                        _formatDuration(audioService.duration),
                        style: TextStyle(
                            color: AppColors.secondaryText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => audioService.skipBackward(),
                      icon: Icon(Icons.replay_10_rounded,
                          color: AppColors.secondaryText, size: 30),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => audioService.togglePlayPause(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mainText,
                        ),
                        child: Icon(
                          audioService.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.background,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () => audioService.skipForward(),
                      icon: Icon(Icons.forward_10_rounded,
                          color: AppColors.secondaryText, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
