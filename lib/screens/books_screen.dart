import 'package:flutter/material.dart';
import 'chapters_screen.dart';
import 'verse_reading_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  bool _showOldTestament = true;

  final List<BibleBook> _oldTestamentBooks = const [
    BibleBook(name: 'Mwanzo', chapters: 50),
    BibleBook(name: 'Kutoka', chapters: 40),
    BibleBook(name: 'Mambo ya Walawi', chapters: 27),
    BibleBook(name: 'Hesabu', chapters: 36),
    BibleBook(name: 'Kumbukumbu la Torati', chapters: 34),
    BibleBook(name: 'Yoshua', chapters: 24),
    BibleBook(name: 'Waamuzi', chapters: 21),
    BibleBook(name: 'Ruthu', chapters: 4),
    BibleBook(name: '1 Samweli', chapters: 31),
    BibleBook(name: '2 Samweli', chapters: 24),
    BibleBook(name: '1 Wafalme', chapters: 22),
    BibleBook(name: '2 Wafalme', chapters: 25),
    BibleBook(name: '1 Mambo ya Nyakati', chapters: 29),
    BibleBook(name: '2 Mambo ya Nyakati', chapters: 36),
    BibleBook(name: 'Ezra', chapters: 10),
    BibleBook(name: 'Nehemia', chapters: 13),
    BibleBook(name: 'Esta', chapters: 10),
    BibleBook(name: 'Ayubu', chapters: 42),
    BibleBook(name: 'Zaburi', chapters: 150),
    BibleBook(name: 'Mithali', chapters: 31),
    BibleBook(name: 'Mhubiri', chapters: 12),
    BibleBook(name: 'Wimbo Ulio Bora', chapters: 8),
    BibleBook(name: 'Isaya', chapters: 66),
    BibleBook(name: 'Yeremia', chapters: 52),
    BibleBook(name: 'Maombolezo', chapters: 5),
    BibleBook(name: 'Ezekieli', chapters: 48),
    BibleBook(name: 'Danieli', chapters: 12),
    BibleBook(name: 'Hosea', chapters: 14),
    BibleBook(name: 'Yoeli', chapters: 3),
    BibleBook(name: 'Amosi', chapters: 9),
    BibleBook(name: 'Obadia', chapters: 1),
    BibleBook(name: 'Yona', chapters: 4),
    BibleBook(name: 'Mika', chapters: 7),
    BibleBook(name: 'Nahumu', chapters: 3),
    BibleBook(name: 'Habakuki', chapters: 3),
    BibleBook(name: 'Sefania', chapters: 3),
    BibleBook(name: 'Hagai', chapters: 2),
    BibleBook(name: 'Zekaria', chapters: 14),
    BibleBook(name: 'Malaki', chapters: 4),
  ];

  final List<BibleBook> _newTestamentBooks = const [
    BibleBook(name: 'Mathayo', chapters: 28),
    BibleBook(name: 'Marko', chapters: 16),
    BibleBook(name: 'Luka', chapters: 24),
    BibleBook(name: 'Yohana', chapters: 21),
    BibleBook(name: 'Matendo ya Mitume', chapters: 28),
    BibleBook(name: 'Warumi', chapters: 16),
    BibleBook(name: '1 Wakorintho', chapters: 16),
    BibleBook(name: '2 Wakorintho', chapters: 13),
    BibleBook(name: 'Wagalatia', chapters: 6),
    BibleBook(name: 'Waefeso', chapters: 6),
    BibleBook(name: 'Wafilipi', chapters: 4),
    BibleBook(name: 'Wakolosai', chapters: 4),
    BibleBook(name: '1 Wathesalonike', chapters: 5),
    BibleBook(name: '2 Wathesalonike', chapters: 3),
    BibleBook(name: '1 Timotheo', chapters: 6),
    BibleBook(name: '2 Timotheo', chapters: 4),
    BibleBook(name: 'Tito', chapters: 3),
    BibleBook(name: 'Filemoni', chapters: 1),
    BibleBook(name: 'Waebrania', chapters: 13),
    BibleBook(name: 'Yakobo', chapters: 5),
    BibleBook(name: '1 Petro', chapters: 5),
    BibleBook(name: '2 Petro', chapters: 3),
    BibleBook(name: '1 Yohana', chapters: 5),
    BibleBook(name: '2 Yohana', chapters: 1),
    BibleBook(name: '3 Yohana', chapters: 1),
    BibleBook(name: 'Yuda', chapters: 1),
    BibleBook(name: 'Ufunuo wa Yohana', chapters: 22),
  ];

  List<BibleBook> get _allBooks {
    return [..._oldTestamentBooks, ..._newTestamentBooks];
  }

  List<BibleBook> get _filteredBooks {
    final List<BibleBook> selectedBooks = _showOldTestament
        ? _oldTestamentBooks
        : _newTestamentBooks;

    final String query = _searchText.trim();

    if (query.isEmpty) {
      return selectedBooks;
    }

    final ParsedBibleReference? reference = _parseBibleReference(query);
    final String bookSearchText = reference?.bookName.trim() ?? query;

    return _allBooks.where((BibleBook book) {
      return book.name.toLowerCase().contains(bookSearchText.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBook(BibleBook book) {
    final String query = _searchText.trim();
    final ParsedBibleReference? reference = _parseBibleReference(query);

    final bool hasExactBookReference =
        reference != null &&
        reference.bookName.toLowerCase() == book.name.toLowerCase();

    if (!hasExactBookReference || reference.chapterNumber == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ChaptersScreen(bookName: book.name, chapterCount: book.chapters),
        ),
      );
      return;
    }

    final int chapterNumber = reference.chapterNumber!;

    if (chapterNumber < 1 || chapterNumber > book.chapters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.name} haina sura ya $chapterNumber.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: book.name,
          chapterNumber: chapterNumber,
          chapterCount: book.chapters,
          initialVerseNumber: reference.verseNumber ?? 1,
        ),
      ),
    );
  }

  ParsedBibleReference? _parseBibleReference(String input) {
    final String cleanedInput = input.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (cleanedInput.isEmpty) {
      return null;
    }

    final RegExp referencePattern = RegExp(
      r'^(.+?)(?:\s+(\d+)(?:\s*:\s*(\d+))?)?$',
      caseSensitive: false,
    );

    final RegExpMatch? match = referencePattern.firstMatch(cleanedInput);

    if (match == null) {
      return null;
    }

    final String bookName = match.group(1)?.trim() ?? '';

    if (bookName.isEmpty) {
      return null;
    }

    return ParsedBibleReference(
      bookName: bookName,
      chapterNumber: int.tryParse(match.group(2) ?? ''),
      verseNumber: int.tryParse(match.group(3) ?? ''),
    );
  }

  void _submitSearch(String value) {
    final ParsedBibleReference? reference = _parseBibleReference(value);

    if (reference == null) {
      return;
    }

    for (final BibleBook book in _allBooks) {
      if (book.name.toLowerCase() == reference.bookName.toLowerCase()) {
        _openBook(book);
        return;
      }
    }
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
        title: const Text(
          'Soma Biblia',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildTestamentSelector(),

            const SizedBox(height: 14),

            Expanded(
              child: _filteredBooks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                      itemCount: _filteredBooks.length,
                      separatorBuilder: (_, __) {
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        return _buildBookCard(_filteredBooks[index], index);
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chagua kitabu cha Biblia',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Chagua kitabu, kisha utaona sura zake.',
            style: TextStyle(color: secondaryBrown, fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _submitSearch,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Mfano: Mithali 31:2',
              hintStyle: const TextStyle(color: secondaryBrown),
              prefixIcon: const Icon(Icons.search_rounded, color: gold),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: secondaryBrown,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: gold.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: gold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: lightGold,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTestamentButton(
                title: 'Agano la Kale',
                isSelected: _showOldTestament,
                onTap: () {
                  setState(() {
                    _showOldTestament = true;
                  });
                },
              ),
            ),
            Expanded(
              child: _buildTestamentButton(
                title: 'Agano Jipya',
                isSelected: !_showOldTestament,
                onTap: () {
                  setState(() {
                    _showOldTestament = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestamentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? primaryBrown : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryBrown,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(BibleBook book, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openBook(book);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      book.chapters == 1 ? 'Sura 1' : 'Sura ${book.chapters}',
                      style: const TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: gold,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, color: gold, size: 58),
            SizedBox(height: 14),
            Text(
              'Kitabu hakijapatikana.',
              style: TextStyle(
                color: primaryBrown,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Jaribu kuandika jina lingine.',
              style: TextStyle(color: secondaryBrown, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class BibleBook {
  const BibleBook({required this.name, required this.chapters});

  final String name;
  final int chapters;
}

class ParsedBibleReference {
  const ParsedBibleReference({
    required this.bookName,
    this.chapterNumber,
    this.verseNumber,
  });

  final String bookName;
  final int? chapterNumber;
  final int? verseNumber;
}
