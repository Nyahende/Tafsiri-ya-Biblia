import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/bible_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/reading_progress_service.dart';
import 'saved_verses_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/cross_reference_service.dart';

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

  /// Verse to select and scroll to when this screen opens.
  final int? initialVerseNumber;

  @override
  State<VerseReadingScreen> createState() {
    return _VerseReadingScreenState();
  }
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

  final Set<int> _bookmarkedVerseNumbers = <int>{};
  final Set<int> _crossReferencedVerseNumbers = <int>{};

  final ScrollController _verseScrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = <int, GlobalKey>{};

  int? _destinationHighlightVerseNumber;

  String? _errorMessage;

  double _fontSize = 18;

  @override
  void initState() {
    super.initState();

    _selectedVerseNumber = widget.initialVerseNumber;

    _initializeChapter();
  }

  @override
  void dispose() {
    _verseScrollController.dispose();
    super.dispose();
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

    await _loadBookmarkStatus();

    if (!mounted) {
      return;
    }

    await _loadCrossReferenceStatus();

    if (!mounted) {
      return;
    }

    await _focusInitialVerse();
  }

  Future<void> _focusInitialVerse() async {
    final int? targetVerseNumber = widget.initialVerseNumber;

    if (targetVerseNumber == null || _verses.isEmpty) {
      return;
    }

    final int targetIndex = _verses.indexWhere(
      (BibleVerse verse) => verse.number == targetVerseNumber,
    );

    if (targetIndex < 0) {
      return;
    }

    setState(() {
      _destinationHighlightVerseNumber = targetVerseNumber;
    });

    // Let the ListView build before positioning it.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted || !_verseScrollController.hasClients) {
      return;
    }

    // First jump near the target. This works even when the target verse is
    // initially far outside the ListView's built/rendered area.
    final double maxExtent = _verseScrollController.position.maxScrollExtent;
    final double approximateOffset = _verses.length <= 1
        ? 0
        : maxExtent * (targetIndex / (_verses.length - 1));

    _verseScrollController.jumpTo(approximateOffset.clamp(0.0, maxExtent));

    // Give Flutter a frame to build the target verse, then align it neatly.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!mounted) {
      return;
    }

    final BuildContext? targetContext =
        _verseKeys[targetVerseNumber]?.currentContext;

    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.28,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }

    // Keep the gold focus long enough to be noticed, then fade it away.
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!mounted || _destinationHighlightVerseNumber != targetVerseNumber) {
      return;
    }

    setState(() {
      _destinationHighlightVerseNumber = null;
    });
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
      _selectedVerseNumber = widget.initialVerseNumber;
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
        _isBookmarked =
            _selectedVerseNumber != null &&
            _bookmarkedVerseNumbers.contains(_selectedVerseNumber);
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

  void _selectVerse(BibleVerse verse) {
    setState(() {
      if (_selectedVerseNumber == verse.number) {
        _selectedVerseNumber = null;
        _isBookmarked = false;
      } else {
        _selectedVerseNumber = verse.number;
        _isBookmarked = _bookmarkedVerseNumbers.contains(verse.number);
      }
    });
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final List<BibleBookmark> bookmarks =
          await BookmarkService.getBookmarks();

      if (!mounted) {
        return;
      }

      final Set<int> savedVerseNumbers = bookmarks
          .where(
            (BibleBookmark bookmark) =>
                bookmark.bookName.trim().toLowerCase() ==
                    widget.bookName.trim().toLowerCase() &&
                bookmark.chapterNumber == widget.chapterNumber,
          )
          .map((BibleBookmark bookmark) => bookmark.verseNumber)
          .toSet();

      setState(() {
        _bookmarkedVerseNumbers
          ..clear()
          ..addAll(savedVerseNumbers);

        _isBookmarked =
            _selectedVerseNumber != null &&
            _bookmarkedVerseNumbers.contains(_selectedVerseNumber);
      });
    } catch (error) {
      debugPrint(
        'Imeshindikana kupakia hali ya mistari iliyohifadhiwa: $error',
      );
    }
  }

  Future<void> _loadCrossReferenceStatus() async {
    try {
      final Set<int> versesWithReferences = <int>{};
      final String bookId = _bookNameToId(widget.bookName);

      for (final BibleVerse verse in _verses) {
        final bool hasReferences = await CrossReferenceService.hasReferences(
          bookId: bookId,
          chapter: widget.chapterNumber,
          verse: verse.number,
        );

        if (hasReferences) {
          versesWithReferences.add(verse.number);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _crossReferencedVerseNumbers
          ..clear()
          ..addAll(versesWithReferences);
      });
    } catch (error) {
      debugPrint('Imeshindikana kupakia marejeo ya mistari: $error');
    }
  }

  String _bookNameToId(String bookName) {
    final String normalized = bookName.trim().toLowerCase();

    if (normalized == 'mambo ya walawi') {
      return 'mambo ya walawi';
    }

    return normalized.replaceAll(' ', '_');
  }

  Future<void> _openCrossReferences(BibleVerse sourceVerse) async {
    final String bookId = _bookNameToId(widget.bookName);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (BuildContext context, ScrollController scrollController) {
            return FutureBuilder<List<_CrossReferenceDisplayItem>>(
              future: _loadCrossReferenceDisplayItems(
                bookId: bookId,
                sourceVerse: sourceVerse,
              ),
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }

                if (snapshot.hasError) {
                  return _buildCrossReferenceError(
                    scrollController,
                    sourceVerse,
                  );
                }

                final List<_CrossReferenceDisplayItem> items =
                    snapshot.data ?? const <_CrossReferenceDisplayItem>[];

                return _buildCrossReferenceSheet(
                  sheetContext: sheetContext,
                  scrollController: scrollController,
                  sourceVerse: sourceVerse,
                  items: items,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<_CrossReferenceDisplayItem>> _loadCrossReferenceDisplayItems({
    required String bookId,
    required BibleVerse sourceVerse,
  }) async {
    final List<CrossReference> references =
        await CrossReferenceService.getReferences(
          bookId: bookId,
          chapter: widget.chapterNumber,
          verse: sourceVerse.number,
        );

    final List<_CrossReferenceDisplayItem> items = [];

    for (final CrossReference reference in references) {
      try {
        final BibleReferenceVerse target = await BibleService.getReferenceVerse(
          bookId: reference.bookId,
          chapterNumber: reference.chapter,
          verseNumber: reference.verse,
        );

        items.add(
          _CrossReferenceDisplayItem(reference: reference, target: target),
        );
      } catch (error) {
        debugPrint('Imeshindikana kupakia rejeo: $error');
      }
    }

    return items;
  }

  Widget _buildCrossReferenceSheet({
    required BuildContext sheetContext,
    required ScrollController scrollController,
    required BibleVerse sourceVerse,
    required List<_CrossReferenceDisplayItem> items,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 46,
          height: 5,
          decoration: BoxDecoration(
            color: primaryBrown.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '†',
                  style: TextStyle(
                    color: gold,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Marejeo',
                      style: TextStyle(
                        color: primaryBrown,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.bookName} '
                      '${widget.chapterNumber}:${sourceVerse.number}',
                      style: const TextStyle(
                        color: secondaryBrown,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Funga',
                onPressed: () => Navigator.of(sheetContext).pop(),
                icon: const Icon(Icons.close_rounded, color: primaryBrown),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: primaryBrown.withValues(alpha: 0.08)),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Hakuna marejeo yanayoweza kuonyeshwa.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryBrown, fontSize: 15),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final _CrossReferenceDisplayItem item = items[index];
                    return _buildCrossReferenceCard(
                      sheetContext: sheetContext,
                      item: item,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCrossReferenceCard({
    required BuildContext sheetContext,
    required _CrossReferenceDisplayItem item,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(sheetContext).pop();

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => VerseReadingScreen(
                bookName: item.target.bookName,
                chapterNumber: item.target.chapterNumber,
                chapterCount: item.target.chapterCount,
                initialVerseNumber: item.target.verseNumber,
              ),
            ),
          );
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: lightGold.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold.withValues(alpha: 0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.target.reference,
                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: gold,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.target.verseText,
                style: const TextStyle(
                  color: primaryBrown,
                  fontSize: 15,
                  height: 1.55,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _crossReferenceTypeLabel(item.reference.type),
                  style: const TextStyle(
                    color: secondaryBrown,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrossReferenceError(
    ScrollController scrollController,
    BibleVerse sourceVerse,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.error_outline_rounded, color: gold, size: 42),
        const SizedBox(height: 14),
        const Text(
          'Marejeo hayakuweza kupakiwa.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryBrown,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${widget.bookName} '
          '${widget.chapterNumber}:${sourceVerse.number}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: secondaryBrown, fontSize: 14),
        ),
      ],
    );
  }

  String _crossReferenceTypeLabel(String type) {
    switch (type) {
      case 'direct_reference':
        return 'Rejeo la moja kwa moja';
      case 'quotation_or_echo':
        return 'Nukuu / mwangwi wa maandiko';
      case 'parallel':
        return 'Kifungu sambamba';
      case 'explanation':
        return 'Maelezo / ufafanuzi';
      case 'contrast':
        return 'Ulinganisho / tofauti';
      case 'fulfillment':
        return 'Utimizwaji / maendeleo ya ahadi';
      case 'theme':
        return 'Mada inayohusiana';
      default:
        return 'Rejeo linalohusiana';
    }
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

  Future<void> _toggleBookmark(BibleVerse verse) async {
    try {
      final bool isNowSaved = await BookmarkService.toggleBookmark(
        BibleBookmark(
          bookName: widget.bookName,
          chapterNumber: widget.chapterNumber,
          chapterCount: widget.chapterCount,
          verseNumber: verse.number,
          verseText: verse.text,
          savedAt: DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (isNowSaved) {
          _bookmarkedVerseNumbers.add(verse.number);
        } else {
          _bookmarkedVerseNumbers.remove(verse.number);
        }

        if (_selectedVerseNumber == verse.number) {
          _isBookmarked = isNowSaved;
        }
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isNowSaved
                  ? 'Mstari umehifadhiwa.'
                  : 'Mstari umeondolewa kwenye zilizohifadhiwa.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kuhifadhi mstari: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _shareSelectedVerse() async {
    final BibleVerse? verse = _selectedVerse;

    if (verse == null) {
      return;
    }

    final String reference =
        '${widget.bookName} ${widget.chapterNumber}:${verse.number}';

    final String shareText =
        '${verse.text}\n\n'
        '$reference\n\n'
        'Jifunze Biblia';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: reference,
          title: 'Shiriki $reference',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Imeshindikana kushiriki mstari: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
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
            onSelected: (value) async {
              if (value == 'search') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Utafutaji wa Biblia utaongezwa.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              if (value == 'bookmarks') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SavedVersesScreen(),
                  ),
                );

                if (!mounted) {
                  return;
                }

                await _loadBookmarkStatus();
              }
            },
            itemBuilder: (context) {
              return const [
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
      controller: _verseScrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        return _buildVerse(_verses[index]);
      },
    );
  }

  Widget _buildVerse(BibleVerse verse) {
    final bool isSelected = _selectedVerseNumber == verse.number;
    final bool isDestinationHighlighted =
        _destinationHighlightVerseNumber == verse.number;
    final bool hasCrossReferences = _crossReferencedVerseNumbers.contains(
      verse.number,
    );

    final GlobalKey verseKey = _verseKeys.putIfAbsent(
      verse.number,
      () => GlobalKey(),
    );

    return Padding(
      key: verseKey,
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _selectVerse(verse);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDestinationHighlighted
                  ? gold.withValues(alpha: 0.30)
                  : isSelected
                  ? selectedVerseColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isDestinationHighlighted
                  ? Border.all(color: gold.withValues(alpha: 0.70), width: 1.4)
                  : isSelected
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
                  if (hasCrossReferences)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _openCrossReferences(verse);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              '†',
                              style: TextStyle(
                                color: gold,
                                fontSize: _fontSize + 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                  label: _isBookmarked ? 'Imehifadhiwa' : 'Hifadhi',
                  onTap: () => _toggleBookmark(verse),
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

class _CrossReferenceDisplayItem {
  const _CrossReferenceDisplayItem({
    required this.reference,
    required this.target,
  });

  final CrossReference reference;
  final BibleReferenceVerse target;
}
