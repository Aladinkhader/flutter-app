import 'package:flutter/material.dart';
import 'package:sheikh_app/services/audio_player_service.dart';
import 'home_tab.dart';
import 'all_lectures_tab.dart';
import 'downloads_favorites_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<Widget> _tabs = const [
    HomeTab(),
    AllLecturesTab(),
    DownloadsFavoritesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final audioService = AudioPlayerService.instance;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'المحاضرات'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'المفضلة'),
        ],
      ),
      bottomSheet: AnimatedBuilder(
        animation: audioService,
        builder: (context, child) {
          if (!audioService.isPlaying && audioService.currentLecture == null) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        audioService.currentLecture?.title ?? '',
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        audioService.currentLecture?.section ?? '',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: audioService.togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.white),
                  onPressed: audioService.stop,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: audioService.next,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
