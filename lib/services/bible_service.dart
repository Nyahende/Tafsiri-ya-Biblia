import 'dart:convert';

import 'package:flutter/services.dart';

class BibleService {
  static const String _dataPath = 'assets/data/bible.json';

  static Future<Map<String, dynamic>>? _cachedBibleData;

  static Future<Map<String, dynamic>> _loadBibleData() {
    return _cachedBibleData ??= _readBibleData();
  }

  static Future<Map<String, dynamic>> _readBibleData() async {
    try {
      final String jsonString = await rootBundle.loadString(_dataPath);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException {
      throw const BibleDataException('Muundo wa faili la Biblia si sahihi.');
    } catch (error) {
      throw BibleDataException('Imeshindikana kupakia Biblia: $error');
    }
  }

  static Future<List<BibleVerse>> getVerses({
    required String bookName,
    required int chapterNumber,
  }) async {
    try {
      final Map<String, dynamic> jsonData = await _loadBibleData();
      final List<dynamic> books = jsonData['books'] as List<dynamic>? ?? [];

      final Map<String, dynamic>? selectedBook = _findBook(
        books: books,
        bookName: bookName,
      );

      if (selectedBook == null) {
        throw BibleDataException('Kitabu "$bookName" hakijapatikana.');
      }

      final Map<String, dynamic> chapters =
          selectedBook['chapters'] as Map<String, dynamic>? ?? {};

      final List<dynamic>? chapterData =
          chapters[chapterNumber.toString()] as List<dynamic>?;

      if (chapterData == null) {
        throw BibleDataException(
          '$bookName sura ya $chapterNumber haijapatikana.',
        );
      }

      return chapterData.map((verseData) {
        final Map<String, dynamic> verse = verseData as Map<String, dynamic>;
        return BibleVerse.fromJson(verse);
      }).toList();
    } on BibleDataException {
      rethrow;
    } catch (error) {
      throw BibleDataException('Imeshindikana kupakia mistari: $error');
    }
  }

  static Future<DailyBibleVerse> getVerseOfTheDay({DateTime? date}) async {
    try {
      final Map<String, dynamic> jsonData = await _loadBibleData();
      final List<dynamic> books = jsonData['books'] as List<dynamic>? ?? [];
      final List<DailyBibleVerse> allVerses = [];

      for (final dynamic bookData in books) {
        final Map<String, dynamic> book = bookData as Map<String, dynamic>;
        final String bookName = book['name']?.toString() ?? '';
        final Map<String, dynamic> chapters =
            book['chapters'] as Map<String, dynamic>? ?? {};
        final int chapterCount = chapters.length;

        final chapterEntries = chapters.entries.toList()
          ..sort((a, b) {
            final int aNumber = int.tryParse(a.key) ?? 0;
            final int bNumber = int.tryParse(b.key) ?? 0;
            return aNumber.compareTo(bNumber);
          });

        for (final chapterEntry in chapterEntries) {
          final int chapterNumber = int.tryParse(chapterEntry.key) ?? 0;
          final List<dynamic> verseData =
              chapterEntry.value as List<dynamic>? ?? [];

          for (final dynamic verseItem in verseData) {
            final Map<String, dynamic> verseMap =
                verseItem as Map<String, dynamic>;
            final BibleVerse verse = BibleVerse.fromJson(verseMap);

            if (bookName.trim().isEmpty ||
                chapterNumber < 1 ||
                verse.text.trim().isEmpty) {
              continue;
            }

            allVerses.add(
              DailyBibleVerse(
                bookName: bookName,
                chapterNumber: chapterNumber,
                chapterCount: chapterCount,
                verseNumber: verse.number,
                verseText: verse.text,
              ),
            );
          }
        }
      }

      if (allVerses.isEmpty) {
        throw const BibleDataException('Hakuna mistari inayopatikana.');
      }

      final DateTime selectedDate = date ?? DateTime.now();
      final DateTime dateOnly = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final int dayNumber = dateOnly.difference(DateTime(2025, 1, 1)).inDays;
      final int selectedIndex = dayNumber.abs() % allVerses.length;

      return allVerses[selectedIndex];
    } on BibleDataException {
      rethrow;
    } catch (error) {
      throw BibleDataException('Imeshindikana kupata Neno la Leo: $error');
    }
  }

  static Future<BibleReferenceVerse> getReferenceVerse({
    required String bookId,
    required int chapterNumber,
    required int verseNumber,
  }) async {
    try {
      final Map<String, dynamic> jsonData = await _loadBibleData();
      final List<dynamic> books = jsonData['books'] as List<dynamic>? ?? [];

      Map<String, dynamic>? selectedBook;

      for (final dynamic bookData in books) {
        final Map<String, dynamic> book = bookData as Map<String, dynamic>;
        final String currentBookId = book['id']?.toString() ?? '';

        if (currentBookId.toLowerCase() == bookId.toLowerCase()) {
          selectedBook = book;
          break;
        }
      }

      if (selectedBook == null) {
        throw BibleDataException('Kitabu chenye ID "$bookId" hakijapatikana.');
      }

      final String bookName = selectedBook['name']?.toString() ?? '';
      final Map<String, dynamic> chapters =
          selectedBook['chapters'] as Map<String, dynamic>? ?? {};
      final int chapterCount =
          int.tryParse(selectedBook['chapterCount']?.toString() ?? '') ??
          chapters.length;

      final List<dynamic>? chapterData =
          chapters[chapterNumber.toString()] as List<dynamic>?;

      if (chapterData == null) {
        throw BibleDataException(
          '$bookName sura ya $chapterNumber haijapatikana.',
        );
      }

      for (final dynamic verseData in chapterData) {
        final Map<String, dynamic> verseMap = verseData as Map<String, dynamic>;
        final BibleVerse verse = BibleVerse.fromJson(verseMap);

        if (verse.number == verseNumber) {
          return BibleReferenceVerse(
            bookId: bookId,
            bookName: bookName,
            chapterNumber: chapterNumber,
            chapterCount: chapterCount,
            verseNumber: verse.number,
            verseText: verse.text,
          );
        }
      }

      throw BibleDataException(
        '$bookName $chapterNumber:$verseNumber haujapatikana.',
      );
    } on BibleDataException {
      rethrow;
    } catch (error) {
      throw BibleDataException('Imeshindikana kupakia rejeo: $error');
    }
  }

  static Map<String, dynamic>? _findBook({
    required List<dynamic> books,
    required String bookName,
  }) {
    for (final dynamic bookData in books) {
      final Map<String, dynamic> book = bookData as Map<String, dynamic>;
      final String currentBookName = book['name']?.toString() ?? '';

      if (currentBookName.toLowerCase() == bookName.toLowerCase()) {
        return book;
      }
    }

    return null;
  }
}

class DailyBibleVerse {
  const DailyBibleVerse({
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
    required this.verseNumber,
    required this.verseText,
  });

  final String bookName;
  final int chapterNumber;
  final int chapterCount;
  final int verseNumber;
  final String verseText;

  String get reference => '$bookName $chapterNumber:$verseNumber';
}

class BibleReferenceVerse {
  const BibleReferenceVerse({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
    required this.verseNumber,
    required this.verseText,
  });

  final String bookId;
  final String bookName;
  final int chapterNumber;
  final int chapterCount;
  final int verseNumber;
  final String verseText;

  String get reference => '$bookName $chapterNumber:$verseNumber';
}

class BibleVerse {
  const BibleVerse({required this.number, required this.text});

  final int number;
  final String text;

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      number: json['number'] as int,
      text: json['text']?.toString() ?? '',
    );
  }
}

class BibleDataException implements Exception {
  const BibleDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
