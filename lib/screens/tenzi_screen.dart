import 'package:flutter/material.dart';

import '../models/tenzi.dart';
import '../services/tenzi_service.dart';
import 'tenzi_reading_screen.dart';

class TenziScreen extends StatefulWidget {
  const TenziScreen({super.key});

  @override
  State<TenziScreen> createState() => _TenziScreenState();
}

class _TenziScreenState extends State<TenziScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);
  static const Color primaryBrown = Color(0xFF4E342E);
  static const Color secondaryBrown = Color(0xFF795548);
  static const Color gold = Color(0xFFD4A017);
  static const Color lightGold = Color(0xFFFFF5D9);
  static const Color cardColor = Color(0xFFFFFDF8);

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  List<Tenzi> _allTenzi = [];
  List<Tenzi> _filteredTenzi = [];

  bool _isLoading = true;
  bool _isSearching = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadTenzi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadTenzi() async {
    try {
      final List<Tenzi> tenzi = await TenziService.getAllTenzi();

      if (!mounted) return;

      setState(() {
        _allTenzi = tenzi;
        _filteredTenzi = tenzi;

        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = 'Imeshindikana kupakia Tenzi za Rohoni.';
      });
    }
  }

  Future<void> _searchTenzi(String query) async {
    final String value = query.trim();

    if (value.isEmpty) {
      setState(() {
        _filteredTenzi = _allTenzi;
        _isSearching = false;
      });

      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final List<Tenzi> results = await TenziService.search(value);

      if (!mounted) return;

      if (_searchController.text.trim() != value) {
        return;
      }

      setState(() {
        _filteredTenzi = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _filteredTenzi = [];
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _filteredTenzi = _allTenzi;
      _isSearching = false;
    });

    _searchFocusNode.unfocus();
  }

  void _openTenzi(Tenzi hymn) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TenziReadingScreen(hymn: hymn)),
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
          tooltip: 'Rudi',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: primaryBrown),
        ),

        titleSpacing: 0,

        title: const Row(
          children: [
            Icon(Icons.library_music_rounded, color: gold, size: 25),
            SizedBox(width: 9),
            Text(
              'Tenzi za Rohoni',
              style: TextStyle(
                color: primaryBrown,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTopSection(),

            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),

      decoration: BoxDecoration(
        color: backgroundColor,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: [primaryBrown, primaryBrown.withValues(alpha: 0.93)],
              ),

              borderRadius: BorderRadius.circular(22),

              boxShadow: [
                BoxShadow(
                  color: primaryBrown.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),

            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,

                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(17),
                  ),

                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFFFFD76A),
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Imba. Sifu. Abudu.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${_allTenzi.length} Tenzi za Rohoni',
                        style: const TextStyle(
                          color: Color(0xFFEADFD9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),

          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,

            onChanged: _searchTenzi,

            textInputAction: TextInputAction.search,

            decoration: InputDecoration(
              hintText: 'Tafuta namba, jina au maneno...',

              hintStyle: TextStyle(
                color: secondaryBrown.withValues(alpha: 0.65),
                fontSize: 14,
              ),

              prefixIcon: const Icon(Icons.search_rounded, color: gold),

              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Futa utafutaji',
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: secondaryBrown,
                      ),
                    )
                  : null,

              filled: true,
              fillColor: cardColor,

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),

                borderSide: BorderSide(
                  color: primaryBrown.withValues(alpha: 0.08),
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),

                borderSide: BorderSide(
                  color: primaryBrown.withValues(alpha: 0.08),
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),

                borderSide: const BorderSide(color: gold, width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: gold, size: 17),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  _searchController.text.trim().isEmpty
                      ? 'Tafuta kwa mfano: 23, Yesu, au Ni salama rohoni mwangu'
                      : '${_filteredTenzi.length} matokeo yamepatikana',

                  style: const TextStyle(
                    color: secondaryBrown,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),

              if (_isSearching)
                const SizedBox(
                  width: 16,
                  height: 16,

                  child: CircularProgressIndicator(color: gold, strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: gold, strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredTenzi.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: gold,

      onRefresh: () async {
        TenziService.clearCache();

        await _loadTenzi();

        if (_searchController.text.trim().isNotEmpty) {
          await _searchTenzi(_searchController.text);
        }
      },

      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),

        itemCount: _filteredTenzi.length,

        separatorBuilder: (_, __) => const SizedBox(height: 11),

        itemBuilder: (context, index) {
          final Tenzi hymn = _filteredTenzi[index];

          return _buildTenziCard(hymn);
        },
      ),
    );
  }

  Widget _buildTenziCard(Tenzi hymn) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () => _openTenzi(hymn),

        borderRadius: BorderRadius.circular(19),

        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

          decoration: BoxDecoration(
            color: cardColor,

            borderRadius: BorderRadius.circular(19),

            border: Border.all(color: primaryBrown.withValues(alpha: 0.07)),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Text(
                  hymn.displayNumber,

                  style: const TextStyle(
                    color: gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      hymn.title,

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: primaryBrown,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Tenzi Na. ${hymn.number}',

                      style: const TextStyle(
                        color: secondaryBrown,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: lightGold,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.search_off_rounded,
                color: gold,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Tenzi haijapatikana',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: primaryBrown,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Jaribu kutafuta kwa namba ya tenzi, jina lake, au maneno yaliyomo ndani ya wimbo.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 18),

            TextButton.icon(
              onPressed: _clearSearch,

              icon: const Icon(Icons.refresh_rounded, color: gold),

              label: const Text(
                'Onyesha Tenzi zote',

                style: TextStyle(color: gold, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.error_outline_rounded, color: gold, size: 46),

            const SizedBox(height: 16),

            Text(
              _errorMessage!,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: primaryBrown,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBrown,

                foregroundColor: Colors.white,
              ),

              onPressed: _loadTenzi,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Jaribu tena'),
            ),
          ],
        ),
      ),
    );
  }
}
