import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BibleBookmark {
  const BibleBookmark({
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
    required this.verseNumber,
    required this.verseText,
    required this.savedAt,
  });

  final String bookName;
  final int chapterNumber;
  final int chapterCount;
  final int verseNumber;
  final String verseText;
  final DateTime savedAt;

  String get id =>
      '${bookName.trim().toLowerCase()}-$chapterNumber-$verseNumber';

  String get reference => '$bookName $chapterNumber:$verseNumber';

  Map<String, dynamic> toJson() {
    return {
      'bookName': bookName,
      'chapterNumber': chapterNumber,
      'chapterCount': chapterCount,
      'verseNumber': verseNumber,
      'verseText': verseText,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory BibleBookmark.fromJson(Map<String, dynamic> json) {
    return BibleBookmark(
      bookName: json['bookName']?.toString() ?? '',
      chapterNumber: _parseInt(json['chapterNumber']),
      chapterCount: _parseInt(json['chapterCount']),
      verseNumber: _parseInt(json['verseNumber']),
      verseText: json['verseText']?.toString() ?? '',
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BookmarkService {
  BookmarkService._();

  static const String _bookmarksKey = 'saved_bible_bookmarks';

  static Future<SharedPreferences> get _preferences async {
    return SharedPreferences.getInstance();
  }

  static Future<List<BibleBookmark>> getBookmarks() async {
    try {
      final SharedPreferences preferences = await _preferences;

      final String? rawData = preferences.getString(_bookmarksKey);

      if (rawData == null || rawData.trim().isEmpty) {
        return [];
      }

      final dynamic decodedData = jsonDecode(rawData);

      if (decodedData is! List) {
        return [];
      }

      final List<BibleBookmark> bookmarks = [];

      for (final dynamic item in decodedData) {
        if (item is! Map) {
          continue;
        }

        final BibleBookmark bookmark = BibleBookmark.fromJson(
          Map<String, dynamic>.from(item),
        );

        if (bookmark.bookName.trim().isEmpty ||
            bookmark.chapterNumber < 1 ||
            bookmark.verseNumber < 1 ||
            bookmark.verseText.trim().isEmpty) {
          continue;
        }

        bookmarks.add(bookmark);
      }

      bookmarks.sort(
        (BibleBookmark first, BibleBookmark second) =>
            second.savedAt.compareTo(first.savedAt),
      );

      return bookmarks;
    } catch (error) {
      throw Exception('Imeshindikana kupakia mistari iliyohifadhiwa: $error');
    }
  }

  static Future<bool> isBookmarked({
    required String bookName,
    required int chapterNumber,
    required int verseNumber,
  }) async {
    final List<BibleBookmark> bookmarks = await getBookmarks();

    final String id =
        '${bookName.trim().toLowerCase()}-$chapterNumber-$verseNumber';

    return bookmarks.any((BibleBookmark bookmark) => bookmark.id == id);
  }

  static Future<void> addBookmark(BibleBookmark bookmark) async {
    final List<BibleBookmark> bookmarks = await getBookmarks();

    final bool alreadyExists = bookmarks.any(
      (BibleBookmark item) => item.id == bookmark.id,
    );

    if (alreadyExists) {
      return;
    }

    bookmarks.insert(0, bookmark);

    await _saveBookmarks(bookmarks);
  }

  static Future<void> removeBookmark({
    required String bookName,
    required int chapterNumber,
    required int verseNumber,
  }) async {
    final List<BibleBookmark> bookmarks = await getBookmarks();

    final String id =
        '${bookName.trim().toLowerCase()}-$chapterNumber-$verseNumber';

    bookmarks.removeWhere((BibleBookmark bookmark) => bookmark.id == id);

    await _saveBookmarks(bookmarks);
  }

  static Future<bool> toggleBookmark(BibleBookmark bookmark) async {
    final bool currentlyBookmarked = await isBookmarked(
      bookName: bookmark.bookName,
      chapterNumber: bookmark.chapterNumber,
      verseNumber: bookmark.verseNumber,
    );

    if (currentlyBookmarked) {
      await removeBookmark(
        bookName: bookmark.bookName,
        chapterNumber: bookmark.chapterNumber,
        verseNumber: bookmark.verseNumber,
      );

      return false;
    }

    await addBookmark(bookmark);

    return true;
  }

  static Future<void> clearBookmarks() async {
    final SharedPreferences preferences = await _preferences;

    await preferences.remove(_bookmarksKey);
  }

  static Future<void> _saveBookmarks(List<BibleBookmark> bookmarks) async {
    final SharedPreferences preferences = await _preferences;

    final String encodedData = jsonEncode(
      bookmarks.map((BibleBookmark bookmark) => bookmark.toJson()).toList(),
    );

    final bool saved = await preferences.setString(_bookmarksKey, encodedData);

    if (!saved) {
      throw Exception('SharedPreferences haikuhifadhi taarifa.');
    }
  }
}
