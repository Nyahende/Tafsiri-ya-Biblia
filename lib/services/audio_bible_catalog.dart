enum AudioBibleTestament { oldTestament, newTestament }

class AudioBibleBook {
  const AudioBibleBook({
    required this.id,
    required this.name,
    required this.testament,
    required this.chapterCount,
  });

  final String id;
  final String name;
  final AudioBibleTestament testament;
  final int chapterCount;
}

class AudioBibleChapter {
  const AudioBibleChapter({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.assetPath,
  });

  final String bookId;
  final String bookName;
  final int chapterNumber;
  final String assetPath;

  String get mediaId => 'audio|$bookId|$chapterNumber';

  String get title => '$bookName — Sura ya $chapterNumber';
}

/// All 66 Bible books are shown in the Audio Bible library.
///
/// Audio availability is kept separately from the Bible book structure so that
/// recordings can be added gradually without changing the reading Bible data.
const List<AudioBibleBook> audioBibleBooks = <AudioBibleBook>[
  AudioBibleBook(
    id: 'mwanzo',
    name: 'Mwanzo',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 50,
  ),
  AudioBibleBook(
    id: 'kutoka',
    name: 'Kutoka',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 40,
  ),
  AudioBibleBook(
    id: 'mambo ya walawi',
    name: 'Mambo ya Walawi',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 27,
  ),
  AudioBibleBook(
    id: 'hesabu',
    name: 'Hesabu',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 36,
  ),
  AudioBibleBook(
    id: 'kumbukumbu_la_torati',
    name: 'Kumbukumbu la Torati',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 34,
  ),
  AudioBibleBook(
    id: 'yoshua',
    name: 'Yoshua',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 24,
  ),
  AudioBibleBook(
    id: 'waamuzi',
    name: 'Waamuzi',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 21,
  ),
  AudioBibleBook(
    id: 'ruthu',
    name: 'Ruthu',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: '1_samweli',
    name: '1 Samweli',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 31,
  ),
  AudioBibleBook(
    id: '2_samweli',
    name: '2 Samweli',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 24,
  ),
  AudioBibleBook(
    id: '1_wafalme',
    name: '1 Wafalme',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 22,
  ),
  AudioBibleBook(
    id: '2_wafalme',
    name: '2 Wafalme',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 25,
  ),
  AudioBibleBook(
    id: '1_nyakati',
    name: '1 Nyakati',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 29,
  ),
  AudioBibleBook(
    id: '2_nyakati',
    name: '2 Nyakati',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 36,
  ),
  AudioBibleBook(
    id: 'ezra',
    name: 'Ezra',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 10,
  ),
  AudioBibleBook(
    id: 'nehemia',
    name: 'Nehemia',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 13,
  ),
  AudioBibleBook(
    id: 'esta',
    name: 'Esta',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 10,
  ),
  AudioBibleBook(
    id: 'ayubu',
    name: 'Ayubu',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 42,
  ),
  AudioBibleBook(
    id: 'zaburi',
    name: 'Zaburi',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 150,
  ),
  AudioBibleBook(
    id: 'mithali',
    name: 'Mithali',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 31,
  ),
  AudioBibleBook(
    id: 'mhubiri',
    name: 'Mhubiri',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 12,
  ),
  AudioBibleBook(
    id: 'wimbo_ulio_bora',
    name: 'Wimbo Ulio Bora',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 8,
  ),
  AudioBibleBook(
    id: 'isaya',
    name: 'Isaya',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 66,
  ),
  AudioBibleBook(
    id: 'yeremia',
    name: 'Yeremia',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 52,
  ),
  AudioBibleBook(
    id: 'maombolezo',
    name: 'Maombolezo',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 5,
  ),
  AudioBibleBook(
    id: 'ezekiel',
    name: 'Ezekiel',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 48,
  ),
  AudioBibleBook(
    id: 'daniel',
    name: 'Daniel',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 12,
  ),
  AudioBibleBook(
    id: 'hosea',
    name: 'Hosea',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 14,
  ),
  AudioBibleBook(
    id: 'Yoeli',
    name: 'Yoeli',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: 'amosi',
    name: 'Amosi',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 9,
  ),
  AudioBibleBook(
    id: 'obadiah',
    name: 'Obadia',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 1,
  ),
  AudioBibleBook(
    id: 'yona',
    name: 'Yona',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: 'mika',
    name: 'Mika',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 7,
  ),
  AudioBibleBook(
    id: 'nahumu',
    name: 'Nahumu',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: 'habakuki',
    name: 'Habakuki',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: 'sefania',
    name: 'Sefania',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: 'hagai',
    name: 'Hagai',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 2,
  ),
  AudioBibleBook(
    id: 'zakaria',
    name: 'Zakaria',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 14,
  ),
  AudioBibleBook(
    id: 'malaki',
    name: 'Malaki',
    testament: AudioBibleTestament.oldTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: 'mathayo',
    name: 'Mathayo',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 28,
  ),
  AudioBibleBook(
    id: 'marko',
    name: 'Marko',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 16,
  ),
  AudioBibleBook(
    id: 'luka',
    name: 'Luka',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 24,
  ),
  AudioBibleBook(
    id: 'yohana',
    name: 'Yohana',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 21,
  ),
  AudioBibleBook(
    id: 'matendo',
    name: 'Matendo ya Mitume',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 28,
  ),
  AudioBibleBook(
    id: 'warumi',
    name: 'Warumi',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 16,
  ),
  AudioBibleBook(
    id: '1_wakorintho',
    name: '1 Wakorintho',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 16,
  ),
  AudioBibleBook(
    id: '2_wakorintho',
    name: '2 Wakorintho',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 13,
  ),
  AudioBibleBook(
    id: 'wagalatia',
    name: 'Wagalatia',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 6,
  ),
  AudioBibleBook(
    id: 'waefeso',
    name: 'Waefeso',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 6,
  ),
  AudioBibleBook(
    id: 'wafilipi',
    name: 'Wafilipi',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: 'wakolosai',
    name: 'Wakolosai',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: '1_wathesalonike',
    name: '1 Wathesalonike',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 5,
  ),
  AudioBibleBook(
    id: '2_wathesalonike',
    name: '2 Wathesalonike',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: '1_timotheo',
    name: '1 Timotheo',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 6,
  ),
  AudioBibleBook(
    id: '2_timotheo',
    name: '2 Timotheo',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 4,
  ),
  AudioBibleBook(
    id: 'tito',
    name: 'Tito',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: 'filemoni',
    name: 'Filemoni',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 1,
  ),
  AudioBibleBook(
    id: 'waebrania',
    name: 'Waebrania',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 13,
  ),
  AudioBibleBook(
    id: 'yakobo',
    name: 'Yakobo',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 5,
  ),
  AudioBibleBook(
    id: '1_petro',
    name: '1 Petro',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 5,
  ),
  AudioBibleBook(
    id: '2_petro',
    name: '2 Petro',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 3,
  ),
  AudioBibleBook(
    id: '1_yohana',
    name: '1 Yohana',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 5,
  ),
  AudioBibleBook(
    id: '2_yohana',
    name: '2 Yohana',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 1,
  ),
  AudioBibleBook(
    id: '3_yohana',
    name: '3 Yohana',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 1,
  ),
  AudioBibleBook(
    id: 'yuda',
    name: 'Yuda',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 1,
  ),
  AudioBibleBook(
    id: 'ufunuo_wa_yohana',
    name: 'Ufunuo wa Yohana',
    testament: AudioBibleTestament.newTestament,
    chapterCount: 22,
  ),
];

/// Local recordings currently supplied for testing.
///
/// Add future recordings here (or replace this map with a remote manifest)
/// without changing the Audio Bible navigation/player architecture.
const Map<String, String> _audioAssets = <String, String>{
  'mathayo:2': 'assets/audio/mathayo/02.mp3',
  'mathayo:3': 'assets/audio/mathayo/03.mp3',
  'mathayo:4': 'assets/audio/mathayo/04.mp3',
  'mathayo:5': 'assets/audio/mathayo/05.mp3',
};

String _audioAssetKey(String bookId, int chapterNumber) {
  return '$bookId:$chapterNumber';
}

List<AudioBibleBook> booksForTestament(AudioBibleTestament testament) {
  return audioBibleBooks
      .where((AudioBibleBook book) => book.testament == testament)
      .toList(growable: false);
}

AudioBibleBook? findAudioBibleBookById(String bookId) {
  for (final AudioBibleBook book in audioBibleBooks) {
    if (book.id == bookId) {
      return book;
    }
  }
  return null;
}

AudioBibleBook? findAudioBibleBookByName(String bookName) {
  final String normalized = bookName.trim().toLowerCase();

  for (final AudioBibleBook book in audioBibleBooks) {
    if (book.name.trim().toLowerCase() == normalized) {
      return book;
    }
  }
  return null;
}

AudioBibleChapter? findAudioBibleChapter({
  required String bookId,
  required int chapterNumber,
}) {
  final AudioBibleBook? book = findAudioBibleBookById(bookId);
  if (book == null || chapterNumber < 1 || chapterNumber > book.chapterCount) {
    return null;
  }

  final String? assetPath =
      _audioAssets[_audioAssetKey(book.id, chapterNumber)];

  if (assetPath == null) {
    return null;
  }

  return AudioBibleChapter(
    bookId: book.id,
    bookName: book.name,
    chapterNumber: chapterNumber,
    assetPath: assetPath,
  );
}

AudioBibleChapter? findAudioBibleChapterByMediaId(String mediaId) {
  final List<String> parts = mediaId.split('|');

  if (parts.length != 3 || parts[0] != 'audio') {
    return null;
  }

  final int? chapterNumber = int.tryParse(parts[2]);
  if (chapterNumber == null) {
    return null;
  }

  return findAudioBibleChapter(bookId: parts[1], chapterNumber: chapterNumber);
}

bool hasAudioForChapter({required String bookId, required int chapterNumber}) {
  return _audioAssets.containsKey(_audioAssetKey(bookId, chapterNumber));
}

int availableAudioChapterCount(AudioBibleBook book) {
  int count = 0;

  for (int chapter = 1; chapter <= book.chapterCount; chapter++) {
    if (hasAudioForChapter(bookId: book.id, chapterNumber: chapter)) {
      count++;
    }
  }

  return count;
}

List<AudioBibleChapter> availableAudioChaptersForBook(AudioBibleBook book) {
  final List<AudioBibleChapter> chapters = <AudioBibleChapter>[];

  for (int chapter = 1; chapter <= book.chapterCount; chapter++) {
    final AudioBibleChapter? audioChapter = findAudioBibleChapter(
      bookId: book.id,
      chapterNumber: chapter,
    );

    if (audioChapter != null) {
      chapters.add(audioChapter);
    }
  }

  return chapters;
}

AudioBibleChapter? previousAudioBibleChapter(AudioBibleChapter current) {
  if (current.chapterNumber <= 1) {
    return null;
  }

  return findAudioBibleChapter(
    bookId: current.bookId,
    chapterNumber: current.chapterNumber - 1,
  );
}

AudioBibleChapter? nextAudioBibleChapter(AudioBibleChapter current) {
  final AudioBibleBook? book = findAudioBibleBookById(current.bookId);

  if (book == null || current.chapterNumber >= book.chapterCount) {
    return null;
  }

  return findAudioBibleChapter(
    bookId: current.bookId,
    chapterNumber: current.chapterNumber + 1,
  );
}
