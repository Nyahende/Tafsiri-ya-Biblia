import 'dart:convert';

import 'package:flutter/services.dart';

const String audioBibleBaseUrl = 'https://audio.jifunzebiblia.co.tz';

const String _audioManifestAssetPath = 'assets/data/audio_manifest.json';

enum AudioBibleTestament { oldTestament, newTestament }

class AudioBibleBook {
  const AudioBibleBook({
    required this.id,
    required this.name,
    required this.testament,
    required this.chapterCount,
    required this.chapters,
  });

  final String id;
  final String name;
  final AudioBibleTestament testament;
  final int chapterCount;
  final List<AudioBibleChapter> chapters;
}

class AudioBibleChapter {
  const AudioBibleChapter({
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    required this.remotePath,
    required this.bytes,
    this.sha256,
  });

  final String bookId;
  final String bookName;
  final int chapterNumber;
  final String remotePath;
  final int bytes;
  final String? sha256;

  String get mediaId => 'audio|$bookId|$chapterNumber';

  String get title => '$bookName — Sura ya $chapterNumber';

  String get audioUrl => '$audioBibleBaseUrl/$remotePath';
}

class _AudioBibleCatalog {
  List<AudioBibleBook> _books = const <AudioBibleBook>[];
  bool _loaded = false;

  List<AudioBibleBook> get books => _books;

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    final String rawJson = await rootBundle.loadString(_audioManifestAssetPath);

    final Object? decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Muundo wa audio_manifest.json si sahihi.');
    }

    final Object? rawBooks = decoded['books'];

    if (rawBooks is! List) {
      throw const FormatException(
        'audio_manifest.json haina orodha sahihi ya vitabu.',
      );
    }

    final List<AudioBibleBook> parsedBooks = <AudioBibleBook>[];

    for (final Object? rawBook in rawBooks) {
      if (rawBook is! Map<String, dynamic>) {
        continue;
      }

      final String id = rawBook['id']?.toString().trim() ?? '';
      final String name = rawBook['name']?.toString().trim() ?? '';
      final String testamentText =
          rawBook['testament']?.toString().trim() ?? '';
      final int? chapterCount = _asInt(rawBook['chapterCount']);

      if (id.isEmpty ||
          name.isEmpty ||
          chapterCount == null ||
          chapterCount < 1) {
        continue;
      }

      final AudioBibleTestament testament = testamentText == 'Agano la Kale'
          ? AudioBibleTestament.oldTestament
          : AudioBibleTestament.newTestament;

      final List<AudioBibleChapter> chapters = <AudioBibleChapter>[];

      final Object? rawChapters = rawBook['chapters'];

      if (rawChapters is List) {
        for (final Object? rawChapter in rawChapters) {
          if (rawChapter is! Map<String, dynamic>) {
            continue;
          }

          final int? chapterNumber = _asInt(rawChapter['number']);
          final int? bytes = _asInt(rawChapter['bytes']);
          final String remotePath = rawChapter['path']?.toString().trim() ?? '';

          if (chapterNumber == null ||
              chapterNumber < 1 ||
              bytes == null ||
              bytes < 1 ||
              remotePath.isEmpty) {
            continue;
          }

          chapters.add(
            AudioBibleChapter(
              bookId: id,
              bookName: name,
              chapterNumber: chapterNumber,
              remotePath: remotePath,
              bytes: bytes,
              sha256: rawChapter['sha256']?.toString().trim(),
            ),
          );
        }
      }

      chapters.sort(
        (AudioBibleChapter first, AudioBibleChapter second) =>
            first.chapterNumber.compareTo(second.chapterNumber),
      );

      parsedBooks.add(
        AudioBibleBook(
          id: id,
          name: name,
          testament: testament,
          chapterCount: chapterCount,
          chapters: List<AudioBibleChapter>.unmodifiable(chapters),
        ),
      );
    }

    if (parsedBooks.isEmpty) {
      throw const FormatException(
        'Hakuna vitabu halali katika audio_manifest.json.',
      );
    }

    _books = List<AudioBibleBook>.unmodifiable(parsedBooks);
    _loaded = true;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

final _AudioBibleCatalog _audioBibleCatalog = _AudioBibleCatalog();

Future<void> initializeAudioBibleCatalog() {
  return _audioBibleCatalog.load();
}

List<AudioBibleBook> get audioBibleBooks => _audioBibleCatalog.books;

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

  for (final AudioBibleChapter chapter in book.chapters) {
    if (chapter.chapterNumber == chapterNumber) {
      return chapter;
    }
  }

  return null;
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
  return findAudioBibleChapter(bookId: bookId, chapterNumber: chapterNumber) !=
      null;
}

int availableAudioChapterCount(AudioBibleBook book) {
  return book.chapters.length;
}

List<AudioBibleChapter> availableAudioChaptersForBook(AudioBibleBook book) {
  return book.chapters;
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
