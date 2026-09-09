import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'services/audio_player_service.dart';
import 'services/downloads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'خطأ:\n${details.exceptionAsString()}',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  };

  String? initError;

  try {
    // تهيئة MediaSession ومشغل الوسائط في شريط الإشعارات
    await JustAudioBackground.init(
      androidNotificationChannelId:
          'com.sheikhapp.temp_scaffold.channel.media.v2',
      androidNotificationChannelName:
          'مشغل محاضرات الشيخ د. محمد الأمين',
      androidNotificationChannelDescription:
          'التحكم في تشغيل محاضرات الشيخ د. محمد الأمين من شريط الإشعارات',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    );

    await FavoritesService.instance.init();
    await DownloadsService.instance.init();
    await AudioPlayerService.instance.init();
  } catch (e, st) {
    initError = '$e\n\n$st';
  }

  runApp(
    SheikhApp(
      initError: initError,
    ),
  );
}

class SheikhApp extends StatelessWidget {
  final String? initError;

  const SheikhApp({
    super.key,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  'خطأ أثناء بدء التطبيق:\n\n$initError',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'الشيخ د. محمد الأمين إسماعيل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
