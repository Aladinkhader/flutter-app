import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/favorites_service.dart';
import 'services/audio_player_service.dart';

late AudioPlayerHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FavoritesService.instance.init();

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.sheikhapp.audio',
      androidNotificationChannelName: 'تشغيل المحاضرات',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

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

  runApp(const SheikhApp());
}

class SheikhApp extends StatelessWidget {
  const SheikhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الشيخ د. محمد الأمين إسماعيل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
