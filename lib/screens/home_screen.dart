import 'package:flutter/material.dart';

import '/screens/books_screen.dart';
import '/screens/saved_verses_screen.dart';
import '/screens/verse_reading_screen.dart';
import '/services/bible_service.dart';
import '/services/reading_progress_service.dart';
import '../../screens/dictionary_screen.dart';
import 'bible_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  ReadingProgress? _readingProgress;
  DailyBibleVerse? _verseOfTheDay;

  bool _isLoadingReadingProgress = true;
  bool _isLoadingVerseOfTheDay = true;

  String? _verseOfTheDayError;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await Future.wait([_loadReadingProgress(), _loadVerseOfTheDay()]);
  }

  Future<void> _loadReadingProgress() async {
    try {
      final progress = await ReadingProgressService.getProgress();

      if (!mounted) return;

      setState(() {
        _readingProgress = progress;
        _isLoadingReadingProgress = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _readingProgress = null;
        _isLoadingReadingProgress = false;
      });
    }
  }

  Future<void> _loadVerseOfTheDay() async {
    try {
      final verse = await BibleService.getVerseOfTheDay();

      if (!mounted) return;

      setState(() {
        _verseOfTheDay = verse;
        _isLoadingVerseOfTheDay = false;
        _verseOfTheDayError = null;
      });
    } on BibleDataException catch (error) {
      if (!mounted) return;

      setState(() {
        _verseOfTheDay = null;
        _isLoadingVerseOfTheDay = false;
        _verseOfTheDayError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _verseOfTheDay = null;
        _isLoadingVerseOfTheDay = false;
        _verseOfTheDayError = 'Imeshindikana kupakia Neno la Leo.';
      });
    }
  }

  Future<void> _openBible() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BooksScreen()),
    );

    if (!mounted) return;
    await _loadReadingProgress();
  }

  Future<void> _continueReading() async {
    final progress = _readingProgress;

    if (progress == null) {
      await _openBible();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: progress.bookName,
          chapterNumber: progress.chapterNumber,
          chapterCount: progress.chapterCount,
        ),
      ),
    );

    if (!mounted) return;
    await _loadReadingProgress();
  }

  Future<void> _openVerseOfTheDay() async {
    final verse = _verseOfTheDay;

    if (verse == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: verse.bookName,
          chapterNumber: verse.chapterNumber,
          chapterCount: verse.chapterCount,
          initialVerseNumber: verse.verseNumber,
        ),
      ),
    );

    if (!mounted) return;
    await _loadReadingProgress();
  }

  void _showComingSoon(String section) {
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
        child: RefreshIndicator(
          color: gold,
          onRefresh: _loadHomeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                _buildContinueReadingCard(),
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
                      onTap: _openBible,
                    ),
                    FeatureCard(
                      icon: Icons.headphones_rounded,
                      title: 'Sikiliza Biblia',
                      onTap: () => _showComingSoon('Sikiliza Biblia'),
                    ),
                    FeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Mafundisho',
                      onTap: () => _showComingSoon('Mafundisho'),
                    ),
                    FeatureCard(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Video za Biblia',
                      onTap: () => _showComingSoon('Video za Biblia'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDictionaryCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 90,
          height: 58,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryBrown,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Tafuta katika Biblia',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BibleSearchScreen()),
            );
          },
          icon: const Icon(Icons.search_rounded, color: gold, size: 23),
        ),

        IconButton(
          tooltip: 'Mistari Iliyohifadhiwa',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedVersesScreen()),
            );
          },
          icon: const Icon(Icons.bookmark_rounded, color: gold, size: 22),
        ),
      ],
    );
  }

  Widget _buildVerseOfTheDay() {
    if (_isLoadingVerseOfTheDay) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: lightGold,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha: 0.25)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: gold, strokeWidth: 2.5),
        ),
      );
    }

    if (_verseOfTheDayError != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loadVerseOfTheDay,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lightGold,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
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
                const SizedBox(height: 14),
                Text(
                  _verseOfTheDayError!,
                  style: const TextStyle(
                    color: secondaryBrown,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gusa ili kujaribu tena.',
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final verse = _verseOfTheDay;
    if (verse == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openVerseOfTheDay,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: lightGold,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gold.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
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
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: gold, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '“${verse.verseText}”',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryBrown,
                  fontSize: 16,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${verse.reference}',
                  style: const TextStyle(
                    color: secondaryBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard() {
    if (_isLoadingReadingProgress) {
      return Container(
        width: double.infinity,
        height: 112,
        decoration: BoxDecoration(
          color: primaryBrown,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFFD76A),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    final progress = _readingProgress;
    final bool hasProgress = progress != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _continueReading,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProgress ? progress.bookName : 'Anza Kusoma Biblia',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasProgress
                          ? 'Sura ya ${progress.chapterNumber}'
                          : 'Chagua kitabu na sura',
                      style: const TextStyle(
                        color: Color(0xFFEADFD9),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasProgress ? 'Endelea ulipoishia' : 'Fungua Biblia',
                      style: const TextStyle(
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

  Widget _buildDictionaryCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DictionaryScreen()),
          );
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
