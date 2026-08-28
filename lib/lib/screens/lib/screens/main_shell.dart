import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'home_tab.dart';
import 'placeholder_tab.dart';

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
    'التنزيلات والمفضلة',
    'الإعدادات',
  ];

  final List<Widget> _tabs = const [
    HomeTab(),
    PlaceholderTab(label: 'جميع المحاضرات — قريبًا (المرحلة 2)'),
    PlaceholderTab(label: 'الأقسام العلمية — قريبًا (المرحلة 2)'),
    PlaceholderTab(label: 'التنزيلات والمفضلة — قريبًا (المرحلة 5-6)'),
    PlaceholderTab(label: 'الإعدادات — قريبًا'),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: _TopHeader(pageTitle: _titles[_currentIndex]),
        ),
        body: SafeArea(
          top: false,
          child: _tabs[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
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
              icon: Icon(Icons.download_rounded),
              label: 'التنزيلات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
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
        color: AppColors.background.withOpacity(
