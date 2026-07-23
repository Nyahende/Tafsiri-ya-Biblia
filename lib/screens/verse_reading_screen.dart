import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/bible_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/reading_progress_service.dart';
import 'saved_verses_screen.dart';
import 'package:share_plus/share_plus.dart';

class VerseReadingScreen extends StatefulWidget {
  const VerseReadingScreen({
    super.key,
    required this.bookName,
    required this.chapterNumber,
    required this.chapterCount,
    this.initialVerseNumber,
  });

  final String bookName;
  final int chapterNumber;
  final int chapterCount;
  final int? initialVerseNumber;

  @override
  State<VerseReadingScreen> createState() => _VerseReadingScreenState();
}

class _VerseReadingScreenState extends State<VerseReadingScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color selectedVerseColor = Color(0xFFFFF1C7);

  List<BibleVerse> _verses = [];

  int? _selectedVerseNumber;

  bool _isLoading = true;
  bool _isBookmarked = false;
  bool _isPlayingAudio = false;

  String? _errorMessage;

  double _fontSize = 18;

  @override
  void initState() {
    super.initState();

    _initializeChapter();
  }

  Future<void> _initializeChapter() async {
    await _saveReadingProgress();

    if (!mounted) {
      return;
    }

    await _loadVerses();

    if (!mounted) {
      return;
    }

    if (widget.initialVerseNumber != null) {
      final exists = _verses.any(
        (verse) => verse.number == widget.initialVerseNumber,
      );

      if (exists) {
        setState(() {
          _selectedVerseNumber = widget.initialVerseNumber;
        });

        await _refreshSelectedBookmarkState();
      }
    }
  }

  Future<void> _saveReadingProgress() async {
    try {
      await ReadingProgressService.saveProgress(
        bookName: widget.bookName,
        chapterNumber: widget.chapterNumber,
        chapterCount: widget.chapterCount,
      );
    } catch (_) {
      /*
     * Failure to save progress should not prevent
     * the user from reading the Bible.
     */
    }
  }

  BibleVerse? get _selectedVerse {
    if (_selectedVerseNumber == null) {
      return null;
    }

    try {
      return _verses.firstWhere(
        (verse) => verse.number == _selectedVerseNumber,
      );
    } catch (_) {
      return null;
    }
  }

  String get _chapterReference {
    return '${widget.bookName} ${widget.chapterNumber}';
  }

  bool get _hasPreviousChapter {
    return widget.chapterNumber > 1;
  }

  bool get _hasNextChapter {
    return widget.chapterNumber < widget.chapterCount;
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedVerseNumber = null;
      _isBookmarked = false;
    });

    try {
      final verses = await BibleService.getVerses(
        bookName: widget.bookName,
        chapterNumber: widget.chapterNumber,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } on BibleDataException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _verses = [];
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _verses = [];
        _isLoading = false;
        _errorMessage = 'Imeshindikana kupakia sura hii.';
      });
    }
  }

  Future<void> _refreshSelectedBookmarkState() async {
    final verse = _selectedVerse;

    if (verse == null) {
      if (mounted) {
        setState(() {
          _isBookmarked = false;
        });
      }
      return;
    }

    final bookmarked = await BookmarkService.isBookmarked(
      bookName: widget.bookName,
      chapterNumber: widget.chapterNumber,
      verseNumber: verse.number,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isBookmarked = bookmarked;
    });
  }

  Future<void> _selectVerse(BibleVerse verse) async {
    if (_selectedVerseNumber == verse.number) {
      setState(() {
        _selectedVerseNumber = null;
        _isBookmarked = false;
      });
      return;
    }

    setState(() {
      _selectedVerseNumber = verse.number;
      _isBookmarked = false;
    });

    await _refreshSelectedBookmarkState();
  }

  Future<void> _copySelectedVerse() async {
    final verse = _selectedVerse;

    if (verse == null) {
      return;
    }

    final text =
        '${verse.text}\n\n'
        '${widget.bookName} '
        '${widget.chapterNumber}:${verse.number}';

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mstari umenakiliwa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleBookmark() async {
    final verse = _selectedVerse;

    if (verse == null) {
      return;
    }

    final bookmark = BibleBookmark(
      bookName: widget.bookName,
      chapterNumber: widget.chapterNumber,
      chapterCount: widget.chapterCount,
      verseNumber: verse.number,
      verseText: verse.text,
      savedAt: DateTime.now(),
    );

    try {
      if (_isBookmarked) {
        await BookmarkService.removeBookmark(
          bookName: widget.bookName,
          chapterNumber: widget.chapterNumber,
          verseNumber: verse.number,
        );
      } else {
        await BookmarkService.addBookmark(bookmark);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Mstari umehifadhiwa.'
                : 'Mstari umeondolewa kwenye zilizohifadhiwa.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindikana kubadilisha hali ya mstari.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareSelectedVerse() async {
    final verse = _selectedVerse;

    if (verse == null) {
      return;
    }

    final text =
        '''
"${verse.text}"

— ${widget.bookName} ${widget.chapterNumber}:${verse.number}

Tafsiri ya Biblia
Soma → Tafakari → Ishi
''';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  void _openTranslationNotes() {
    final verse = _selectedVerse;

    if (verse == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _buildTranslationNotesSheet(verse);
      },
    );
  }

  void _toggleAudio() {
    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPlayingAudio
              ? 'Usomaji wa sauti umeanza.'
              : 'Usomaji wa sauti umesimamishwa.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTextSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ukubwa wa Maandishi',
                    style: TextStyle(
                      color: primaryBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Text(
                        'A',
                        style: TextStyle(color: secondaryBrown, fontSize: 14),
                      ),

                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 15,
                          max: 28,
                          divisions: 13,
                          activeColor: gold,
                          onChanged: (value) {
                            setModalState(() {
                              _fontSize = value;
                            });

                            setState(() {
                              _fontSize = value;
                            });
                          },
                        ),
                      ),

                      const Text(
                        'A',
                        style: TextStyle(
                          color: primaryBrown,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Hofu ya BWANA ni mwanzo wa maarifa.',
                    style: TextStyle(
                      color: primaryBrown,
                      fontSize: _fontSize,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _goToPreviousChapter() {
    if (widget.chapterNumber <= 1) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: widget.bookName,
          chapterNumber: widget.chapterNumber - 1,
          chapterCount: widget.chapterCount,
        ),
      ),
    );
  }

  void _goToNextChapter() {
    if (widget.chapterNumber >= widget.chapterCount) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: widget.bookName,
          chapterNumber: widget.chapterNumber + 1,
          chapterCount: widget.chapterCount,
        ),
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookName,
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sura ya ${widget.chapterNumber}',
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sikiliza',
            onPressed: _toggleAudio,
            icon: Icon(
              _isPlayingAudio
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: gold,
            ),
          ),
          IconButton(
            tooltip: 'Ukubwa wa maandishi',
            onPressed: _showTextSettings,
            icon: const Icon(Icons.text_fields_rounded, color: primaryBrown),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: primaryBrown),
            color: backgroundColor,
            onSelected: (value) {
              if (value == 'search') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utafutaji wa Biblia utaongezwa.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              if (value == 'bookmarks') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedVersesScreen()),
                ).then((_) {
                  _refreshSelectedBookmarkState();
                });
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: primaryBrown),
                      SizedBox(width: 12),
                      Text('Tafuta'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'bookmarks',
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_outline_rounded, color: primaryBrown),
                      SizedBox(width: 12),
                      Text('Mistari Iliyohifadhiwa'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildChapterHeader(),

            Expanded(child: _buildVerseContent()),
          ],
        ),
      ),
      bottomNavigationBar: _selectedVerse != null
          ? _buildVerseActions()
          : _buildChapterNavigation(),
    );
  }

  Widget _buildChapterHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: gold),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _chapterReference,
                  style: const TextStyle(
                    color: primaryBrown,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Gusa mstari ili kuona chaguo zaidi.',
                  style: TextStyle(color: secondaryBrown, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: gold));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_verses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Hakuna mistari katika sura hii.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryBrown, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        return _buildVerse(_verses[index]);
      },
    );
  }

  Widget _buildVerse(BibleVerse verse) {
    final bool isSelected = _selectedVerseNumber == verse.number;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _selectVerse(verse);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? selectedVerseColor : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: gold.withValues(alpha: 0.35))
                  : null,
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: primaryBrown,
                  fontSize: _fontSize,
                  height: 1.65,
                  fontFamily: 'serif',
                ),
                children: [
                  TextSpan(
                    text: '${verse.number}  ',
                    style: TextStyle(
                      color: gold,
                      fontSize: _fontSize - 3,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                  TextSpan(text: verse.text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: lightGold,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: gold,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Sura Haijapatikana',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryBrown,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Imeshindikana kupakia sura hii.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: _loadVerses,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Jaribu Tena'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseActions() {
    final verse = _selectedVerse;

    if (verse == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: primaryBrown.withValues(alpha: 0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.bookName} '
              '${widget.chapterNumber}:${verse.number}',
              style: const TextStyle(
                color: primaryBrown,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Nakili',
                  onTap: _copySelectedVerse,
                ),
                _buildActionButton(
                  icon: _isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: 'Hifadhi',
                  onTap: _toggleBookmark,
                ),
                _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'Shiriki',
                  onTap: _shareSelectedVerse,
                ),

                _buildActionButton(
                  icon: Icons.volume_up_rounded,
                  label: 'Sikiliza',
                  onTap: _toggleAudio,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterNavigation() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: primaryBrown.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Sura Iliyopita'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBrown,
                  disabledForegroundColor: secondaryBrown.withValues(
                    alpha: 0.35,
                  ),
                  side: BorderSide(
                    color: _hasPreviousChapter
                        ? gold.withValues(alpha: 0.35)
                        : primaryBrown.withValues(alpha: 0.08),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: FilledButton.icon(
                onPressed: _hasNextChapter ? _goToNextChapter : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Sura Inayofuata'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryBrown,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryBrown.withValues(alpha: 0.12),
                  disabledForegroundColor: secondaryBrown.withValues(
                    alpha: 0.4,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationNotesSheet(BibleVerse verse) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        18,
        24,
        MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: primaryBrown.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded, color: gold),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maelezo ya Tafsiri',
                      style: TextStyle(
                        color: primaryBrown,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.bookName} '
                      '${widget.chapterNumber}:${verse.number}',
                      style: const TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            verse.text,
            style: const TextStyle(
              color: primaryBrown,
              fontSize: 17,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Maelezo',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Hapa ndipo maelezo kuhusu tafsiri, maana ya maneno ya awali, muktadha wa mstari na tofauti za tafsiri yataonyeshwa.',
            style: TextStyle(color: secondaryBrown, fontSize: 15, height: 1.6),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGold,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Neno la Awali',
                  style: TextStyle(
                    color: primaryBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Maelezo ya neno la Kiebrania au Kigiriki yataonekana hapa.',
                  style: TextStyle(color: secondaryBrown, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
