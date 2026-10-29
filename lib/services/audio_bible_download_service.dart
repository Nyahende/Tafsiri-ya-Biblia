import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_bible_catalog.dart';

/// Manages individual chapter MP3 downloads in app-private persistent storage.
/// Downloaded chapters are stored privately and can be managed per book.
class AudioBibleDownloadService extends ChangeNotifier {
  AudioBibleDownloadService._();
  static final AudioBibleDownloadService instance =
      AudioBibleDownloadService._();

  final Map<String, double?> _progress = {};
  final Set<String> _downloaded = {};
  final Map<String, HttpClient> _clients = {};
  final Set<String> _cancelled = {};
  String? _bulkBookId;
  bool _bulkCancelRequested = false;
  int _bulkCompleted = 0;
  int _bulkTotal = 0;
  AudioBibleChapter? _bulkCurrent;
  String? _bulkError;

  bool isBookDownloading(AudioBibleBook book) => _bulkBookId == book.id;
  bool get isAnyBookDownloading => _bulkBookId != null;
  int get bulkCompleted => _bulkCompleted;
  int get bulkTotal => _bulkTotal;
  AudioBibleChapter? get bulkCurrent => _bulkCurrent;
  String? get bulkError => _bulkError;
  double get bulkProgress {
    if (_bulkTotal == 0) return 0.0;
    final currentProgress = _bulkCurrent == null
        ? 0.0
        : (progress(_bulkCurrent!) ?? 0.0);
    return ((_bulkCompleted + currentProgress) / _bulkTotal).clamp(0.0, 1.0);
  }

  Directory? _folder;
  Future<void>? _initializing;

  bool isDownloaded(AudioBibleChapter chapter) =>
      _downloaded.contains(_safeId(chapter));
  bool isDownloading(AudioBibleChapter chapter) =>
      _progress.containsKey(chapter.mediaId);
  double? progress(AudioBibleChapter chapter) => _progress[chapter.mediaId];
  int downloadedCountForBook(AudioBibleBook book) =>
      availableAudioChaptersForBook(book).where(isDownloaded).length;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    final root = await getApplicationSupportDirectory();
    final folder = Directory(
      '${root.path}${Platform.pathSeparator}audio_bible_downloads',
    );
    await folder.create(recursive: true);
    _folder = folder;
    // Recover downloaded status from completed files, not from a stale flag.
    final files = await folder
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.mp3'))
        .cast<File>()
        .toList();
    for (final file in files) {
      if (await file.length() >= 1024) {
        _downloaded.add(file.uri.pathSegments.last.replaceAll('.mp3', ''));
      } else {
        await file.delete();
      }
    }
    notifyListeners();
  }

  // The mediaId is stable but may contain URL separators. Restrict filenames.
  String _safeId(AudioBibleChapter chapter) =>
      '${Uri.encodeComponent(chapter.bookId).replaceAll('%', '_')}_${chapter.chapterNumber}';

  File _target(AudioBibleChapter chapter) =>
      File('${_folder!.path}${Platform.pathSeparator}${_safeId(chapter)}.mp3');

  Future<File?> localFile(AudioBibleChapter chapter) async {
    await initialize();
    final file = _target(chapter);
    if (await file.exists() && await file.length() >= 1024) return file;
    return null;
  }

  /// Actual storage occupied by completed downloads in this book.
  Future<int> bytesForBook(AudioBibleBook book) async {
    await initialize();
    var total = 0;
    for (final chapter in availableAudioChaptersForBook(book)) {
      final file = await localFile(chapter);
      if (file != null) total += await file.length();
    }
    return total;
  }

  Future<int> bytesForChapter(AudioBibleChapter chapter) async {
    final file = await localFile(chapter);
    return file == null ? 0 : file.length();
  }

  /// Never delete an actively downloading file. The caller must protect
  /// the currently loaded chapter to avoid breaking an open audio source.
  Future<bool> deleteChapter(AudioBibleChapter chapter) async {
    await initialize();
    if (isDownloading(chapter)) return false;
    final file = _target(chapter);
    if (await file.exists()) await file.delete();
    _downloaded.remove(_safeId(chapter));
    notifyListeners();
    return true;
  }

  Future<void> download(AudioBibleChapter chapter) async {
    await initialize();
    final key = chapter.mediaId;
    if (_progress.containsKey(key) || isDownloaded(chapter)) return;
    _cancelled.remove(key);
    _progress[key] = null;
    notifyListeners();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    _clients[key] = client;
    final target = _target(chapter);
    final partial = File('${target.path}.part');
    IOSink? sink;
    try {
      final uri = Uri.parse(chapter.audioUrl);
      if (uri.scheme != 'https') throw const FormatException('HTTPS required');
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final type = response.headers.contentType?.mimeType;
      if (type != null &&
          type != 'audio/mpeg' &&
          type != 'audio/mp3' &&
          type != 'application/octet-stream' &&
          type != 'binary/octet-stream') {
        throw const FormatException('Server did not return an MP3');
      }
      final expected = response.contentLength;
      if (expected > 0 && expected < 1024)
        throw const FormatException('Invalid MP3 size');
      sink = partial.openWrite();
      var received = 0;
      await for (final bytes in response) {
        if (_cancelled.contains(key)) throw const _DownloadCancelled();
        sink.add(bytes);
        received += bytes.length;
        _progress[key] = expected > 0
            ? (received / expected).clamp(0.0, 1.0)
            : null;
        notifyListeners();
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (_cancelled.contains(key)) throw const _DownloadCancelled();
      if (received < 1024 || (expected > 0 && received != expected)) {
        throw const FormatException('Incomplete audio download');
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
      _downloaded.add(_safeId(chapter));
    } on _DownloadCancelled {
      // User cancelled; don't report as an error.
    } catch (_) {
      if (!_cancelled.contains(key)) rethrow;
    } finally {
      try {
        await sink?.close();
      } catch (_) {}
      if (await partial.exists()) await partial.delete();
      client.close(force: true);
      _clients.remove(key);
      _progress.remove(key);
      _cancelled.remove(key);
      notifyListeners();
    }
  }

  /// Sequential queue; already downloaded chapters are skipped.
  /// A failure stops the queue and preserves completed chapters.
  Future<void> downloadBook(AudioBibleBook book) async {
    await initialize();
    if (_bulkBookId != null) return;
    final chapters = availableAudioChaptersForBook(
      book,
    ).where((chapter) => !isDownloaded(chapter)).toList();
    if (chapters.isEmpty) return;
    _bulkBookId = book.id;
    _bulkCancelRequested = false;
    _bulkCompleted = 0;
    _bulkTotal = chapters.length;
    _bulkError = null;
    notifyListeners();
    try {
      for (final chapter in chapters) {
        if (_bulkCancelRequested) break;
        _bulkCurrent = chapter;
        notifyListeners();
        try {
          // If another control started this chapter, wait for it to finish.
          while (isDownloading(chapter) && !_bulkCancelRequested) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          if (_bulkCancelRequested) break;
          if (!isDownloaded(chapter)) await download(chapter);
          if (_bulkCancelRequested) break;
          if (!isDownloaded(chapter)) {
            throw StateError('Sura haikupakuliwa: ${chapter.title}');
          }
          _bulkCompleted++;
        } catch (error) {
          if (!_bulkCancelRequested) {
            _bulkError = '${chapter.title}: $error';
          }
          break;
        } finally {
          _bulkCurrent = null;
          notifyListeners();
        }
      }
    } finally {
      _bulkBookId = null;
      _bulkCancelRequested = false;
      _bulkCurrent = null;
      notifyListeners();
    }
  }

  void cancelBook(AudioBibleBook book) {
    if (_bulkBookId != book.id) return;
    _bulkCancelRequested = true;
    final chapter = _bulkCurrent;
    if (chapter != null && isDownloading(chapter)) cancel(chapter);
    notifyListeners();
  }

  void cancel(AudioBibleChapter chapter) {
    final key = chapter.mediaId;
    if (!_progress.containsKey(key)) return;
    _cancelled.add(key);
    _clients[key]?.close(force: true);
  }
}

class _DownloadCancelled implements Exception {
  const _DownloadCancelled();
}
