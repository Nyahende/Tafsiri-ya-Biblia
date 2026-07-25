import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dictionary_entry.dart';

class DictionaryService {
  DictionaryService._();

  static const String _dictionaryAssetPath = 'assets/data/dictionary.json';

  static List<DictionaryEntry>? _cachedEntries;

  /// Loads all dictionary entries from the JSON file.
  ///
  /// After the first load, the entries are kept in memory
  /// so the JSON file is not repeatedly loaded.
  static Future<List<DictionaryEntry>> getAllEntries() async {
    if (_cachedEntries != null) {
      return _cachedEntries!;
    }

    try {
      final String jsonString = await rootBundle.loadString(
        _dictionaryAssetPath,
      );

      final dynamic decodedData = jsonDecode(jsonString);

      late final List<dynamic> rawEntries;

      if (decodedData is List) {
        rawEntries = decodedData;
      } else if (decodedData is Map<String, dynamic> &&
          decodedData['words'] is List) {
        rawEntries = decodedData['words'] as List<dynamic>;
      } else {
        throw const FormatException(
          'Dictionary JSON must be a list or contain a "words" list.',
        );
      }

      final List<DictionaryEntry> entries = rawEntries.map((dynamic item) {
        if (item is! Map) {
          throw const FormatException(
            'Every dictionary entry must be a JSON object.',
          );
        }

        return DictionaryEntry.fromJson(Map<String, dynamic>.from(item));
      }).toList();

      entries.sort((DictionaryEntry first, DictionaryEntry second) {
        return first.word.toLowerCase().compareTo(second.word.toLowerCase());
      });

      _cachedEntries = entries;

      return entries;
    } catch (error) {
      throw Exception('Imeshindikana kupakia Kamusi: $error');
    }
  }

  /// Finds one exact dictionary entry.
  ///
  /// This method ignores:
  /// - uppercase and lowercase
  /// - commas
  /// - full stops
  /// - quotation marks
  /// - brackets
  /// - other punctuation
  static Future<DictionaryEntry?> findEntry(String word) async {
    final List<DictionaryEntry> entries = await getAllEntries();

    final String normalizedInput = normalizeWord(word);

    if (normalizedInput.isEmpty) {
      return null;
    }

    for (final DictionaryEntry entry in entries) {
      if (entry.normalizedWord == normalizedInput) {
        return entry;
      }
    }

    return null;
  }

  /// Returns true when a word exists in the dictionary.
  static Future<bool> containsWord(String word) async {
    final DictionaryEntry? entry = await findEntry(word);

    return entry != null;
  }

  /// Searches the dictionary by word or definition.
  static Future<List<DictionaryEntry>> searchEntries(String query) async {
    final List<DictionaryEntry> entries = await getAllEntries();

    final String normalizedQuery = normalizeSearchQuery(query);

    if (normalizedQuery.isEmpty) {
      return entries;
    }

    return entries.where((DictionaryEntry entry) {
      final String normalizedWord = entry.normalizedWord.toLowerCase();

      final String normalizedDefinition = entry.definition.toLowerCase();

      final String normalizedShortDefinition =
          entry.shortDefinition?.toLowerCase() ?? '';

      final String normalizedOriginalWord =
          entry.originalWord?.toLowerCase() ?? '';

      final String normalizedTransliteration =
          entry.transliteration?.toLowerCase() ?? '';

      return normalizedWord.contains(normalizedQuery) ||
          normalizedDefinition.contains(normalizedQuery) ||
          normalizedShortDefinition.contains(normalizedQuery) ||
          normalizedOriginalWord.contains(normalizedQuery) ||
          normalizedTransliteration.contains(normalizedQuery);
    }).toList();
  }

  /// Normalizes a single word for exact matching.
  ///
  /// Examples:
  ///
  /// Hekima    -> hekima
  /// hekima,   -> hekima
  /// “Hekima”  -> hekima
  /// hekima.   -> hekima
  static String normalizeWord(String word) {
    return word
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'''^[\s"'“”‘’.,;:!?()[\]{}<>«»—–-]+'''), '')
        .replaceAll(RegExp(r'''[\s"'“”‘’.,;:!?()[\]{}<>«»—–-]+$'''), '');
  }

  /// Normalizes a search query while allowing spaces.
  ///
  /// This is useful for phrases such as:
  ///
  /// Roho Mtakatifu
  /// Mtenda haki
  static String normalizeSearchQuery(String query) {
    return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns dictionary entries in a map.
  ///
  /// The normalized word becomes the key.
  ///
  /// This will later make verse-word detection faster.
  static Future<Map<String, DictionaryEntry>> getEntryMap() async {
    final List<DictionaryEntry> entries = await getAllEntries();

    return {
      for (final DictionaryEntry entry in entries) entry.normalizedWord: entry,
    };
  }

  /// Clears the dictionary currently stored in memory.
  ///
  /// This is mostly useful during development or testing.
  static void clearCache() {
    _cachedEntries = null;
  }
}
