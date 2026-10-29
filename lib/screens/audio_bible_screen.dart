import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../services/audio_bible_catalog.dart';
import '../services/audio_bible_service.dart';
import 'audio_bible_chapters_screen.dart';

class AudioBibleScreen extends StatefulWidget {
  const AudioBibleScreen({super.key});

  @override
  State<AudioBibleScreen> createState() => _AudioBibleScreenState();
}

class _AudioBibleScreenState extends State<AudioBibleScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  final TextEditingController _searchController = TextEditingController();

  late Future<AudioBibleSavedProgress?> _savedProgress;
  late Future<List<AudioBibleHistoryEntry>> _listeningHistory;

  @override
  void initState() {
    super.initState();
    _savedProgress = audioBibleHandler.getSavedProgress();
    _listeningHistory = audioBibleHandler.getListeningHistory();
  }

  void _refreshSavedProgress() {
    if (!mounted) return;
    setState(() {
      _savedProgress = audioBibleHandler.getSavedProgress();
      _listeningHistory = audioBibleHandler.getListeningHistory();
    });
  }

  String _searchText = '';
  bool _showOldTestament = true;

  List<AudioBibleBook> get _oldTestamentBooks {
    return booksForTestament(AudioBibleTestament.oldTestament);
  }

  List<AudioBibleBook> get _newTestamentBooks {
    return booksForTestament(AudioBibleTestament.newTestament);
  }

  List<AudioBibleBook> get _allBooks {
    return <AudioBibleBook>[..._oldTestamentBooks, ..._newTestamentBooks];
  }

  List<AudioBibleBook> get _filteredBooks {
    final List<AudioBibleBook> selectedBooks = _showOldTestament
        ? _oldTestamentBooks
        : _newTestamentBooks;

    final String query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return selectedBooks;
    }

    return _allBooks.where((AudioBibleBook book) {
      return book.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBook(AudioBibleBook book) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AudioBibleChaptersScreen(book: book),
      ),
    );
    _refreshSavedProgress();
  }

  void _submitSearch(String value) {
    final String query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    for (final AudioBibleBook book in _allBooks) {
      if (book.name.toLowerCase() == query) {
        _openBook(book);
        return;
      }
    }
  }

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
        title: const Text(
          'Sikiliza Biblia',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildContinueListeningCard(),
            _buildListeningHistoryButton(),
            _buildTestamentSelector(),
            const SizedBox(height: 14),
            Expanded(
              child: _filteredBooks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                      itemCount: _filteredBooks.length,
                      separatorBuilder: (_, __) {
                        return const SizedBox(height: 10);
                      },
                      itemBuilder: (context, index) {
                        return _buildBookCard(_filteredBooks[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AudioBibleMiniPlayer(),
    );
  }

  Widget _buildContinueListeningCard() {
    return FutureBuilder<AudioBibleSavedProgress?>(
      future: _savedProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        if (progress == null) return const SizedBox.shrink();

        final durationMs = progress.duration.inMilliseconds;
        final positionMs = progress.position.inMilliseconds;
        final fraction = durationMs > 0
            ? (positionMs / durationMs).clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                final chapter = progress.chapter;
                final book = findAudioBibleBookById(chapter.bookId);
                if (book == null) return;
                try {
                  await audioBibleHandler.loadChapter(chapter);
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Imeshindikana kufungua sauti. Jaribu tena.',
                      ),
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                _openBook(book);
              },
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: gold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.headphones_rounded, color: gold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Endelea Kusikiliza',
                          style: TextStyle(
                            color: primaryBrown,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: primaryBrown,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      progress.chapter.title,
                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: gold.withValues(alpha: 0.20),
                        valueColor: const AlwaysStoppedAnimation<Color>(gold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSavedTime(progress.position),
                          style: const TextStyle(
                            color: secondaryBrown,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          durationMs > 0
                              ? _formatSavedTime(progress.duration)
                              : '--:--',
                          style: const TextStyle(
                            color: secondaryBrown,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListeningHistoryButton() {
    return FutureBuilder<List<AudioBibleHistoryEntry>>(
      future: _listeningHistory,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <AudioBibleHistoryEntry>[];
        if (entries.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: OutlinedButton.icon(
            onPressed: () => _showListeningHistory(entries),
            icon: const Icon(Icons.history_rounded),
            label: Text('Historia ya Usikilizaji (${entries.length})'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBrown,
              side: BorderSide(color: gold.withValues(alpha: 0.45)),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showListeningHistory(
    List<AudioBibleHistoryEntry> initialEntries,
  ) async {
    final entries = List<AudioBibleHistoryEntry>.from(initialEntries);
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.68,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historia ya Usikilizaji',
                          style: TextStyle(
                            color: primaryBrown,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (entries.isNotEmpty)
                        TextButton.icon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Futa historia yote?'),
                                      content: const Text(
                                        'Sura zote zitaondolewa kwenye historia. '
                                        'Sauti na sehemu uliyofikia kusikiliza havitafutwa.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('Ghairi'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: const Text('Futa zote'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true ||
                                      !sheetContext.mounted)
                                    return;
                                  updateSheet(() => busy = true);
                                  try {
                                    await audioBibleHandler
                                        .clearListeningHistory();
                                    if (!sheetContext.mounted) return;
                                    updateSheet(() {
                                      entries.clear();
                                      busy = false;
                                    });
                                    _refreshSavedProgress();
                                  } catch (_) {
                                    if (!sheetContext.mounted) return;
                                    updateSheet(() => busy = false);
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Imeshindikana kufuta historia.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                          ),
                          label: const Text('Futa zote'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(
                          child: Text(
                            'Hakuna historia ya usikilizaji.',
                            style: TextStyle(color: secondaryBrown),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final entry = entries[index];
                            final durationMs = entry.duration.inMilliseconds;
                            final fraction = durationMs > 0
                                ? (entry.position.inMilliseconds / durationMs)
                                      .clamp(0.0, 1.0)
                                : 0.0;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 7,
                                horizontal: 4,
                              ),
                              leading: const Icon(
                                Icons.headphones_rounded,
                                color: gold,
                              ),
                              title: Text(
                                entry.chapter.title,
                                style: const TextStyle(
                                  color: primaryBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 7),
                                  LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 4,
                                    color: gold,
                                    backgroundColor: lightGold,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatSavedTime(entry.position)} / '
                                    '${durationMs > 0 ? _formatSavedTime(entry.duration) : '--:--'}',
                                    style: const TextStyle(
                                      color: secondaryBrown,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                tooltip: 'Ondoa kwenye historia',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: secondaryBrown,
                                ),
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<bool>(
                                          context: sheetContext,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text(
                                              'Ondoa kwenye historia?',
                                            ),
                                            content: Text(
                                              'Unataka kuondoa ${entry.chapter.title} '
                                              'kwenye historia ya usikilizaji? '
                                              'Sauti na sehemu uliyofikia kusikiliza havitafutwa.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                ),
                                                child: const Text('Ghairi'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                ),
                                                child: const Text('Ondoa'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true ||
                                            !sheetContext.mounted)
                                          return;
                                        updateSheet(() => busy = true);
                                        try {
                                          await audioBibleHandler
                                              .removeListeningHistoryEntry(
                                                entry.chapter,
                                              );
                                          if (!sheetContext.mounted) return;
                                          updateSheet(() {
                                            entries.removeWhere(
                                              (e) =>
                                                  e.chapter.mediaId ==
                                                  entry.chapter.mediaId,
                                            );
                                            busy = false;
                                          });
                                          _refreshSavedProgress();
                                        } catch (_) {
                                          if (!sheetContext.mounted) return;
                                          updateSheet(() => busy = false);
                                          ScaffoldMessenger.of(
                                            sheetContext,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Imeshindikana kuondoa sura kwenye historia.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                              onTap: busy
                                  ? null
                                  : () async {
                                      final book = findAudioBibleBookById(
                                        entry.chapter.bookId,
                                      );
                                      if (book == null) return;
                                      Navigator.pop(sheetContext);
                                      try {
                                        await audioBibleHandler.loadChapter(
                                          entry.chapter,
                                        );
                                        if (!mounted) return;
                                        _openBook(book);
                                      } catch (_) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Imeshindikana kufungua sauti. Jaribu tena.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _refreshSavedProgress();
  }

  String _formatSavedTime(Duration duration) {
    final seconds = duration.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chagua kitabu cha Biblia',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chagua kitabu, kisha utaona sura zake.',
            style: TextStyle(color: secondaryBrown, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _submitSearch,
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Mfano: Mathayo',
              hintStyle: const TextStyle(color: secondaryBrown),
              prefixIcon: const Icon(Icons.search_rounded, color: gold),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: secondaryBrown,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: gold.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: gold, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: lightGold,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTestamentButton(
                title: 'Agano la Kale',
                isSelected: _showOldTestament,
                onTap: () {
                  setState(() {
                    _showOldTestament = true;
                  });
                },
              ),
            ),
            Expanded(
              child: _buildTestamentButton(
                title: 'Agano Jipya',
                isSelected: !_showOldTestament,
                onTap: () {
                  setState(() {
                    _showOldTestament = false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestamentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? primaryBrown : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : primaryBrown,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(AudioBibleBook book, int index) {
    final int availableCount = availableAudioChapterCount(book);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openBook(book);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      availableCount > 0
                          ? 'Sura ${book.chapterCount} • $availableCount zenye sauti'
                          : 'Sura ${book.chapterCount} • Sauti bado',
                      style: TextStyle(
                        color: availableCount > 0 ? gold : secondaryBrown,
                        fontSize: 13,
                        fontWeight: availableCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (availableCount > 0) ...[
                const Icon(Icons.headphones_rounded, color: gold, size: 20),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: gold,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.headphones_outlined, color: gold, size: 58),
            SizedBox(height: 14),
            Text(
              'Kitabu hakijapatikana.',
              style: TextStyle(
                color: primaryBrown,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Jaribu kuandika jina lingine.',
              style: TextStyle(color: secondaryBrown, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioBibleMiniPlayer extends StatelessWidget {
  const _AudioBibleMiniPlayer();

  static const Color backgroundColor = _AudioBibleScreenState.backgroundColor;
  static const Color primaryBrown = _AudioBibleScreenState.primaryBrown;
  static const Color secondaryBrown = _AudioBibleScreenState.secondaryBrown;
  static const Color gold = _AudioBibleScreenState.gold;
  static const Color lightGold = _AudioBibleScreenState.lightGold;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioBibleHandler.mediaItem,
      initialData: audioBibleHandler.mediaItem.value,
      builder: (BuildContext context, AsyncSnapshot<MediaItem?> mediaSnapshot) {
        final MediaItem? item = mediaSnapshot.data;

        if (item == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PlaybackState>(
          stream: audioBibleHandler.playbackState,
          initialData: audioBibleHandler.playbackState.value,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<PlaybackState> playbackSnapshot,
              ) {
                final PlaybackState state =
                    playbackSnapshot.data ??
                    audioBibleHandler.playbackState.value;

                return SafeArea(
                  top: false,
                  child: Material(
                    color: backgroundColor,
                    child: InkWell(
                      onTap: () => _openCurrentBook(context, item),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: primaryBrown.withValues(alpha: 0.10),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: lightGold,
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: gold,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Inacheza sasa',
                                    style: TextStyle(
                                      color: secondaryBrown,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: primaryBrown,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: state.playing ? 'Sitisha' : 'Endelea',
                              onPressed: audioBibleHandler.togglePlayPause,
                              icon: Icon(
                                state.playing
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: gold,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  void _openCurrentBook(BuildContext context, MediaItem item) {
    final Object? bookIdValue = item.extras?['bookId'];

    if (bookIdValue is! String) {
      return;
    }

    final AudioBibleBook? book = findAudioBibleBookById(bookIdValue);

    if (book == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AudioBibleChaptersScreen(book: book),
      ),
    );
  }
}
