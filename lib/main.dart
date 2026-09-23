import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/verse_reading_screen.dart';
import 'services/daily_verse_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DailyVerseNotificationService.initialize();

  DailyVerseNotificationService.onNotificationTap =
      (DailyVerseNotificationTarget target) {
        final NavigatorState? navigator = navigatorKey.currentState;

        if (navigator == null) {
          return;
        }

        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => VerseReadingScreen(
              bookName: target.bookName,
              chapterNumber: target.chapterNumber,
              chapterCount: target.chapterCount,
              initialVerseNumber: target.verseNumber,
            ),
          ),
        );
      };

  await DailyVerseNotificationService.scheduleDailyVerseNotifications(
    hour: 5,
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
      navigatorKey: navigatorKey,
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
