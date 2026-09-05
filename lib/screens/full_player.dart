import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
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
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/sheikh.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  lecture?.title ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lecture?.section ?? '',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const Spacer(),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioService.position),
                        style: GoogleFonts.tajawal(
                            color: AppColors.secondaryText, fontSize: 11),
                      ),
                      Text(
                        _formatDuration(audioService.duration),
                        style: GoogleFonts.tajawal(
                            color: AppColors.secondaryText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          audioService.hasPrevious ? audioService.playPrevious : null,
                      icon: Icon(Icons.skip_previous_rounded,
                          color: audioService.hasPrevious
                              ? AppColors.secondaryText
                              : AppColors.secondaryText.withOpacity(0.3),
                          size: 26),
                    ),
                    IconButton(
                      onPressed: () => audioService.skipBackward(),
                      icon: Icon(Icons.replay_10_rounded,
                          color: AppColors.secondaryText, size: 28),
                    ),
                    const SizedBox(width: 12),
                    _PlayPauseButton(audioService: audioService),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => audioService.skipForward(),
                      icon: Icon(Icons.forward_10_rounded,
                          color: AppColors.secondaryText, size: 28),
                    ),
                    IconButton(
                      onPressed:
                          audioService.hasNext ? audioService.playNext : null,
                      icon: Icon(Icons.skip_next_rounded,
                          color: audioService.hasNext
                              ? AppColors.secondaryText
                              : AppColors.secondaryText.withOpacity(0.3),
                          size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => audioService.toggleRepeat(),
                  icon: Icon(
                    Icons.repeat_rounded,
                    color: audioService.isRepeat
                        ? AppColors.primaryTeal
                        : AppColors.secondaryText.withOpacity(0.5),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final AudioPlayerService audioService;
  const _PlayPauseButton({required this.audioService});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => widget.audioService.togglePlayPause(),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mainText,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.audioService.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: AppColors.background,
            size: 34,
          ),
        ),
      ),
    );
  }
}
