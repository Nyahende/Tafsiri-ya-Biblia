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
      // Curated references only. The actual verse text still comes from
      // the existing bible.json through getReferenceVerse().
      const List<({String bookId, int chapter, int verse})> curatedVerses = [
        (bookId: 'mwanzo', chapter: 15, verse: 1),
        (bookId: 'kutoka', chapter: 14, verse: 14),
        (bookId: 'kumbukumbu_la_torati', chapter: 31, verse: 8),
        (bookId: 'yoshua', chapter: 1, verse: 9),
        (bookId: 'zaburi', chapter: 23, verse: 1),
        (bookId: 'zaburi', chapter: 23, verse: 4),
        (bookId: 'zaburi', chapter: 27, verse: 1),
        (bookId: 'zaburi', chapter: 34, verse: 8),
        (bookId: 'zaburi', chapter: 37, verse: 5),
        (bookId: 'zaburi', chapter: 46, verse: 1),
        (bookId: 'zaburi', chapter: 55, verse: 22),
        (bookId: 'zaburi', chapter: 91, verse: 1),
        (bookId: 'zaburi', chapter: 119, verse: 105),
        (bookId: 'zaburi', chapter: 121, verse: 2),
        (bookId: 'mithali', chapter: 3, verse: 5),
        (bookId: 'mithali', chapter: 3, verse: 6),
        (bookId: 'mithali', chapter: 4, verse: 23),
        (bookId: 'mithali', chapter: 16, verse: 3),
        (bookId: 'isaya', chapter: 26, verse: 3),
        (bookId: 'isaya', chapter: 40, verse: 31),
        (bookId: 'isaya', chapter: 41, verse: 10),
        (bookId: 'isaya', chapter: 43, verse: 2),
        (bookId: 'yeremia', chapter: 29, verse: 11),
        (bookId: 'yeremia', chapter: 33, verse: 3),
        (bookId: 'maombolezo', chapter: 3, verse: 23),
        (bookId: 'nahumu', chapter: 1, verse: 7),
        (bookId: 'sefania', chapter: 3, verse: 17),
        (bookId: 'mathayo', chapter: 5, verse: 14),
        (bookId: 'mathayo', chapter: 5, verse: 16),
        (bookId: 'mathayo', chapter: 6, verse: 33),
        (bookId: 'mathayo', chapter: 6, verse: 34),
        (bookId: 'mathayo', chapter: 7, verse: 7),
        (bookId: 'mathayo', chapter: 11, verse: 28),
        (bookId: 'mathayo', chapter: 11, verse: 29),
        (bookId: 'mathayo', chapter: 17, verse: 20),
        (bookId: 'mathayo', chapter: 19, verse: 26),
        (bookId: 'mathayo', chapter: 21, verse: 22),
        (bookId: 'mathayo', chapter: 22, verse: 37),
        (bookId: 'mathayo', chapter: 22, verse: 39),
        (bookId: 'mathayo', chapter: 28, verse: 20),
        (bookId: 'marko', chapter: 9, verse: 23),
        (bookId: 'marko', chapter: 11, verse: 24),
        (bookId: 'luka', chapter: 6, verse: 31),
        (bookId: 'luka', chapter: 8, verse: 50),
        (bookId: 'luka', chapter: 11, verse: 9),
        (bookId: 'luka', chapter: 12, verse: 32),
        (bookId: 'luka', chapter: 18, verse: 27),
        (bookId: 'yohana', chapter: 3, verse: 16),
        (bookId: 'yohana', chapter: 6, verse: 35),
        (bookId: 'yohana', chapter: 8, verse: 12),
        (bookId: 'yohana', chapter: 8, verse: 32),
        (bookId: 'yohana', chapter: 10, verse: 10),
        (bookId: 'yohana', chapter: 10, verse: 27),
        (bookId: 'yohana', chapter: 10, verse: 28),
        (bookId: 'yohana', chapter: 11, verse: 25),
        (bookId: 'yohana', chapter: 13, verse: 34),
        (bookId: 'yohana', chapter: 14, verse: 1),
        (bookId: 'yohana', chapter: 14, verse: 6),
        (bookId: 'yohana', chapter: 14, verse: 18),
        (bookId: 'yohana', chapter: 14, verse: 27),
        (bookId: 'yohana', chapter: 15, verse: 5),
        (bookId: 'yohana', chapter: 15, verse: 7),
        (bookId: 'yohana', chapter: 15, verse: 12),
        (bookId: 'yohana', chapter: 16, verse: 33),
        (bookId: 'matendo', chapter: 1, verse: 8),
        (bookId: 'warumi', chapter: 5, verse: 8),
        (bookId: 'warumi', chapter: 8, verse: 1),
        (bookId: 'warumi', chapter: 8, verse: 28),
        (bookId: 'warumi', chapter: 8, verse: 31),
        (bookId: 'warumi', chapter: 8, verse: 37),
        (bookId: 'warumi', chapter: 8, verse: 38),
        (bookId: 'warumi', chapter: 8, verse: 39),
        (bookId: 'warumi', chapter: 10, verse: 17),
        (bookId: 'warumi', chapter: 12, verse: 12),
        (bookId: 'warumi', chapter: 15, verse: 13),
        (bookId: '1_wakorintho', chapter: 10, verse: 13),
        (bookId: '1_wakorintho', chapter: 13, verse: 13),
        (bookId: '1_wakorintho', chapter: 15, verse: 58),
        (bookId: '2_wakorintho', chapter: 4, verse: 16),
        (bookId: '2_wakorintho', chapter: 5, verse: 7),
        (bookId: '2_wakorintho', chapter: 12, verse: 9),
        (bookId: 'wagalatia', chapter: 5, verse: 22),
        (bookId: 'wagalatia', chapter: 6, verse: 9),
        (bookId: 'waefeso', chapter: 2, verse: 8),
        (bookId: 'waefeso', chapter: 3, verse: 20),
        (bookId: 'waefeso', chapter: 6, verse: 10),
        (bookId: 'wafilipi', chapter: 1, verse: 6),
        (bookId: 'wafilipi', chapter: 4, verse: 4),
        (bookId: 'wafilipi', chapter: 4, verse: 6),
        (bookId: 'wafilipi', chapter: 4, verse: 7),
        (bookId: 'wafilipi', chapter: 4, verse: 8),
        (bookId: 'wafilipi', chapter: 4, verse: 13),
        (bookId: 'wafilipi', chapter: 4, verse: 19),
        (bookId: 'wakolosai', chapter: 3, verse: 15),
        (bookId: '1_wathesalonike', chapter: 5, verse: 16),
        (bookId: '1_wathesalonike', chapter: 5, verse: 17),
        (bookId: '1_wathesalonike', chapter: 5, verse: 18),
        (bookId: '2_timotheo', chapter: 1, verse: 7),
        (bookId: 'waebrania', chapter: 4, verse: 16),
        (bookId: 'waebrania', chapter: 10, verse: 23),
        (bookId: 'waebrania', chapter: 11, verse: 1),
        (bookId: 'waebrania', chapter: 11, verse: 6),
        (bookId: 'waebrania', chapter: 13, verse: 5),
        (bookId: 'yakobo', chapter: 1, verse: 5),
        (bookId: 'yakobo', chapter: 1, verse: 17),
        (bookId: 'yakobo', chapter: 4, verse: 8),
        (bookId: '1_petro', chapter: 5, verse: 7),
        (bookId: '1_yohana', chapter: 1, verse: 9),
        (bookId: '1_yohana', chapter: 4, verse: 4),
        (bookId: '1_yohana', chapter: 4, verse: 8),
        (bookId: '1_yohana', chapter: 4, verse: 18),
        (bookId: 'ufunuo_wa_yohana', chapter: 3, verse: 20),
        (bookId: 'ufunuo_wa_yohana', chapter: 21, verse: 4),
      ];

      final DateTime selectedDate = date ?? DateTime.now();
      final DateTime dateOnly = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      final int dayNumber = dateOnly.difference(DateTime(2025, 1, 1)).inDays;
      final int selectedIndex = dayNumber.abs() % curatedVerses.length;
      final selected = curatedVerses[selectedIndex];

      final BibleReferenceVerse verse = await getReferenceVerse(
        bookId: selected.bookId,
        chapterNumber: selected.chapter,
        verseNumber: selected.verse,
      );

      return DailyBibleVerse(
        bookName: verse.bookName,
        chapterNumber: verse.chapterNumber,
        chapterCount: verse.chapterCount,
        verseNumber: verse.verseNumber,
        verseText: verse.verseText,
      );
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
