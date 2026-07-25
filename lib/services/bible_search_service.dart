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

  /// Searches for an exact word or phrase.
  ///
  /// The search ignores:
  /// - uppercase and lowercase differences
  /// - punctuation
  /// - repeated spaces
  static Future<List<BibleSearchResult>> search(String query) async {
    final String normalizedQuery = normalizeText(query);

    if (normalizedQuery.isEmpty) {
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

      /// Total number of chapters in this book.
      ///
      /// This is passed to VerseReadingScreen so it can
      /// correctly handle previous and next chapter navigation.
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

  /// Searches for verses containing every individual
  /// word in the supplied query.
  ///
  /// The words do not need to appear next to each other.
  ///
  /// Example:
  ///
  /// hekima maelekezo
  ///
  /// A verse is returned when it contains both words.
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

  /// Returns the total number of chapters
  /// in the specified Bible book.
  static Future<int> getChapterCount(String bookName) async {
    final Map<String, dynamic> bibleData = await _loadBibleData();

    final List<dynamic> books = bibleData['books'] as List<dynamic>;

    final String normalizedBookName = normalizeText(bookName);

    for (final dynamic rawBook in books) {
      if (rawBook is! Map) {
        continue;
      }

      final Map<String, dynamic> book = Map<String, dynamic>.from(rawBook);

      final String currentBookName = book['name']?.toString() ?? '';

      if (normalizeText(currentBookName) != normalizedBookName) {
        continue;
      }

      final dynamic rawChapters = book['chapters'];

      if (rawChapters is Map) {
        return rawChapters.length;
      }
    }

    return 0;
  }

  /// Converts text into a consistent searchable format.
  ///
  /// It:
  /// - converts text to lowercase
  /// - removes punctuation
  /// - replaces repeated spaces with one space
  static String normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'''["“”‘’.,;:!?()[\]{}<>«»—–-]'''), ' ')
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
  ///
  /// Run this during development after editing
  /// the bible.json asset.
  static void clearCache() {
    _cachedBibleData = null;
  }
}
