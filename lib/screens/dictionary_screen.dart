import 'package:flutter/material.dart';

import '../models/dictionary_entry.dart';
import '../services/dictionary_service.dart';
import 'dictionary_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);

  static const Color primaryBrown = Color(0xFF4E342E);

  static const Color secondaryBrown = Color(0xFF795548);

  static const Color gold = Color(0xFFD4A017);

  static const Color lightGold = Color(0xFFFFF5D9);

  final TextEditingController _searchController = TextEditingController();

  List<DictionaryEntry> _allEntries = [];
  List<DictionaryEntry> _filteredEntries = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadDictionary();

    _searchController.addListener(_filterDictionary);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDictionary);

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadDictionary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<DictionaryEntry> entries =
          await DictionaryService.getAllEntries();

      if (!mounted) {
        return;
      }

      setState(() {
        _allEntries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Imeshindikana kupakia kamusi.';
      });
    }
  }

  void _filterDictionary() {
    final String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredEntries = _allEntries;
      });

      return;
    }

    setState(() {
      _filteredEntries = _allEntries.where((DictionaryEntry entry) {
        final String word = entry.word.toLowerCase();

        final String definition = entry.definition.toLowerCase();

        final String shortDefinition =
            entry.shortDefinition?.toLowerCase() ?? '';

        final String transliteration =
            entry.transliteration?.toLowerCase() ?? '';

        return word.contains(query) ||
            definition.contains(query) ||
            shortDefinition.contains(query) ||
            transliteration.contains(query);
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();

    FocusScope.of(context).unfocus();
  }

  Future<void> _openDictionaryEntry(DictionaryEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DictionaryDetailScreen(entry: entry)),
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
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),
        title: const Text(
          'Kamusi',
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

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maana za Maneno',
            style: TextStyle(
              color: primaryBrown,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Tafuta na ujifunze maana ya maneno '
            'yanayotumika katika tafsiri.',
            style: TextStyle(color: secondaryBrown, fontSize: 14, height: 1.45),
          ),

          const SizedBox(height: 18),

          _buildSearchField(),

          const SizedBox(height: 14),

          if (!_isLoading && _errorMessage == null)
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
      textInputAction: TextInputAction.search,
      cursorColor: gold,
      decoration: InputDecoration(
        hintText: 'Tafuta neno...',
        hintStyle: TextStyle(color: secondaryBrown.withValues(alpha: 0.65)),
        prefixIcon: const Icon(Icons.search_rounded, color: gold),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded, color: secondaryBrown),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
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
    final int count = _filteredEntries.length;

    if (_searchController.text.trim().isEmpty) {
      return 'Maneno $count katika kamusi';
    }

    if (count == 1) {
      return 'Neno 1 limepatikana';
    }

    return 'Maneno $count yamepatikana';
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: gold));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredEntries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: gold,
      onRefresh: _loadDictionary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        itemCount: _filteredEntries.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final DictionaryEntry entry = _filteredEntries[index];

          return _buildDictionaryCard(entry);
        },
      ),
    );
  }

  Widget _buildDictionaryCard(DictionaryEntry entry) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openDictionaryEntry(entry);
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: primaryBrown.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFirstLetter(entry.word),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.word,
                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      entry.shortDefinition ?? entry.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryBrown,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),

                    if (entry.transliteration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          entry.transliteration!,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: gold,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstLetter(String word) {
    final String firstLetter = word.isEmpty
        ? '?'
        : word.substring(0, 1).toUpperCase();

    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: gold,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: lightGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: gold,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Neno halijapatikana',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryBrown,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Hakuna neno linalolingana na '
              '“${_searchController.text.trim()}”.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 18),

            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Onyesha maneno yote'),
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
            const Icon(Icons.menu_book_rounded, color: gold, size: 58),

            const SizedBox(height: 18),

            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _loadDictionary,
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
