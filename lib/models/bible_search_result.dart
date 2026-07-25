class BibleSearchResult {
  const BibleSearchResult({
    required this.bookName,
    required this.bookIndex,
    required this.chapterNumber,
    required this.chapterCount,
    required this.verseNumber,
    required this.verseText,
  });

  /// Name displayed to the user.
  ///
  /// Example:
  /// Mithali
  final String bookName;

  /// Position of the book in the Bible.
  final int bookIndex;

  /// Chapter number.
  final int chapterNumber;

  /// Total chapters in this book.
  ///
  /// Needed by VerseReadingScreen so it knows
  /// whether there is a next/previous chapter.
  final int chapterCount;

  /// Verse number.
  final int verseNumber;

  /// Verse text.
  final String verseText;

  /// Example:
  /// Mithali 3:5
  String get reference {
    return '$bookName $chapterNumber:$verseNumber';
  }

  BibleSearchResult copyWith({
    String? bookName,
    int? bookIndex,
    int? chapterNumber,
    int? chapterCount,
    int? verseNumber,
    String? verseText,
  }) {
    return BibleSearchResult(
      bookName: bookName ?? this.bookName,
      bookIndex: bookIndex ?? this.bookIndex,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      chapterCount: chapterCount ?? this.chapterCount,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookName': bookName,
      'bookIndex': bookIndex,
      'chapterNumber': chapterNumber,
      'chapterCount': chapterCount,
      'verseNumber': verseNumber,
      'verseText': verseText,
    };
  }

  factory BibleSearchResult.fromMap(Map<String, dynamic> map) {
    return BibleSearchResult(
      bookName: map['bookName'] as String? ?? '',
      bookIndex: map['bookIndex'] as int? ?? 0,
      chapterNumber: map['chapterNumber'] as int? ?? 0,
      chapterCount: map['chapterCount'] as int? ?? 0,
      verseNumber: map['verseNumber'] as int? ?? 0,
      verseText: map['verseText'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'BibleSearchResult('
        'reference: $reference, '
        'chapterCount: $chapterCount, '
        'verseText: $verseText'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is BibleSearchResult &&
        other.bookName == bookName &&
        other.bookIndex == bookIndex &&
        other.chapterNumber == chapterNumber &&
        other.chapterCount == chapterCount &&
        other.verseNumber == verseNumber &&
        other.verseText == verseText;
  }

  @override
  int get hashCode {
    return Object.hash(
      bookName,
      bookIndex,
      chapterNumber,
      chapterCount,
      verseNumber,
      verseText,
    );
  }
}
