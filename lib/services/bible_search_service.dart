import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bible_search_result.dart';

class BibleSearchService {
  BibleSearchService._();

  static const String _bibleAssetPath = 'assets/data/bible.json';

  static Map<String, dynamic>? _cachedBibleData;

  /// Loads and caches the Bible JSON data.
  static Future<Map<String, dynamic>> _loadBibleData() async {
    if (_cachedBibleData != null) {
      return _cachedBibleData!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_bibleAssetPath);

      final dynamic decodedData = jsonDecode(jsonString);

      if (decodedData is! Map) {
        throw const FormatException('Bible JSON must contain an object.');
      }

      final Map<String, dynamic> bibleData = Map<String, dynamic>.from(
        decodedData,
      );

      if (bibleData['books'] is! List) {
        throw const FormatException('Bible JSON must contain a books list.');
      }

      _cachedBibleData = bibleData;

      return bibleData;
    } catch (error) {
      throw Exception('Imeshindikana kupakia Biblia: $error');
    }
  }

  /// Searches the Bible.
  ///
  /// It first checks whether the query is a Bible reference.
  ///
  /// Supported examples:
  ///
  /// Mithali
  /// Mithali 31
  /// Mithali 31:2
  /// Mithali31:2
  /// 1 Wakorintho 13
  /// Wimbo Ulio Bora 2:7
  ///
  /// If the query is not a Bible reference, it searches inside
  /// the text of every available verse.
  static Future<List<BibleSearchResult>> search(String query) async {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      return [];
    }

    final Map<String, dynamic> bibleData = await _loadBibleData();

    final List<dynamic> books = bibleData['books'] as List<dynamic>;

    final List<BibleSearchResult>? referenceResults = _searchBibleReference(
      query: cleanedQuery,
      books: books,
    );

    if (referenceResults != null) {
      return referenceResults;
    }

    return _searchVerseText(query: cleanedQuery, books: books);
  }

  /// Attempts to interpret the supplied query as a Bible reference.
  ///
  /// Returns:
  ///
  /// - a list containing the matching verse when the query is
  ///   a valid Bible reference
  /// - an empty list when the book is found but the requested
  ///   chapter or verse does not exist
  /// - null when the query is not a Bible reference
  static List<BibleSearchResult>? _searchBibleReference({
    required String query,
    required List<dynamic> books,
  }) {
    final String compactQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (compactQuery.isEmpty) {
      return null;
    }

    /*
     * Matches:
     *
     * Mithali 31
     * Mithali 31:2
     * Mithali31
     * Mithali31:2
     * 1 Wakorintho 13:4
     * Wimbo Ulio Bora 2:7
     *
     * Group 1 = book name
     * Group 2 = chapter
     * Group 3 = optional verse
     */
    final RegExp referencePattern = RegExp(
      r'^(.+?)(\d+)(?:\s*:\s*(\d+))?$',
      caseSensitive: false,
    );

    final RegExpMatch? referenceMatch = referencePattern.firstMatch(
      compactQuery,
    );

    if (referenceMatch != null) {
      final String requestedBookName = referenceMatch.group(1)?.trim() ?? '';

      final int? requestedChapter = int.tryParse(referenceMatch.group(2) ?? '');

      final int? requestedVerse = int.tryParse(referenceMatch.group(3) ?? '');

      if (requestedBookName.isEmpty ||
          requestedChapter == null ||
          requestedChapter < 1) {
        return null;
      }

      final _BibleBookData? bookData = _findBookData(
        books: books,
        requestedBookName: requestedBookName,
      );

      if (bookData == null) {
        /*
         * It resembles a reference, but the beginning may be
         * ordinary search text ending with a number.
         *
         * Return null so normal verse-text search can continue.
         */
        return null;
      }

      return _buildReferenceResult(
        bookData: bookData,
        chapterNumber: requestedChapter,
        verseNumber: requestedVerse,
      );
    }

    /*
     * If no chapter or verse was supplied, check whether the
     * entire query is exactly a Bible book name.
     *
     * Example:
     *
     * Mithali
     */
    final _BibleBookData? bookOnlyData = _findBookData(
      books: books,
      requestedBookName: compactQuery,
    );

    if (bookOnlyData == null) {
      return null;
    }

    return _buildReferenceResult(
      bookData: bookOnlyData,
      chapterNumber: 1,
      verseNumber: null,
    );
  }

  /// Builds one search result for a Bible reference.
  ///
  /// When no verse number is supplied, the first valid verse
  /// of the selected chapter is returned.
  static List<BibleSearchResult> _buildReferenceResult({
    required _BibleBookData bookData,
    required int chapterNumber,
    required int? verseNumber,
  }) {
    final dynamic rawChapter = bookData.chapters[chapterNumber.toString()];

    if (rawChapter is! List || rawChapter.isEmpty) {
      return [];
    }

    Map<String, dynamic>? selectedVerse;

    if (verseNumber != null) {
      for (final dynamic rawVerse in rawChapter) {
        if (rawVerse is! Map) {
          continue;
        }

        final Map<String, dynamic> verse = Map<String, dynamic>.from(rawVerse);

        final int currentVerseNumber = _parseInt(verse['number']);

        if (currentVerseNumber == verseNumber) {
          selectedVerse = verse;
          break;
        }
      }

      if (selectedVerse == null) {
        return [];
      }
    } else {
      for (final dynamic rawVerse in rawChapter) {
        if (rawVerse is! Map) {
          continue;
        }

        final Map<String, dynamic> verse = Map<String, dynamic>.from(rawVerse);

        final int currentVerseNumber = _parseInt(verse['number']);

        final String currentVerseText = verse['text']?.toString().trim() ?? '';

        if (currentVerseNumber > 0 && currentVerseText.isNotEmpty) {
          selectedVerse = verse;
          break;
        }
      }

      if (selectedVerse == null) {
        return [];
      }
    }

    final int selectedVerseNumber = _parseInt(selectedVerse['number']);

    final String selectedVerseText =
        selectedVerse['text']?.toString().trim() ?? '';

    if (selectedVerseNumber < 1 || selectedVerseText.isEmpty) {
      return [];
    }

    return [
      BibleSearchResult(
        bookName: bookData.bookName,
        bookIndex: bookData.bookIndex,
        chapterNumber: chapterNumber,
        chapterCount: bookData.chapters.length,
        verseNumber: selectedVerseNumber,
        verseText: selectedVerseText,
      ),
    ];
  }

  /// Searches inside the text of every Bible verse.
  static List<BibleSearchResult> _searchVerseText({
    required String query,
    required List<dynamic> books,
  }) {
    final String normalizedQuery = normalizeText(query);

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final List<BibleSearchResult> results = [];

    for (int bookIndex = 0; bookIndex < books.length; bookIndex++) {
      final dynamic rawBook = books[bookIndex];

      if (rawBook is! Map) {
        continue;
      }

      final Map<String, dynamic> book = Map<String, dynamic>.from(rawBook);

      final String bookName = book['name']?.toString().trim() ?? '';

      final dynamic rawChapters = book['chapters'];

      if (rawChapters is! Map) {
        continue;
      }

      final Map<String, dynamic> chapters = Map<String, dynamic>.from(
        rawChapters,
      );

      final int chapterCount = chapters.length;

      final List<String> chapterKeys = chapters.keys.toList()
        ..sort((String first, String second) {
          final int firstNumber = int.tryParse(first) ?? 0;

          final int secondNumber = int.tryParse(second) ?? 0;

          return firstNumber.compareTo(secondNumber);
        });

      for (final String chapterKey in chapterKeys) {
        final int chapterNumber = int.tryParse(chapterKey) ?? 0;

        if (chapterNumber <= 0) {
          continue;
        }

        final dynamic rawVerses = chapters[chapterKey];

        if (rawVerses is! List) {
          continue;
        }

        for (final dynamic rawVerse in rawVerses) {
          if (rawVerse is! Map) {
            continue;
          }

          final Map<String, dynamic> verse = Map<String, dynamic>.from(
            rawVerse,
          );

          final int verseNumber = _parseInt(verse['number']);

          final String verseText = verse['text']?.toString().trim() ?? '';

          if (verseNumber <= 0 || verseText.isEmpty) {
            continue;
          }

          final String normalizedVerse = normalizeText(verseText);

          if (normalizedVerse.contains(normalizedQuery)) {
            results.add(
              BibleSearchResult(
                bookName: bookName,
                bookIndex: bookIndex,
                chapterNumber: chapterNumber,
                chapterCount: chapterCount,
                verseNumber: verseNumber,
                verseText: verseText,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  /// Searches for verses containing every individual word
  /// in the supplied query.
  static Future<List<BibleSearchResult>> searchAllWords(String query) async {
    final List<String> queryWords = normalizeText(
      query,
    ).split(' ').where((String word) => word.trim().isNotEmpty).toList();

    if (queryWords.isEmpty) {
      return [];
    }

    final Map<String, dynamic> bibleData = await _loadBibleData();

    final List<dynamic> books = bibleData['books'] as List<dynamic>;

    final List<BibleSearchResult> results = [];

    for (int bookIndex = 0; bookIndex < books.length; bookIndex++) {
      final dynamic rawBook = books[bookIndex];

      if (rawBook is! Map) {
        continue;
      }

      final Map<String, dynamic> book = Map<String, dynamic>.from(rawBook);

      final String bookName = book['name']?.toString().trim() ?? '';

      final dynamic rawChapters = book['chapters'];

      if (rawChapters is! Map) {
        continue;
      }

      final Map<String, dynamic> chapters = Map<String, dynamic>.from(
        rawChapters,
      );

      final int chapterCount = chapters.length;

      final List<String> chapterKeys = chapters.keys.toList()
        ..sort((String first, String second) {
          final int firstNumber = int.tryParse(first) ?? 0;

          final int secondNumber = int.tryParse(second) ?? 0;

          return firstNumber.compareTo(secondNumber);
        });

      for (final String chapterKey in chapterKeys) {
        final int chapterNumber = int.tryParse(chapterKey) ?? 0;

        if (chapterNumber <= 0) {
          continue;
        }

        final dynamic rawVerses = chapters[chapterKey];

        if (rawVerses is! List) {
          continue;
        }

        for (final dynamic rawVerse in rawVerses) {
          if (rawVerse is! Map) {
            continue;
          }

          final Map<String, dynamic> verse = Map<String, dynamic>.from(
            rawVerse,
          );

          final int verseNumber = _parseInt(verse['number']);

          final String verseText = verse['text']?.toString().trim() ?? '';

          if (verseNumber <= 0 || verseText.isEmpty) {
            continue;
          }

          final String normalizedVerse = normalizeText(verseText);

          final bool containsAllWords = queryWords.every((String word) {
            return normalizedVerse.contains(word);
          });

          if (containsAllWords) {
            results.add(
              BibleSearchResult(
                bookName: bookName,
                bookIndex: bookIndex,
                chapterNumber: chapterNumber,
                chapterCount: chapterCount,
                verseNumber: verseNumber,
                verseText: verseText,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  /// Finds a book whose name exactly matches the supplied name.
  static _BibleBookData? _findBookData({
    required List<dynamic> books,
    required String requestedBookName,
  }) {
    final String normalizedRequestedName = normalizeBookName(requestedBookName);

    if (normalizedRequestedName.isEmpty) {
      return null;
    }

    for (int bookIndex = 0; bookIndex < books.length; bookIndex++) {
      final dynamic rawBook = books[bookIndex];

      if (rawBook is! Map) {
        continue;
      }

      final Map<String, dynamic> book = Map<String, dynamic>.from(rawBook);

      final String bookName = book['name']?.toString().trim() ?? '';

      if (normalizeBookName(bookName) != normalizedRequestedName) {
        continue;
      }

      final dynamic rawChapters = book['chapters'];

      if (rawChapters is! Map) {
        return null;
      }

      return _BibleBookData(
        bookName: bookName,
        bookIndex: bookIndex,
        chapters: Map<String, dynamic>.from(rawChapters),
      );
    }

    return null;
  }

  /// Returns the total number of searchable verses.
  static Future<int> getTotalVerseCount() async {
    final Map<String, dynamic> bibleData = await _loadBibleData();

    final List<dynamic> books = bibleData['books'] as List<dynamic>;

    int total = 0;

    for (final dynamic rawBook in books) {
      if (rawBook is! Map) {
        continue;
      }

      final Map<String, dynamic> book = Map<String, dynamic>.from(rawBook);

      final dynamic rawChapters = book['chapters'];

      if (rawChapters is! Map) {
        continue;
      }

      final Map<String, dynamic> chapters = Map<String, dynamic>.from(
        rawChapters,
      );

      for (final dynamic rawVerses in chapters.values) {
        if (rawVerses is List) {
          total += rawVerses.length;
        }
      }
    }

    return total;
  }

  /// Returns the total number of chapters in a specified book.
  static Future<int> getChapterCount(String bookName) async {
    final Map<String, dynamic> bibleData = await _loadBibleData();

    final List<dynamic> books = bibleData['books'] as List<dynamic>;

    final _BibleBookData? bookData = _findBookData(
      books: books,
      requestedBookName: bookName,
    );

    return bookData?.chapters.length ?? 0;
  }

  /// Normalizes text used for verse-text searching.
  static String normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'''["“”‘’.,;:!?()[\]{}<>«»—–-]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalizes a Bible book name.
  ///
  /// It ignores:
  ///
  /// - uppercase and lowercase
  /// - repeated spaces
  /// - dots
  /// - commas
  /// - hyphens
  static String normalizeBookName(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'''["“”‘’.,;!?()[\]{}<>«»—–-]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Clears the cached Bible data.
  static void clearCache() {
    _cachedBibleData = null;
  }
}

/// Internal representation of a Bible book.
///
/// This is only used inside BibleSearchService.
class _BibleBookData {
  const _BibleBookData({
    required this.bookName,
    required this.bookIndex,
    required this.chapters,
  });

  final String bookName;
  final int bookIndex;
  final Map<String, dynamic> chapters;
}
