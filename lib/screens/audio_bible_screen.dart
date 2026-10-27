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

  void _openBook(AudioBibleBook book) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AudioBibleChaptersScreen(book: book),
      ),
    );
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
