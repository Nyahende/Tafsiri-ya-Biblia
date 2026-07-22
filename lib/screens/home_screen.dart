import 'package:flutter/material.dart';
import '/screens/books_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  void _showComingSoon(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$section inakuja hivi karibuni.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),

              const SizedBox(height: 24),

              _buildVerseOfTheDay(),

              const SizedBox(height: 26),

              const Text(
                'Endelea Kusoma',
                style: TextStyle(
                  color: primaryBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _buildContinueReadingCard(context),

              const SizedBox(height: 28),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  FeatureCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Soma Biblia',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BooksScreen()),
                      );
                    },
                  ),
                  FeatureCard(
                    icon: Icons.headphones_rounded,
                    title: 'Sikiliza Biblia',
                    onTap: () {
                      _showComingSoon(context, 'Sikiliza Biblia');
                    },
                  ),
                  FeatureCard(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Mafundisho',
                    onTap: () {
                      _showComingSoon(context, 'Mafundisho');
                    },
                  ),
                  FeatureCard(
                    icon: Icons.ondemand_video_rounded,
                    title: 'Video za Biblia',
                    onTap: () {
                      _showComingSoon(context, 'Video za Biblia');
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _buildDictionaryCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/bible_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Text(
            'Tafsiri ya Biblia',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Mipangilio',
          onPressed: () {
            _showComingSoon(context, 'Mipangilio');
          },
          icon: const Icon(
            Icons.settings_outlined,
            color: primaryBrown,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildVerseOfTheDay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: gold, size: 22),
              SizedBox(width: 8),
              Text(
                'Neno la Leo',
                style: TextStyle(
                  color: primaryBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            '“Kwa kuwa hekima ni bora kuliko marijani; wala vitu vyote vinavyoweza kutamaniwa havilingani nayo.”',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryBrown,
              fontSize: 16,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),

          SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Mithali 8:11',
              style: TextStyle(
                color: secondaryBrown,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showComingSoon(context, 'Mithali, Sura ya 1');
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryBrown,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFFFFD76A),
                  size: 31,
                ),
              ),

              const SizedBox(width: 16),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mithali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sura ya 1',
                      style: TextStyle(color: Color(0xFFEADFD9), fontSize: 15),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Endelea ulipoishia',
                      style: TextStyle(
                        color: Color(0xFFFFD76A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDictionaryCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showComingSoon(context, 'Kamusi ya Biblia');
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: lightGold,
                child: Icon(Icons.library_books_rounded, color: gold, size: 28),
              ),

              SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamusi ya Biblia',
                      style: TextStyle(
                        color: primaryBrown,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tafuta watu, maeneo, vitu na maana za maneno.',
                      style: TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios_rounded, color: gold, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 51,
                  height: 51,
                  decoration: BoxDecoration(
                    color: lightGold,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: gold, size: 28),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: primaryBrown,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
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
