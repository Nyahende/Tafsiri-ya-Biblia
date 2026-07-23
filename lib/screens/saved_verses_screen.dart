import 'package:flutter/material.dart';

import '../../services/bookmark_service.dart';
import 'verse_reading_screen.dart';

class SavedVersesScreen extends StatefulWidget {
  const SavedVersesScreen({super.key});

  @override
  State<SavedVersesScreen> createState() => _SavedVersesScreenState();
}

class _SavedVersesScreenState extends State<SavedVersesScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  List<BibleBookmark> _bookmarks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookmarks = await BookmarkService.getBookmarks();

      if (!mounted) {
        return;
      }

      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Imeshindikana kupakia mistari iliyohifadhiwa.';
      });
    }
  }

  Future<void> _openBookmark(BibleBookmark bookmark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: bookmark.bookName,
          chapterNumber: bookmark.chapterNumber,
          chapterCount: bookmark.chapterCount,
          initialVerseNumber: bookmark.verseNumber,
        ),
      ),
    );

    await _loadBookmarks();
  }

  Future<void> _removeBookmark(BibleBookmark bookmark) async {
    await BookmarkService.removeBookmark(
      bookName: bookmark.bookName,
      chapterNumber: bookmark.chapterNumber,
      verseNumber: bookmark.verseNumber,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _bookmarks.removeWhere((item) => item.id == bookmark.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mstari umeondolewa kwenye zilizohifadhiwa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    if (_bookmarks.isEmpty) {
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: const Text(
            'Ondoa Mistari Yote?',
            style: TextStyle(color: primaryBrown),
          ),
          content: const Text(
            'Kitendo hiki kitaondoa mistari yote '
            'uliyohifadhi.',
            style: TextStyle(color: secondaryBrown),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Ghairi'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(backgroundColor: primaryBrown),
              child: const Text('Ondoa Yote'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    await BookmarkService.clearBookmarks();

    if (!mounted) {
      return;
    }

    setState(() {
      _bookmarks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mistari Iliyohifadhiwa',
          style: TextStyle(color: primaryBrown, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: primaryBrown),
        actions: [
          if (_bookmarks.isNotEmpty)
            IconButton(
              tooltip: 'Ondoa yote',
              onPressed: _confirmClearAll,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: gold,
        onRefresh: _loadBookmarks,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: gold));
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(
            Icons.error_outline_rounded,
            size: 62,
            color: gold.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: secondaryBrown, fontSize: 16),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              onPressed: _loadBookmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Jaribu Tena'),
              style: FilledButton.styleFrom(backgroundColor: primaryBrown),
            ),
          ),
        ],
      );
    }

    if (_bookmarks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 110),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: lightGold, shape: BoxShape.circle),
            child: const Icon(
              Icons.bookmark_border_rounded,
              color: gold,
              size: 42,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Hakuna Mistari Iliyohifadhiwa',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryBrown,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gusa mstari unapokuwa unasoma, kisha '
            'bonyeza “Hifadhi”.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryBrown, fontSize: 15, height: 1.5),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      itemCount: _bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];

        return Dismissible(
          key: ValueKey(bookmark.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          onDismissed: (_) {
            _removeBookmark(bookmark);
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openBookmark(bookmark);
              },
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: lightGold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bookmark_rounded, color: gold),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookmark.reference,
                            style: const TextStyle(
                              color: primaryBrown,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bookmark.verseText,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: secondaryBrown,
                              fontSize: 15,
                              height: 1.5,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ondoa',
                      onPressed: () {
                        _removeBookmark(bookmark);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: secondaryBrown,
                        size: 20,
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
  }
}
