import 'package:flutter/material.dart';

import '../models/dictionary_entry.dart';

class DictionaryDetailScreen extends StatelessWidget {
  const DictionaryDetailScreen({super.key, required this.entry});

  final DictionaryEntry entry;

  static const Color backgroundColor = Color(0xFFFAF9F6);

  static const Color primaryBrown = Color(0xFF4E342E);

  static const Color secondaryBrown = Color(0xFF795548);

  static const Color gold = Color(0xFFD4A017);

  static const Color lightGold = Color(0xFFFFF5D9);

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
          'Maana ya Neno',
          style: TextStyle(
            color: primaryBrown,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWordHeader(),

              const SizedBox(height: 22),

              _buildDefinitionCard(),

              if (_hasOriginalLanguageInformation) ...[
                const SizedBox(height: 18),
                _buildOriginalLanguageCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasOriginalLanguageInformation {
    return entry.originalWord != null ||
        entry.transliteration != null ||
        entry.originalLanguage != null;
  }

  Widget _buildWordHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightGold,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.word.isEmpty
                  ? '?'
                  : entry.word.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: gold,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            entry.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryBrown,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (entry.transliteration != null) ...[
            const SizedBox(height: 7),
            Text(
              entry.transliteration!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefinitionCard() {
    return _buildInformationCard(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Maana',
      child: Text(
        entry.definition,
        style: const TextStyle(
          color: secondaryBrown,
          fontSize: 16,
          height: 1.65,
        ),
      ),
    );
  }

  Widget _buildOriginalLanguageCard() {
    return _buildInformationCard(
      icon: Icons.translate_rounded,
      title: 'Lugha ya Asili',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.originalLanguage != null)
            _buildDetailRow(label: 'Lugha', value: entry.originalLanguage!),

          if (entry.originalWord != null)
            _buildDetailRow(label: 'Neno la asili', value: entry.originalWord!),

          if (entry.transliteration != null)
            _buildDetailRow(label: 'Matamshi', value: entry.transliteration!),
        ],
      ),
    );
  }

  Widget _buildInformationCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryBrown.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: primaryBrown.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: lightGold,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: gold, size: 22),
              ),

              const SizedBox(width: 12),

              Text(
                title,
                style: const TextStyle(
                  color: primaryBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: secondaryBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: primaryBrown,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
