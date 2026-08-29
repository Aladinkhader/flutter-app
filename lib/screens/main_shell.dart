import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/audio_player_service.dart';
import 'home_tab.dart';
import 'placeholder_tab.dart';
import 'all_lectures_tab.dart';
import 'categories_tab.dart';
import 'favorites_tab.dart';
import 'full_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'الرئيسية',
    'جميع المحاضرات',
    'الأقسام',
    'المفضلة',
    'الإعدادات',
  ];

  final List<Widget> _tabs = const [
    HomeTab(),
    AllLecturesTab(),
    CategoriesTab(),
    FavoritesTab(),
    PlaceholderTab(label: 'الإعدادات — قريبًا'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: _TopHeader(pageTitle: _titles[_currentIndex]),
        ),
        body: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_currentIndex),
              child: _tabs[_currentIndex],
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MiniPlayer(),
            BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_rounded),
                  label: 'المحاضرات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_rounded),
                  label: 'الأقسام',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_rounded),
                  label: 'المفضلة',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: 'الإعدادات',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;

    return AnimatedBuilder(
      animation: audioService,
      builder: (context, _) {
        final lecture = audioService.currentLecture;
        if (lecture == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryTeal.withOpacity(0.4),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(
                      color: AppColors.primaryTeal.withOpacity(0.5),
                    ),
                  ),
                  child: Icon(Icons.person,
                      size: 18,
                      color: AppColors.primaryTeal.withOpacity(0.7)),
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
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainText,
                        ),
                      ),
                      Text(
                        lecture.section,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppColors.secondaryText.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => audioService.togglePlayPause(),
                  icon: Icon(
                    audioService.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppColors.primaryTeal,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String pageTitle;
  const _TopHeader({required this.pageTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardGradientStart.withOpacity(0.4),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                  border: Border.all(
                    color: AppColors.primaryTeal.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 22,
                  color: AppColors.primaryTeal.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الشيخ د. محمد الأمين إسماعيل',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainText,
                    ),
                  ),
                  Text(
                    pageTitle,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                  border: Border.all(
                    color: AppColors.cardGradientStart.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
