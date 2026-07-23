import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgress {
  const ReadingProgress({
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
  });

  final String bookName;
  final int chapterNumber;
  final int chapterCount;
}

class ReadingProgressService {
  static const String _bookNameKey = 'last_read_book';
  static const String _chapterNumberKey = 'last_read_chapter';
  static const String _chapterCountKey = 'last_read_chapter_count';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static Future<void> saveProgress({
    required String bookName,
    required int chapterNumber,
    required int chapterCount,
  }) async {
    await Future.wait([
      _preferences.setString(_bookNameKey, bookName),
      _preferences.setInt(_chapterNumberKey, chapterNumber),
      _preferences.setInt(_chapterCountKey, chapterCount),
    ]);
  }

  static Future<ReadingProgress?> getProgress() async {
    final results = await Future.wait<Object?>([
      _preferences.getString(_bookNameKey),
      _preferences.getInt(_chapterNumberKey),
      _preferences.getInt(_chapterCountKey),
    ]);

    final String? bookName = results[0] as String?;
    final int? chapterNumber = results[1] as int?;
    final int? chapterCount = results[2] as int?;

    if (bookName == null ||
        bookName.trim().isEmpty ||
        chapterNumber == null ||
        chapterCount == null) {
      return null;
    }

    if (chapterNumber < 1 || chapterCount < 1 || chapterNumber > chapterCount) {
      return null;
    }

    return ReadingProgress(
      bookName: bookName,
      chapterNumber: chapterNumber,
      chapterCount: chapterCount,
    );
  }

  static Future<void> clearProgress() async {
    await Future.wait([
      _preferences.remove(_bookNameKey),
      _preferences.remove(_chapterNumberKey),
      _preferences.remove(_chapterCountKey),
    ]);
  }
}
