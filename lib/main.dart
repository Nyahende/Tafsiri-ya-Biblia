import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/daily_verse_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DailyVerseNotificationService.initialize();

  await DailyVerseNotificationService.scheduleDailyVerseNotifications(
    hour: 7,
    minute: 0,
    daysToSchedule: 30,
  );

  runApp(const TafsiriYaBibliaApp());
}

class TafsiriYaBibliaApp extends StatelessWidget {
  const TafsiriYaBibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jifunze Biblia',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAF9F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A017),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
