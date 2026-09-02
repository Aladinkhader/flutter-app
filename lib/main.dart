import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'services/audio_player_service.dart';
import 'services/downloads_service.dart';

// تم إزالة السطر: late AudioPlayerHandler audioHandler;
// لأن AudioPlayerHandler معرف داخل audio_player_service.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة AudioService مباشرة باستخدام AudioPlayerHandler من audio_player_service.dart
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sheikhapp.audio',
      androidNotificationChannelName: 'تشغيل المحاضرات',
      androidNotificationChannelDescription: 'التحكم في تشغيل المحاضرات الصوتية',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: false,
      androidNotificationClickStartsActivity: true,
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      androidResumeOnClick: true,
    ),
  );

  // تمرير المعالج إلى AudioPlayerService
  await AudioPlayerService.instance.init(audioHandler);

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'خطأ:\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  };

  String? initError;
  try {
    await FavoritesService.instance.init();
    await DownloadsService.instance.init();
  } catch (e, st) {
    initError = '$e\n\n$st';
  }

  runApp(SheikhApp(initError: initError));
}

class SheikhApp extends StatelessWidget {
  final String? initError;
  const SheikhApp({super.key, this.initError});

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
                  style: const TextStyle(color: Colors.red, fontSize: 12),
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
