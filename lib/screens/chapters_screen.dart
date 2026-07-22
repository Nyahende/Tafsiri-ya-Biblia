import 'package:flutter/material.dart';
import 'verse_reading_screen.dart';

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({
    super.key,
    required this.bookName,
    required this.chapterCount,
  });

  final String bookName;
  final int chapterCount;

  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  void _openChapter(BuildContext context, int chapterNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: bookName,
          chapterNumber: chapterNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        title: Text(
          bookName,
          style: const TextStyle(
            color: primaryBrown,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                itemCount: chapterCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final chapterNumber = index + 1;

                  return _buildChapterCard(context, chapterNumber);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightGold,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: gold, size: 28),
                SizedBox(width: 10),
                Text(
                  'Chagua Sura',
                  style: TextStyle(
                    color: primaryBrown,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              'Kitabu cha $bookName kina ${_chapterLabel(chapterCount)}.',
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Gusa namba ya sura unayotaka kusoma.',
              style: TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, int chapterNumber) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openChapter(context, chapterNumber);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$chapterNumber',
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _chapterLabel(int chapterCount) {
    if (chapterCount == 1) {
      return 'sura 1';
    }

    return 'sura $chapterCount';
  }
}
