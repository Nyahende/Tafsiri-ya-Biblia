import 'package:flutter/material.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color deepBrown = Color(0xFF4E342E);
  static const Color brown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);

  bool _showLogo = false;
  bool _showTitle = false;
  bool _showUnderline = false;

  bool _showSoma = false;
  bool _showFirstArrow = false;
  bool _showTafakari = false;
  bool _showSecondArrow = false;
  bool _showIshi = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    setState(() {
      _showLogo = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _showTitle = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _showUnderline = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() {
      _showSoma = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _showFirstArrow = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _showTafakari = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _showSecondArrow = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    setState(() {
      _showIshi = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    _openHomeScreen();
  }

  void _openHomeScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const HomeScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _showLogo ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: _showLogo ? 1 : 0.88,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      'assets/images/bible_logo.png',
                      width: 270,
                      height: 270,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 270,
                          height: 270,
                          child: Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 130,
                              color: gold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                AnimatedOpacity(
                  opacity: _showTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: _showTitle ? Offset.zero : const Offset(0, 0.25),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOut,
                    child: const Text(
                      'Tafsiri ya Biblia',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: deepBrown,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                AnimatedOpacity(
                  opacity: _showUnderline ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: const DecorativeUnderline(),
                ),

                const SizedBox(height: 32),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSloganItem(
                        visible: _showSoma,
                        child: const Text(
                          'Soma',
                          style: TextStyle(
                            color: brown,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      AnimatedSloganItem(
                        visible: _showFirstArrow,
                        slideFromLeft: true,
                        child: const Text(
                          '➜',
                          style: TextStyle(
                            color: gold,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      AnimatedSloganItem(
                        visible: _showTafakari,
                        child: const Text(
                          'Tafakari',
                          style: TextStyle(
                            color: brown,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      AnimatedSloganItem(
                        visible: _showSecondArrow,
                        slideFromLeft: true,
                        child: const Text(
                          '➜',
                          style: TextStyle(
                            color: gold,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      AnimatedSloganItem(
                        visible: _showIshi,
                        child: const Text(
                          'Ishi',
                          style: TextStyle(
                            color: brown,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedSloganItem extends StatelessWidget {
  const AnimatedSloganItem({
    required this.visible,
    required this.child,
    this.slideFromLeft = false,
    super.key,
  });

  final bool visible;
  final Widget child;
  final bool slideFromLeft;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible
            ? Offset.zero
            : slideFromLeft
            ? const Offset(-0.7, 0)
            : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class DecorativeUnderline extends StatelessWidget {
  const DecorativeUnderline({super.key});

  static const Color gold = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 80, height: 1.5, color: gold),
        const SizedBox(width: 10),
        const Icon(Icons.auto_awesome, size: 18, color: gold),
        const SizedBox(width: 10),
        Container(width: 80, height: 1.5, color: gold),
      ],
    );
  }
}
