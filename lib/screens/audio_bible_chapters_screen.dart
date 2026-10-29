import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../services/audio_bible_catalog.dart';
import '../services/audio_bible_service.dart';
import '../services/audio_bible_download_service.dart';
import 'audio_bible_downloads_screen.dart';

class AudioBibleChaptersScreen extends StatefulWidget {
  const AudioBibleChaptersScreen({required this.book, super.key});

  final AudioBibleBook book;

  // Public theme constants used by the player and other screens.
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  @override
  State<AudioBibleChaptersScreen> createState() =>
      _AudioBibleChaptersScreenState();
}

class _AudioBibleChaptersScreenState extends State<AudioBibleChaptersScreen> {
  final AudioBibleDownloadService _downloads =
      AudioBibleDownloadService.instance;
  bool _offlineOnly = false;

  @override
  void initState() {
    super.initState();
    _downloads.initialize().catchError((Object error) {
      debugPrint('Offline audio initialization failed: $error');
    });
  }

  Future<void> _downloadWholeBook() async {
    if (_downloads.isBookDownloading(book)) {
      _downloads.cancelBook(book);
      return;
    }
    if (_downloads.isAnyBookDownloading) {
      _showDownloadMessage('Upakuaji wa kitabu kingine unaendelea.');
      return;
    }
    final missing = availableAudioChaptersForBook(
      book,
    ).where((chapter) => !_downloads.isDownloaded(chapter)).length;
    if (missing == 0) {
      _showDownloadMessage('Sura zote zenye sauti tayari zimepakuliwa.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pakua kitabu kizima?'),
        content: Text(
          'Sura $missing zitapakuliwa moja baada ya nyingine. '
          'Faili za sauti zinaweza kutumia data nyingi. '
          'Tunapendekeza Wi-Fi; programu haizuii matumizi ya data ya simu kiotomatiki. '
          'Unaweza kughairi wakati wowote.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ghairi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Anza kupakua'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _downloads.downloadBook(book);
    if (!mounted) return;
    if (_downloads.bulkError != null) {
      _showDownloadMessage(
        'Upakuaji umesimama. Angalia intaneti na ujaribu tena.',
      );
    } else {
      _showDownloadMessage('Upakuaji umekamilika au umeghairiwa.');
    }
  }

  void _showDownloadMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  AudioBibleBook get book => widget.book;

  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        actions: [
          IconButton(
            tooltip: 'Vipakuliwa vya kitabu hiki',
            icon: const Icon(Icons.folder_rounded, color: primaryBrown),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AudioBibleDownloadsScreen(book: book),
              ),
            ),
          ),
        ],
        title: Text(
          book.name,
          style: const TextStyle(
            color: primaryBrown,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _downloads,
                builder: (context, _) => Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_rounded,
                      color: secondaryBrown,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Zilizopakuliwa tu',
                        style: TextStyle(
                          color: primaryBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _offlineOnly,
                      activeTrackColor: gold,
                      onChanged: (value) =>
                          setState(() => _offlineOnly = value),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _downloads,
              builder: (context, _) {
                final active = _downloads.isBookDownloading(book);
                final remaining = availableAudioChaptersForBook(
                  book,
                ).where((chapter) => !_downloads.isDownloaded(chapter)).length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: (remaining == 0 && !active)
                            ? null
                            : _downloadWholeBook,
                        icon: Icon(
                          active
                              ? Icons.close_rounded
                              : Icons.download_for_offline_rounded,
                        ),
                        label: Text(
                          active
                              ? 'Ghairi upakuaji wa kitabu'
                              : 'Pakua kitabu ($remaining sura)',
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _downloads.bulkProgress,
                          color: gold,
                          backgroundColor: lightGold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zimekamilika ${_downloads.bulkCompleted} kati ya '
                          '${_downloads.bulkTotal} • '
                          '${_downloads.bulkCurrent?.title ?? "Inajiandaa"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: secondaryBrown,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<MediaItem?>(
                stream: audioBibleHandler.mediaItem,
                initialData: audioBibleHandler.mediaItem.value,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<MediaItem?> mediaSnapshot,
                    ) {
                      final MediaItem? currentItem = mediaSnapshot.data;

                      return AnimatedBuilder(
                        animation: _downloads,
                        builder: (context, _) => GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                          itemCount: _offlineOnly
                              ? availableAudioChaptersForBook(
                                  book,
                                ).where(_downloads.isDownloaded).length
                              : book.chapterCount,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, index) {
                            final int chapterNumber = _offlineOnly
                                ? availableAudioChaptersForBook(book)
                                      .where(_downloads.isDownloaded)
                                      .toList()[index]
                                      .chapterNumber
                                : index + 1;

                            final AudioBibleChapter? chapter =
                                findAudioBibleChapter(
                                  bookId: book.id,
                                  chapterNumber: chapterNumber,
                                );

                            final bool isCurrent =
                                chapter != null &&
                                currentItem?.id == chapter.mediaId;

                            return AnimatedBuilder(
                              animation: _downloads,
                              builder: (context, _) => _buildChapterCard(
                                context,
                                chapterNumber,
                                chapter,
                                isCurrent,
                              ),
                            );
                          },
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _FullAudioPlayer(),
    );
  }

  Widget _buildHeader() {
    final int availableCount = availableAudioChapterCount(book);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightGold,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.headphones_rounded, color: gold, size: 28),
                SizedBox(width: 10),
                Text(
                  'Chagua Sura',
                  style: TextStyle(
                    color: primaryBrown,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Kitabu cha ${book.name} kina ${_chapterLabel(book.chapterCount)}.',
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              availableCount > 0
                  ? 'Gusa namba ya sura unayotaka kusikiliza. '
                        '$availableCount zina sauti kwa sasa.'
                  : 'Sauti za kitabu hiki bado hazijaongezwa.',
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(
    BuildContext context,
    int chapterNumber,
    AudioBibleChapter? chapter,
    bool isCurrent,
  ) {
    final bool hasAudio = chapter != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (chapter == null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Sauti ya sura hii bado haijaongezwa.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            return;
          }

          _playChapter(context, chapter);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isCurrent
                ? lightGold
                : hasAudio
                ? cardColor
                : cardColor.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? gold.withValues(alpha: 0.65)
                  : primaryBrown.withValues(alpha: hasAudio ? 0.08 : 0.04),
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: [
              if (hasAudio)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '$chapterNumber',
                    style: TextStyle(
                      color: isCurrent
                          ? gold
                          : hasAudio
                          ? primaryBrown
                          : secondaryBrown.withValues(alpha: 0.32),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (chapter != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: _downloadControl(context, chapter)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _downloadControl(BuildContext context, AudioBibleChapter chapter) {
    final downloaded = _downloads.isDownloaded(chapter);
    final downloading = _downloads.isDownloading(chapter);
    final progress = _downloads.progress(chapter);
    if (downloaded) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 5),
        child: Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF388E3C),
          size: 19,
        ),
      );
    }
    return SizedBox(
      height: 29,
      width: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: downloading ? 'Ghairi upakuaji' : 'Pakua sura',
        onPressed: () {
          if (downloading) {
            _downloads.cancel(chapter);
          } else {
            _startDownload(context, chapter);
          }
        },
        icon: downloading
            ? Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      color: gold,
                    ),
                  ),
                  const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: primaryBrown,
                  ),
                ],
              )
            : const Icon(Icons.download_rounded, size: 22, color: gold),
      ),
    );
  }

  Future<void> _startDownload(
    BuildContext context,
    AudioBibleChapter chapter,
  ) async {
    try {
      await _downloads.download(chapter);
      if (!context.mounted) return;
      if (_downloads.isDownloaded(chapter)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chapter.title} imepakuliwa.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imeshindikana kupakua ${chapter.title}. Jaribu tena.'),
        ),
      );
      debugPrint('Audio download failed: $error');
    }
  }

  Future<void> _playChapter(
    BuildContext context,
    AudioBibleChapter chapter,
  ) async {
    try {
      await audioBibleHandler.loadChapter(chapter);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kucheza sauti: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  static String _chapterLabel(int chapterCount) {
    if (chapterCount == 1) {
      return 'sura 1';
    }

    return 'sura $chapterCount';
  }
}

class _FullAudioPlayer extends StatelessWidget {
  const _FullAudioPlayer();

  static const Color backgroundColor = AudioBibleChaptersScreen.backgroundColor;
  static const Color primaryBrown = AudioBibleChaptersScreen.primaryBrown;
  static const Color secondaryBrown = AudioBibleChaptersScreen.secondaryBrown;
  static const Color gold = AudioBibleChaptersScreen.gold;
  static const Color lightGold = AudioBibleChaptersScreen.lightGold;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioBibleHandler.mediaItem,
      initialData: audioBibleHandler.mediaItem.value,
      builder: (BuildContext context, AsyncSnapshot<MediaItem?> mediaSnapshot) {
        final MediaItem? currentItem = mediaSnapshot.data;

        if (currentItem == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlaybackState>(
          stream: audioBibleHandler.playbackState,
          initialData: audioBibleHandler.playbackState.value,
          builder: (BuildContext context, AsyncSnapshot<PlaybackState> playbackSnapshot) {
            final PlaybackState state =
                playbackSnapshot.data ?? audioBibleHandler.playbackState.value;

            final bool isPlaying = state.playing;
            final bool isBusy =
                state.processingState == AudioProcessingState.loading ||
                state.processingState == AudioProcessingState.buffering;

            final Duration duration = currentItem.duration ?? Duration.zero;

            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: primaryBrown.withValues(alpha: 0.10),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: StreamBuilder<Duration>(
                  stream: AudioService.position,
                  initialData: state.updatePosition,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Duration> positionSnapshot,
                      ) {
                        final Duration rawPosition =
                            positionSnapshot.data ?? state.updatePosition;

                        final Duration position = _clampDuration(
                          rawPosition,
                          duration,
                        );

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.headphones_rounded,
                                  color: gold,
                                  size: 22,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    currentItem.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryBrown,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: duration.inMilliseconds > 0
                                  ? position.inMilliseconds.toDouble()
                                  : 0,
                              max: duration.inMilliseconds > 0
                                  ? duration.inMilliseconds.toDouble()
                                  : 1,
                              activeColor: gold,
                              inactiveColor: gold.withValues(alpha: 0.18),
                              onChanged: duration.inMilliseconds > 0
                                  ? (double value) {
                                      audioBibleHandler.seek(
                                        Duration(milliseconds: value.round()),
                                      );
                                    }
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: secondaryBrown,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: secondaryBrown,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: 'Sura iliyopita',
                                  onPressed:
                                      audioBibleHandler.hasPreviousChapter
                                      ? audioBibleHandler.skipToPrevious
                                      : null,
                                  icon: const Icon(
                                    Icons.skip_previous_rounded,
                                    size: 29,
                                  ),
                                  color: primaryBrown,
                                  disabledColor: secondaryBrown.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Rudi sekunde 10',
                                  onPressed: audioBibleHandler.rewind,
                                  icon: const Icon(
                                    Icons.replay_10_rounded,
                                    color: primaryBrown,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: isBusy
                                        ? null
                                        : audioBibleHandler.togglePlayPause,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryBrown,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: const CircleBorder(),
                                    ),
                                    child: isBusy
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 31,
                                          ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Songa mbele sekunde 10',
                                  onPressed: audioBibleHandler.fastForward,
                                  icon: const Icon(
                                    Icons.forward_10_rounded,
                                    color: primaryBrown,
                                    size: 28,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Sura inayofuata',
                                  onPressed: audioBibleHandler.hasNextChapter
                                      ? audioBibleHandler.skipToNext
                                      : null,
                                  icon: const Icon(
                                    Icons.skip_next_rounded,
                                    size: 29,
                                  ),
                                  color: primaryBrown,
                                  disabledColor: secondaryBrown.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<double>(
                              valueListenable: audioBibleHandler.playbackSpeed,
                              builder: (context, speed, _) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Kasi ya Kusoma:',
                                    style: TextStyle(
                                      color: secondaryBrown,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 5,
                                    runSpacing: 4,
                                    children: [
                                      for (final value
                                          in AudioBibleHandler.supportedSpeeds)
                                        ChoiceChip(
                                          label: Text(
                                            '${value.toStringAsFixed(value == 1.0 || value == 2.0
                                                ? 1
                                                : value == 0.75 || value == 1.25
                                                ? 2
                                                : 1)}×',
                                          ),
                                          selected: speed == value,
                                          showCheckmark: false,
                                          selectedColor: lightGold,
                                          backgroundColor: backgroundColor,
                                          side: BorderSide(
                                            color: speed == value
                                                ? gold.withValues(alpha: 0.55)
                                                : primaryBrown.withValues(
                                                    alpha: 0.10,
                                                  ),
                                          ),
                                          labelStyle: TextStyle(
                                            color: speed == value
                                                ? primaryBrown
                                                : secondaryBrown,
                                            fontSize: 11,
                                            fontWeight: speed == value
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                          onSelected: (_) async {
                                            try {
                                              await audioBibleHandler.setSpeed(
                                                value,
                                              );
                                            } catch (error) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Imeshindikana kubadilisha kasi ya sauti.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            ValueListenableBuilder<AudioBiblePlaybackMode>(
                              valueListenable: audioBibleHandler.playbackMode,
                              builder:
                                  (
                                    BuildContext context,
                                    AudioBiblePlaybackMode mode,
                                    Widget? child,
                                  ) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Baada ya sura:',
                                          style: TextStyle(
                                            color: secondaryBrown,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _modeChip(
                                              label: 'Simama',
                                              icon: Icons.stop_circle_outlined,
                                              mode: AudioBiblePlaybackMode
                                                  .stopAfterChapter,
                                              selectedMode: mode,
                                            ),
                                            _modeChip(
                                              label: 'Endelea',
                                              icon: Icons.playlist_play_rounded,
                                              mode: AudioBiblePlaybackMode
                                                  .autoNext,
                                              selectedMode: mode,
                                            ),
                                            _modeChip(
                                              label: 'Rudia',
                                              icon: Icons.repeat_one_rounded,
                                              mode: AudioBiblePlaybackMode
                                                  .repeatChapter,
                                              selectedMode: mode,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                            ),
                          ],
                        );
                      },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required AudioBiblePlaybackMode mode,
    required AudioBiblePlaybackMode selectedMode,
  }) {
    final bool selected = mode == selectedMode;

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      selectedColor: lightGold,
      backgroundColor: backgroundColor,
      side: BorderSide(
        color: selected
            ? gold.withValues(alpha: 0.55)
            : primaryBrown.withValues(alpha: 0.10),
      ),
      avatar: Icon(icon, size: 16, color: selected ? gold : secondaryBrown),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? primaryBrown : secondaryBrown,
        fontSize: 11,
        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
      ),
      onSelected: (_) {
        audioBibleHandler.setPlaybackMode(mode);
      },
    );
  }

  Duration _clampDuration(Duration position, Duration duration) {
    if (position.isNegative) {
      return Duration.zero;
    }

    if (duration > Duration.zero && position > duration) {
      return duration;
    }

    return position;
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
