import 'dart:async';

import 'package:flutter/material.dart';

import '../models/bible_search_result.dart';
import '../services/bible_search_service.dart';
import '../screens/verse_reading_screen.dart';

class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  Timer? _searchDebounce;

  List<BibleSearchResult> _results = [];

  bool _isSearching = false;
  bool _hasSearched = false;

  String? _errorMessage;

  /// Used to ensure an older search does not replace
  /// the results of a newer search.
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.removeListener(_onSearchTextChanged);

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  void _onSearchTextChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    _searchDebounce?.cancel();

    final String query = _searchController.text.trim();

    if (query.isEmpty) {
      _searchRequestId++;

      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
        _errorMessage = null;
      });

      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      return;
    }

    final int currentRequestId = ++_searchRequestId;

    if (mounted) {
      setState(() {
        _isSearching = true;
        _hasSearched = true;
        _errorMessage = null;
      });
    }

    try {
      final List<BibleSearchResult> results = await BibleSearchService.search(
        cleanedQuery,
      );

      if (!mounted) {
        return;
      }

      /// Ignore results from an older search.
      if (currentRequestId != _searchRequestId) {
        return;
      }

      /// Ignore results if the user has changed the query.
      if (_searchController.text.trim() != cleanedQuery) {
        return;
      }

      setState(() {
        _results = results;
        _isSearching = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (currentRequestId != _searchRequestId) {
        return;
      }

      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = 'Imeshindikana kutafuta katika Biblia. Jaribu tena.';
      });
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();

    _searchRequestId++;

    _searchController.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _results = [];
      _hasSearched = false;
      _isSearching = false;
      _errorMessage = null;
    });

    _searchFocusNode.requestFocus();
  }

  void _useSearchSuggestion(String suggestion) {
    _searchDebounce?.cancel();

    _searchController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );

    _performSearch(suggestion);
  }

  void _openSearchResult(BibleSearchResult result) {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseReadingScreen(
          bookName: result.bookName,
          chapterNumber: result.chapterNumber,
          chapterCount: result.chapterCount,
          initialVerseNumber: result.verseNumber,
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Rudi',
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        title: const Text(
          'Tafuta Biblia',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tafuta neno au kifungu',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Andika neno au maneno unayokumbuka '
            'kutoka katika Biblia.',
            style: TextStyle(color: secondaryBrown, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 18),
          _buildSearchField(),
          const SizedBox(height: 14),
          if (_hasSearched && !_isSearching && _errorMessage == null)
            Text(
              _buildResultCountText(),
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      textInputAction: TextInputAction.search,
      cursorColor: gold,
      autocorrect: false,
      enableSuggestions: true,
      onSubmitted: (String query) {
        _searchDebounce?.cancel();

        final String cleanedQuery = query.trim();

        if (cleanedQuery.isNotEmpty) {
          _performSearch(cleanedQuery);
        }
      },
      decoration: InputDecoration(
        hintText: 'Mfano: hekima',
        hintStyle: TextStyle(color: secondaryBrown.withValues(alpha: 0.60)),
        prefixIcon: const Icon(Icons.search_rounded, color: gold),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                tooltip: 'Futa',
                icon: const Icon(Icons.close_rounded, color: secondaryBrown),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryBrown.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
      ),
    );
  }

  String _buildResultCountText() {
    final int count = _results.length;

    if (count == 0) {
      return 'Hakuna matokeo';
    }

    if (count == 1) {
      return 'Mstari 1 umepatikana';
    }

    return 'Mistari $count imepatikana';
  }

  Widget _buildBody() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_results.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildResultsList();
  }

  Widget _buildInitialState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: lightGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.manage_search_rounded,
                color: gold,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tafuta katika Biblia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryBrown,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unaweza kutafuta neno moja au '
              'kifungu kamili kama “Hofu ya BWANA”.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildSearchSuggestion('hekima'),
                _buildSearchSuggestion('Hofu ya BWANA'),
                _buildSearchSuggestion('maelekezo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestion(String suggestion) {
    return ActionChip(
      avatar: const Icon(Icons.search_rounded, color: gold, size: 18),
      label: Text(suggestion),
      labelStyle: const TextStyle(
        color: primaryBrown,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: primaryBrown.withValues(alpha: 0.10)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _useSearchSuggestion(suggestion);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: gold),
          SizedBox(height: 16),
          Text(
            'Inatafuta...',
            style: TextStyle(
              color: secondaryBrown,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      itemCount: _results.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final BibleSearchResult result = _results[index];

        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(BibleSearchResult result) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openSearchResult(result);
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: primaryBrown.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: lightGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.reference,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: gold,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildHighlightedVerse(
                result.verseText,
                _searchController.text.trim(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedVerse(String verseText, String query) {
    final String cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      return Text(
        verseText,
        style: const TextStyle(color: primaryBrown, fontSize: 16, height: 1.6),
      );
    }

    final String lowercaseVerse = verseText.toLowerCase();

    final String lowercaseQuery = cleanedQuery.toLowerCase();

    final List<TextSpan> spans = [];

    int currentIndex = 0;

    while (currentIndex < verseText.length) {
      final int matchIndex = lowercaseVerse.indexOf(
        lowercaseQuery,
        currentIndex,
      );

      if (matchIndex == -1) {
        spans.add(TextSpan(text: verseText.substring(currentIndex)));

        break;
      }

      if (matchIndex > currentIndex) {
        spans.add(
          TextSpan(text: verseText.substring(currentIndex, matchIndex)),
        );
      }

      final int matchEnd = matchIndex + cleanedQuery.length;

      spans.add(
        TextSpan(
          text: verseText.substring(matchIndex, matchEnd),
          style: const TextStyle(
            color: primaryBrown,
            fontWeight: FontWeight.bold,
            backgroundColor: lightGold,
          ),
        ),
      );

      currentIndex = matchEnd;
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: primaryBrown, fontSize: 16, height: 1.6),
        children: spans,
      ),
    );
  }

  Widget _buildNoResultsState() {
    final String query = _searchController.text.trim();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: lightGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: gold,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Hakuna mstari uliopatikana',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryBrown,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hakuna mstari wenye “$query” '
              'katika vitabu vilivyopo kwa sasa.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tafuta neno lingine'),
              style: TextButton.styleFrom(foregroundColor: gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: gold, size: 58),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Imeshindikana kutafuta katika Biblia.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                final String query = _searchController.text.trim();

                if (query.isNotEmpty) {
                  _performSearch(query);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Jaribu Tena'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
