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

  String get id => '$bookName-$chapterNumber-$verseNumber';

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
      bookName: json['bookName'] as String,
      chapterNumber: json['chapterNumber'] as int,
      chapterCount: json['chapterCount'] as int,
      verseNumber: json['verseNumber'] as int,
      verseText: json['verseText'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

class BookmarkService {
  static const String _bookmarksKey = 'saved_bible_bookmarks';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<List<BibleBookmark>> getBookmarks() async {
    final String? rawData = await _preferences.getString(_bookmarksKey);

    if (rawData == null || rawData.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawData);

      if (decoded is! List) {
        return [];
      }

      final bookmarks = decoded
          .whereType<Map>()
          .map(
            (item) => BibleBookmark.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      bookmarks.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return bookmarks;
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isBookmarked({
    required String bookName,
    required int chapterNumber,
    required int verseNumber,
  }) async {
    final bookmarks = await getBookmarks();
    final id = '$bookName-$chapterNumber-$verseNumber';

    return bookmarks.any((bookmark) => bookmark.id == id);
  }

  static Future<void> addBookmark(BibleBookmark bookmark) async {
    final bookmarks = await getBookmarks();

    final exists = bookmarks.any((item) => item.id == bookmark.id);

    if (exists) {
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
    final bookmarks = await getBookmarks();
    final id = '$bookName-$chapterNumber-$verseNumber';

    bookmarks.removeWhere((bookmark) => bookmark.id == id);

    await _saveBookmarks(bookmarks);
  }

  static Future<void> toggleBookmark(BibleBookmark bookmark) async {
    final bookmarked = await isBookmarked(
      bookName: bookmark.bookName,
      chapterNumber: bookmark.chapterNumber,
      verseNumber: bookmark.verseNumber,
    );

    if (bookmarked) {
      await removeBookmark(
        bookName: bookmark.bookName,
        chapterNumber: bookmark.chapterNumber,
        verseNumber: bookmark.verseNumber,
      );
    } else {
      await addBookmark(bookmark);
    }
  }

  static Future<void> clearBookmarks() async {
    await _preferences.remove(_bookmarksKey);
  }

  static Future<void> _saveBookmarks(List<BibleBookmark> bookmarks) async {
    final encoded = jsonEncode(
      bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    );

    await _preferences.setString(_bookmarksKey, encoded);
  }
}
