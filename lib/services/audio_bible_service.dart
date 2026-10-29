import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

import 'audio_bible_catalog.dart';

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

class AudioBibleHandler extends BaseAudioHandler with SeekHandler {
  AudioBibleHandler() {
    playbackMode.addListener(_onPlaybackModeChanged);

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
  }

  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();

  /// Default audiobook behaviour: continue to the next chapter.
  final ValueNotifier<AudioBiblePlaybackMode> playbackMode =
      ValueNotifier<AudioBiblePlaybackMode>(AudioBiblePlaybackMode.autoNext);

  bool _handlingCompletion = false;

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

  Future<void> loadChapter(
    AudioBibleChapter chapter, {
    bool autoplay = true,
  }) async {
    final MediaItem requestedItem = _mediaItemForChapter(chapter);

    final MediaItem? currentItem = mediaItem.value;

    final bool isSameChapter = currentItem?.id == requestedItem.id;

    if (!isSameChapter) {
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

      // Stream directly from Cloudflare R2.
      final Duration? duration = await _player.setUrl(chapter.audioUrl);

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
    } else if (_player.processingState ==
        just_audio.ProcessingState.completed) {
      await _player.seek(Duration.zero);
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
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

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

      switch (playbackMode.value) {
        case AudioBiblePlaybackMode.repeatChapter:
          await _player.seek(Duration.zero);
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
