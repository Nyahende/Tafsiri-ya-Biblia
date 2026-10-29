import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_bible_catalog.dart';
import 'audio_bible_download_service.dart';

late final AudioBibleHandler audioBibleHandler;

Future<void> initializeAudioBibleService() async {
  // Load the small local Audio Bible manifest before the app starts.
  // This keeps the books/chapter catalogue independent of the internet.
  await initializeAudioBibleCatalog();

  audioBibleHandler = await AudioService.init(
    builder: AudioBibleHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.nyahende.tafsiriyabiblia.audio_playback',
      androidNotificationChannelName: 'Biblia ya Sauti',
      androidNotificationChannelDescription:
          'Udhibiti wa usomaji wa Biblia kwa sauti',
      androidNotificationOngoing: false,
      androidShowNotificationBadge: false,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );

  final AudioSession session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());
}

enum AudioBiblePlaybackMode { stopAfterChapter, autoNext, repeatChapter }

/// Snapshot of the last locally saved listening position.
class AudioBibleSavedProgress {
  const AudioBibleSavedProgress({
    required this.chapter,
    required this.position,
    required this.duration,
  });

  final AudioBibleChapter chapter;
  final Duration position;
  final Duration duration;
}

/// A chapter previously opened in the audio player.
class AudioBibleHistoryEntry {
  const AudioBibleHistoryEntry({
    required this.chapter,
    required this.position,
    required this.duration,
  });

  final AudioBibleChapter chapter;
  final Duration position;
  final Duration duration;
}

class AudioBibleHandler extends BaseAudioHandler with SeekHandler {
  AudioBibleHandler() {
    playbackMode.addListener(_onPlaybackModeChanged);
    _restoreSavedSpeed();

    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            errorMessage: error.toString(),
          ),
        );
      },
    );

    _player.durationStream.listen((Duration? duration) {
      final MediaItem? currentItem = mediaItem.value;

      if (currentItem == null || duration == null) {
        return;
      }

      if (currentItem.duration != duration) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });

    _player.playerStateStream.listen((just_audio.PlayerState state) {
      if (state.processingState == just_audio.ProcessingState.completed) {
        _handleChapterCompleted();
      }
    });

    // Periodically remember the listening position.
    _player.positionStream.listen((Duration position) {
      if (!_player.playing || _restoringPosition) {
        return;
      }

      final AudioBibleChapter? chapter = currentChapter;
      if (chapter == null) {
        return;
      }

      final int seconds = position.inSeconds;

      if (seconds >= _lastSavedSecond + 5 || seconds < _lastSavedSecond) {
        _lastSavedSecond = seconds;
        _savePlaybackPosition();
      }
    });
  }

  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();

  /// Default audiobook behaviour: continue to the next chapter.
  final ValueNotifier<AudioBiblePlaybackMode> playbackMode =
      ValueNotifier<AudioBiblePlaybackMode>(AudioBiblePlaybackMode.autoNext);

  static const String _speedKey = 'audio_bible_playback_speed_v1';
  static const List<double> supportedSpeeds = <double>[
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
  ];
  final ValueNotifier<double> playbackSpeed = ValueNotifier<double>(1.0);
  Future<void>? _speedRestore;

  Future<void> _restoreSavedSpeed() {
    return _speedRestore ??= _readSavedSpeed();
  }

  Future<void> _readSavedSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getDouble(_speedKey) ?? 1.0;
      final speed = supportedSpeeds.contains(stored) ? stored : 1.0;
      await _player.setSpeed(speed);
      playbackSpeed.value = speed;
      _broadcastState(_player.playbackEvent);
    } catch (error) {
      debugPrint('Audio Bible speed restore failed: $error');
    }
  }

  bool _handlingCompletion = false;

  // STEP 1A: Local playback persistence.
  static const String _savedBookKey = 'audio_bible_last_book_id';
  static const String _savedChapterKey = 'audio_bible_last_chapter_number';
  static const String _savedPositionKey = 'audio_bible_last_position_ms';
  static const String _savedDurationKey = 'audio_bible_last_duration_ms';
  static const String _historyKey = 'audio_bible_listening_history_v1';
  static const int _historyLimit = 10;

  // Prevent active playback from immediately recreating deleted history.
  final Set<String> _historyExcludedUntilReload = <String>{};

  String _historyId(String bookId, int chapterNumber) =>
      '$bookId::$chapterNumber';

  /// Remove only this chapter's history entry; leave playback and
  /// Step 1A's last-listened position untouched.
  Future<void> removeListeningHistoryEntry(AudioBibleChapter chapter) {
    final id = _historyId(chapter.bookId, chapter.chapterNumber);
    _historyExcludedUntilReload.add(id);
    _pendingSave = _pendingSave
        .catchError((Object error) {
          debugPrint('Audio Bible previous save error: $error');
        })
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          final records = _readHistoryRecords(prefs);
          records.removeWhere(
            (record) =>
                record['bookId'] == chapter.bookId &&
                record['chapterNumber'] == chapter.chapterNumber,
          );
          final saved = await prefs.setString(_historyKey, jsonEncode(records));
          if (!saved) throw StateError('Could not save listening history');
        });
    return _pendingSave;
  }

  /// Clear history only, without stopping audio or resetting Continue Listening.
  Future<void> clearListeningHistory() {
    final chapter = currentChapter;
    if (chapter != null) {
      _historyExcludedUntilReload.add(
        _historyId(chapter.bookId, chapter.chapterNumber),
      );
    }
    _pendingSave = _pendingSave
        .catchError((Object error) {
          debugPrint('Audio Bible previous save error: $error');
        })
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          final saved = await prefs.remove(_historyKey);
          if (!saved) throw StateError('Could not clear listening history');
        });
    return _pendingSave;
  }

  int _lastSavedSecond = -5;
  bool _restoringPosition = false;

  // Serialize preference writes so an older position cannot
  // overwrite a newer one when writes overlap.
  Future<void> _pendingSave = Future<void>.value();

  /// Read Step 1A's existing preferences without changing playback.
  Future<AudioBibleSavedProgress?> getSavedProgress() async {
    await _pendingSave;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? bookId = prefs.getString(_savedBookKey);
      final int? number = prefs.getInt(_savedChapterKey);
      if (bookId == null || number == null) return null;

      final AudioBibleChapter? chapter = findAudioBibleChapter(
        bookId: bookId,
        chapterNumber: number,
      );
      if (chapter == null) return null;

      final int positionMs = prefs.getInt(_savedPositionKey) ?? 0;
      final int durationMs = prefs.getInt(_savedDurationKey) ?? 0;
      if (positionMs <= 0) return null;
      if (durationMs > 0 && durationMs - positionMs <= 3000) {
        return null;
      }

      return AudioBibleSavedProgress(
        chapter: chapter,
        position: Duration(milliseconds: positionMs),
        duration: Duration(milliseconds: durationMs > 0 ? durationMs : 0),
      );
    } catch (error) {
      debugPrint('Audio Bible saved progress read failed: $error');
      return null;
    }
  }

  /// Newest first; invalid or unavailable chapters are ignored.
  Future<List<AudioBibleHistoryEntry>> getListeningHistory() async {
    await _pendingSave;
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = _readHistoryRecords(prefs);
      final entries = <AudioBibleHistoryEntry>[];
      for (final record in records) {
        final bookId = record['bookId'];
        final number = record['chapterNumber'];
        if (bookId is! String || number is! int) continue;
        final chapter = findAudioBibleChapter(
          bookId: bookId,
          chapterNumber: number,
        );
        if (chapter == null) continue;
        final position = record['positionMs'];
        final duration = record['durationMs'];
        entries.add(
          AudioBibleHistoryEntry(
            chapter: chapter,
            position: Duration(
              milliseconds: position is int && position > 0 ? position : 0,
            ),
            duration: Duration(
              milliseconds: duration is int && duration > 0 ? duration : 0,
            ),
          ),
        );
      }
      return entries;
    } catch (error) {
      debugPrint('Audio Bible history read failed: $error');
      return <AudioBibleHistoryEntry>[];
    }
  }

  List<Map<String, dynamic>> _readHistoryRecords(SharedPreferences prefs) {
    final raw = prefs.getString(_historyKey);
    if (raw == null) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .take(_historyLimit)
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  AudioBibleChapter? get currentChapter {
    final MediaItem? currentItem = mediaItem.value;

    if (currentItem == null) {
      return null;
    }

    return findAudioBibleChapterByMediaId(currentItem.id);
  }

  bool get hasPreviousChapter {
    final AudioBibleChapter? chapter = currentChapter;

    return chapter != null && previousAudioBibleChapter(chapter) != null;
  }

  bool get hasNextChapter {
    final AudioBibleChapter? chapter = currentChapter;

    return chapter != null && nextAudioBibleChapter(chapter) != null;
  }

  Future<void> _savePlaybackPosition({
    Duration? position,
    AudioBibleChapter? chapter,
  }) {
    final AudioBibleChapter? targetChapter = chapter ?? currentChapter;

    if (targetChapter == null) {
      return _pendingSave;
    }

    final int positionMs = (position ?? _player.position).inMilliseconds;

    final int durationMs = _player.duration?.inMilliseconds ?? 0;

    final String bookId = targetChapter.bookId;
    final int chapterNumber = targetChapter.chapterNumber;

    _pendingSave = _pendingSave
        .catchError((Object error) {
          debugPrint('Audio Bible previous save error: $error');
        })
        .then((_) async {
          try {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();

            await prefs.setString(_savedBookKey, bookId);
            await prefs.setInt(_savedChapterKey, chapterNumber);
            await prefs.setInt(_savedPositionKey, positionMs);
            await prefs.setInt(_savedDurationKey, durationMs);
            // Keep Step 1A intact even when history has been deleted.
            if (_historyExcludedUntilReload.contains(
              _historyId(bookId, chapterNumber),
            ))
              return;
            // Update history in the same serialized write as Step 1A.
            final history = _readHistoryRecords(prefs);
            history.removeWhere(
              (entry) =>
                  entry['bookId'] == bookId &&
                  entry['chapterNumber'] == chapterNumber,
            );
            history.insert(0, <String, dynamic>{
              'bookId': bookId,
              'chapterNumber': chapterNumber,
              'positionMs': positionMs < 0 ? 0 : positionMs,
              'durationMs': durationMs,
            });
            await prefs.setString(
              _historyKey,
              jsonEncode(history.take(_historyLimit).toList()),
            );
          } catch (error) {
            debugPrint('Audio Bible position save failed: $error');
          }
        });

    return _pendingSave;
  }

  Future<void> _restorePlaybackPosition(AudioBibleChapter chapter) async {
    _restoringPosition = true;

    try {
      // Wait for pending saves before reading stored progress.
      await _pendingSave;

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final String? savedBookId = prefs.getString(_savedBookKey);

      final int? savedChapterNumber = prefs.getInt(_savedChapterKey);

      int savedPositionMs;
      if (savedBookId == chapter.bookId &&
          savedChapterNumber == chapter.chapterNumber) {
        savedPositionMs = prefs.getInt(_savedPositionKey) ?? 0;
      } else {
        final matches = _readHistoryRecords(prefs).where(
          (entry) =>
              entry['bookId'] == chapter.bookId &&
              entry['chapterNumber'] == chapter.chapterNumber,
        );
        if (matches.isEmpty) return;
        final stored = matches.first['positionMs'];
        savedPositionMs = stored is int ? stored : 0;
      }

      if (savedPositionMs <= 0) {
        return;
      }

      final Duration? duration = _player.duration;

      if (duration != null) {
        final int remainingMs = duration.inMilliseconds - savedPositionMs;

        // A finished or nearly finished chapter starts
        // from the beginning instead of its final seconds.
        if (remainingMs <= 3000) {
          await _player.seek(Duration.zero);
          _lastSavedSecond = -5;
          return;
        }
      }

      await _player.seek(Duration(milliseconds: savedPositionMs));

      _lastSavedSecond = savedPositionMs ~/ 1000;
    } catch (error) {
      debugPrint('Audio Bible position restore failed: $error');
    } finally {
      _restoringPosition = false;
    }
  }

  Future<void> loadChapter(
    AudioBibleChapter chapter, {
    bool autoplay = true,
  }) async {
    await _restoreSavedSpeed();
    // Explicitly opening a chapter allows it back into listening history.
    _historyExcludedUntilReload.remove(
      _historyId(chapter.bookId, chapter.chapterNumber),
    );
    final MediaItem requestedItem = _mediaItemForChapter(chapter);

    final MediaItem? currentItem = mediaItem.value;

    final bool isSameChapter = currentItem?.id == requestedItem.id;

    if (!isSameChapter) {
      // Preserve the old chapter's position before switching.
      if (currentChapter != null) {
        await _savePlaybackPosition();
      }

      await _player.stop();

      final AudioBibleBook? book = findAudioBibleBookById(chapter.bookId);

      if (book != null) {
        queue.add(
          availableAudioChaptersForBook(
            book,
          ).map(_mediaItemForChapter).toList(growable: false),
        );
      }

      mediaItem.add(requestedItem);

      _lastSavedSecond = -5;
      _restoringPosition = true;

      try {
        // Step 2B: Prefer a completed download, including when auto-advancing
        // or skipping chapters. Otherwise retain the original R2 streaming path.
        final localFile = await AudioBibleDownloadService.instance.localFile(
          chapter,
        );
        Duration? duration;
        if (localFile != null) {
          try {
            duration = await _player.setFilePath(localFile.path);
            debugPrint('Audio Bible: playing downloaded ${chapter.mediaId}');
          } catch (error) {
            // A file may become unreadable or be removed by the OS. When
            // online, fall back to the existing stream rather than failing.
            debugPrint('Audio Bible local file failed; trying R2: $error');
            duration = await _player.setUrl(chapter.audioUrl);
          }
        } else {
          duration = await _player.setUrl(chapter.audioUrl);
        }

        mediaItem.add(requestedItem.copyWith(duration: duration));

        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.ready,
            playing: false,
            updatePosition: Duration.zero,
            bufferedPosition: Duration.zero,
            speed: _player.speed,
          ),
        );
      } finally {
        _restoringPosition = false;
      }

      // Restore a previously listened chapter (including history entries).
      await _restorePlaybackPosition(chapter);
      await _savePlaybackPosition();
    } else if (_player.processingState ==
        just_audio.ProcessingState.completed) {
      await _player.seek(Duration.zero);
      _lastSavedSecond = -5;
    }

    if (autoplay) {
      await play();
    }
  }

  bool isChapterLoaded(AudioBibleChapter chapter) {
    return mediaItem.value?.id == chapter.mediaId;
  }

  void setPlaybackMode(AudioBiblePlaybackMode mode) {
    if (playbackMode.value == mode) {
      return;
    }

    playbackMode.value = mode;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() async {
    await _player.pause();
    await _savePlaybackPosition();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);

    _lastSavedSecond = position.inSeconds;

    await _savePlaybackPosition();
  }

  @override
  Future<void> setSpeed(double speed) async {
    if (!supportedSpeeds.contains(speed)) {
      throw ArgumentError.value(speed, 'speed', 'Unsupported playback speed');
    }
    await _restoreSavedSpeed();
    await _player.setSpeed(speed);
    playbackSpeed.value = speed;
    _broadcastState(_player.playbackEvent);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_speedKey, speed);
    } catch (error) {
      debugPrint('Audio Bible speed save failed: $error');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final AudioBibleChapter? chapter = currentChapter;

    if (chapter == null) {
      return;
    }

    final AudioBibleChapter? previous = previousAudioBibleChapter(chapter);

    if (previous == null) {
      return;
    }

    await loadChapter(previous);
  }

  @override
  Future<void> skipToNext() async {
    final AudioBibleChapter? chapter = currentChapter;

    if (chapter == null) {
      return;
    }

    final AudioBibleChapter? next = nextAudioBibleChapter(chapter);

    if (next == null) {
      return;
    }

    await loadChapter(next);
  }

  @override
  Future<void> stop() async {
    // Save before stopping, because stopping may reset
    // the player's current position.
    await _savePlaybackPosition();

    await _player.stop();

    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: _player.position,
      ),
    );

    await super.stop();
  }

  Future<void> togglePlayPause() async {
    if (_player.processingState == just_audio.ProcessingState.completed) {
      await _player.seek(Duration.zero);
      _lastSavedSecond = -5;
      await play();
      return;
    }

    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> _handleChapterCompleted() async {
    if (_handlingCompletion) {
      return;
    }

    _handlingCompletion = true;

    try {
      final AudioBibleChapter? chapter = currentChapter;

      if (chapter == null) {
        await pause();
        return;
      }

      // A completed chapter should not reopen at its end.
      await _savePlaybackPosition(chapter: chapter, position: Duration.zero);

      switch (playbackMode.value) {
        case AudioBiblePlaybackMode.repeatChapter:
          await _player.seek(Duration.zero);
          _lastSavedSecond = -5;
          await _player.play();
          break;

        case AudioBiblePlaybackMode.autoNext:
          final AudioBibleChapter? next = nextAudioBibleChapter(chapter);

          if (next != null) {
            await loadChapter(next);
          } else {
            await pause();
          }
          break;

        case AudioBiblePlaybackMode.stopAfterChapter:
          await pause();
          break;
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  MediaItem _mediaItemForChapter(AudioBibleChapter chapter) {
    return MediaItem(
      id: chapter.mediaId,
      album: 'Biblia ya Sauti',
      title: chapter.title,
      artist: 'Jifunze Biblia',
      extras: <String, dynamic>{
        'bookId': chapter.bookId,
        'bookName': chapter.bookName,
        'chapterNumber': chapter.chapterNumber,
        'audioUrl': chapter.audioUrl,
        'remotePath': chapter.remotePath,
      },
    );
  }

  void _onPlaybackModeChanged() {
    playbackState.add(
      playbackState.value.copyWith(
        repeatMode: playbackMode.value == AudioBiblePlaybackMode.repeatChapter
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none,
      ),
    );
  }

  void _broadcastState(just_audio.PlaybackEvent event) {
    final bool playing = _player.playing;

    playbackState.add(
      PlaybackState(
        controls: <MediaControl>[
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const <int>[1, 2, 3],
        processingState: _transformProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        repeatMode: playbackMode.value == AudioBiblePlaybackMode.repeatChapter
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none,
      ),
    );
  }

  AudioProcessingState _transformProcessingState(
    just_audio.ProcessingState state,
  ) {
    switch (state) {
      case just_audio.ProcessingState.idle:
        return AudioProcessingState.idle;
      case just_audio.ProcessingState.loading:
        return AudioProcessingState.loading;
      case just_audio.ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case just_audio.ProcessingState.ready:
        return AudioProcessingState.ready;
      case just_audio.ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
