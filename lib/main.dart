import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const TafsiriYaBibliaApp());
}

class TafsiriYaBibliaApp extends StatelessWidget {
  const TafsiriYaBibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tafsiri ya Biblia',
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
