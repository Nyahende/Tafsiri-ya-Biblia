import 'package:flutter/material.dart';

import '../models/tenzi.dart';
import '../services/tenzi_service.dart';

class TenziReadingScreen extends StatefulWidget {
  const TenziReadingScreen({required this.hymn, super.key});

  final Tenzi hymn;

  @override
  State<TenziReadingScreen> createState() => _TenziReadingScreenState();
}

class _TenziReadingScreenState extends State<TenziReadingScreen> {
  static const Color backgroundColor = Color(0xFFFAF9F6);

  static const Color primaryBrown = Color(0xFF4E342E);

  static const Color secondaryBrown = Color(0xFF795548);

  static const Color gold = Color(0xFFD4A017);

  static const Color lightGold = Color(0xFFFFF5D9);

  static const Color cardColor = Color(0xFFFFFDF8);

  late Tenzi _currentHymn;

  bool _isChangingHymn = false;

  @override
  void initState() {
    super.initState();

    _currentHymn = widget.hymn;
  }

  Future<void> _openPreviousHymn() async {
    if (_currentHymn.number <= 1 || _isChangingHymn) {
      return;
    }

    setState(() {
      _isChangingHymn = true;
    });

    try {
      final Tenzi? previous = await TenziService.getPreviousTenzi(
        _currentHymn.number,
      );

      if (!mounted) return;

      if (previous != null) {
        setState(() {
          _currentHymn = previous;
        });

        _scrollToTop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingHymn = false;
        });
      }
    }
  }

  Future<void> _openNextHymn() async {
    if (_currentHymn.number >= 161 || _isChangingHymn) {
      return;
    }

    setState(() {
      _isChangingHymn = true;
    });

    try {
      final Tenzi? next = await TenziService.getNextTenzi(_currentHymn.number);

      if (!mounted) return;

      if (next != null) {
        setState(() {
          _currentHymn = next;
        });

        _scrollToTop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingHymn = false;
        });
      }
    }
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPrevious = _currentHymn.number > 1;

    final bool hasNext = _currentHymn.number < 161;

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

        title: const Text(
          'Tenzi za Rohoni',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            decoration: BoxDecoration(
              color: lightGold,
              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              '${_currentHymn.number}/161',

              style: const TextStyle(
                color: gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        top: false,

        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,

                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildHymnHeader(),

                    const SizedBox(height: 20),

                    _buildLyricsCard(),

                    const SizedBox(height: 24),

                    _buildEndDecoration(),
                  ],
                ),
              ),
            ),

            _buildBottomNavigation(hasPrevious: hasPrevious, hasNext: hasNext),
          ],
        ),
      ),
    );
  }

  Widget _buildHymnHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: primaryBrown,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: primaryBrown.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Container(
                width: 65,
                height: 65,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.11),

                  borderRadius: BorderRadius.circular(19),

                  border: Border.all(
                    color: const Color(0xFFFFD76A).withValues(alpha: 0.35),
                  ),
                ),

                child: Text(
                  _currentHymn.number.toString().padLeft(3, '0'),

                  style: const TextStyle(
                    color: Color(0xFFFFD76A),
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'TENZI ZA ROHONI',

                      style: TextStyle(
                        color: Color(0xFFFFD76A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _currentHymn.title,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            width: double.infinity,

            color: Colors.white.withValues(alpha: 0.12),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: Color(0xFFFFD76A),
                size: 18,
              ),

              const SizedBox(width: 7),

              Text(
                'Tenzi Na. ${_currentHymn.number}',

                style: const TextStyle(
                  color: Color(0xFFEADFD9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(22, 25, 22, 27),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(23),

        border: Border.all(color: primaryBrown.withValues(alpha: 0.07)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: SelectableText(
        _currentHymn.lyrics,

        style: const TextStyle(
          color: primaryBrown,
          fontSize: 17,
          height: 1.72,
          letterSpacing: 0.05,
        ),
      ),
    );
  }

  Widget _buildEndDecoration() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: gold.withValues(alpha: 0.20)),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),

              child: Icon(Icons.music_note_rounded, color: gold, size: 18),
            ),

            Expanded(
              child: Container(height: 1, color: gold.withValues(alpha: 0.20)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'Tenzi za Rohoni',

          style: TextStyle(
            color: secondaryBrown,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation({
    required bool hasPrevious,
    required bool hasNext,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),

      decoration: BoxDecoration(
        color: cardColor,

        border: Border(
          top: BorderSide(color: primaryBrown.withValues(alpha: 0.07)),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            Expanded(
              child: _NavigationButton(
                icon: Icons.arrow_back_rounded,

                label: 'Iliyopita',

                enabled: hasPrevious && !_isChangingHymn,

                onTap: _openPreviousHymn,
              ),
            ),

            const SizedBox(width: 12),

            Container(
              width: 54,
              height: 48,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: lightGold,

                borderRadius: BorderRadius.circular(15),
              ),

              child: _isChangingHymn
                  ? const SizedBox(
                      width: 19,
                      height: 19,

                      child: CircularProgressIndicator(
                        color: gold,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.library_music_rounded,
                      color: gold,
                      size: 24,
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _NavigationButton(
                icon: Icons.arrow_forward_rounded,

                label: 'Inayofuata',

                iconAfterText: true,

                enabled: hasNext && !_isChangingHymn,

                onTap: _openNextHymn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.iconAfterText = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool iconAfterText;

  static const Color primaryBrown = Color(0xFF4E342E);

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: enabled ? onTap : null,

        borderRadius: BorderRadius.circular(15),

        child: Ink(
          height: 48,

          decoration: BoxDecoration(
            color: enabled
                ? primaryBrown
                : primaryBrown.withValues(alpha: 0.38),

            borderRadius: BorderRadius.circular(15),
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              if (!iconAfterText) ...[
                Icon(icon, color: foregroundColor, size: 19),

                const SizedBox(width: 7),
              ],

              Text(
                label,

                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (iconAfterText) ...[
                const SizedBox(width: 7),

                Icon(icon, color: foregroundColor, size: 19),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
