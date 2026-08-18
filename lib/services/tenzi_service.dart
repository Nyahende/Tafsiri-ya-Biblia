import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tenzi.dart';

class TenziService {
  TenziService._();

  static const String _assetPath = 'assets/data/tenzi.json';

  static List<Tenzi>? _cachedTenzi;

  /// Loads all Tenzi from the JSON file.
  ///
  /// The data is cached after the first load so that
  /// subsequent searches and navigation are fast.
  static Future<List<Tenzi>> getAllTenzi() async {
    if (_cachedTenzi != null) {
      return _cachedTenzi!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_assetPath);

      final dynamic decodedData = jsonDecode(jsonString);

      if (decodedData is! Map) {
        throw const FormatException('Tenzi JSON must contain an object.');
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(decodedData);

      final dynamic rawHymns = data['hymns'];

      if (rawHymns is! List) {
        throw const FormatException('Tenzi JSON must contain a hymns list.');
      }

      final List<Tenzi> tenzi = [];

      for (final dynamic rawHymn in rawHymns) {
        if (rawHymn is! Map) {
          continue;
        }

        final Tenzi hymn = Tenzi.fromJson(Map<String, dynamic>.from(rawHymn));

        if (hymn.number <= 0 || hymn.title.isEmpty || hymn.lyrics.isEmpty) {
          continue;
        }

        tenzi.add(hymn);
      }

      tenzi.sort(
        (Tenzi first, Tenzi second) => first.number.compareTo(second.number),
      );

      _cachedTenzi = List<Tenzi>.unmodifiable(tenzi);

      return _cachedTenzi!;
    } catch (error) {
      throw Exception('Imeshindikana kupakia Tenzi za Rohoni: $error');
    }
  }

  /// Finds one hymn using its hymn number.
  ///
  /// Example:
  /// getTenziByNumber(23)
  static Future<Tenzi?> getTenziByNumber(int number) async {
    if (number <= 0) {
      return null;
    }

    final List<Tenzi> tenzi = await getAllTenzi();

    for (final Tenzi hymn in tenzi) {
      if (hymn.number == number) {
        return hymn;
      }
    }

    return null;
  }

  /// Searches Tenzi by:
  ///
  /// - hymn number
  /// - title
  /// - words appearing anywhere in the hymn
  ///
  /// Examples:
  ///
  /// 23
  ///
  /// Tenzi 23
  ///
  /// Ni salama rohoni mwangu
  ///
  /// Yesu Mwokozi
  ///
  /// damu
  static Future<List<Tenzi>> search(String query) async {
    final String trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return getAllTenzi();
    }

    final List<Tenzi> tenzi = await getAllTenzi();

    final int? requestedNumber = _extractHymnNumber(trimmedQuery);

    /// If the query clearly refers to a hymn number,
    /// return that hymn directly.
    ///
    /// Examples:
    /// 23
    /// Tenzi 23
    /// Tenzi Na. 23
    /// Tenzi Namba 23
    if (requestedNumber != null) {
      final Tenzi? exactHymn = await getTenziByNumber(requestedNumber);

      if (exactHymn != null) {
        return [exactHymn];
      }

      return [];
    }

    final String normalizedQuery = normalizeText(trimmedQuery);

    if (normalizedQuery.isEmpty) {
      return [];
    }

    final List<String> queryWords = normalizedQuery
        .split(' ')
        .where((String word) => word.trim().isNotEmpty)
        .toList();

    final List<_RankedTenzi> rankedResults = [];

    for (final Tenzi hymn in tenzi) {
      final String normalizedTitle = normalizeText(hymn.title);

      final String normalizedLyrics = normalizeText(hymn.lyrics);

      int score = 0;

      /// Exact title match receives the highest score.
      if (normalizedTitle == normalizedQuery) {
        score = 100;
      }
      /// A title beginning with the query is highly relevant.
      else if (normalizedTitle.startsWith(normalizedQuery)) {
        score = 90;
      }
      /// Query appears somewhere in the title.
      else if (normalizedTitle.contains(normalizedQuery)) {
        score = 80;
      }
      /// Exact phrase appears somewhere in the lyrics.
      else if (normalizedLyrics.contains(normalizedQuery)) {
        score = 70;
      }
      /// Every word supplied by the user appears
      /// somewhere in either the title or lyrics.
      else {
        final String searchableText = '$normalizedTitle $normalizedLyrics';

        final bool containsAllWords = queryWords.every(
          (String word) => searchableText.contains(word),
        );

        if (containsAllWords) {
          score = 60;
        }
      }

      if (score > 0) {
        rankedResults.add(_RankedTenzi(hymn: hymn, score: score));
      }
    }

    /// Show the most relevant results first.
    ///
    /// Hymn number is used as the secondary sorting rule.
    rankedResults.sort((_RankedTenzi first, _RankedTenzi second) {
      final int scoreComparison = second.score.compareTo(first.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return first.hymn.number.compareTo(second.hymn.number);
    });

    return rankedResults.map((_RankedTenzi result) => result.hymn).toList();
  }

  /// Returns the next hymn.
  static Future<Tenzi?> getNextTenzi(int currentNumber) async {
    return getTenziByNumber(currentNumber + 1);
  }

  /// Returns the previous hymn.
  static Future<Tenzi?> getPreviousTenzi(int currentNumber) async {
    return getTenziByNumber(currentNumber - 1);
  }

  /// Returns the total number of hymns.
  static Future<int> getTotalCount() async {
    final List<Tenzi> tenzi = await getAllTenzi();

    return tenzi.length;
  }

  /// Recognises searches that clearly refer to a
  /// hymn number.
  ///
  /// Examples recognised:
  ///
  /// 23
  /// Tenzi 23
  /// Tenzi Na 23
  /// Tenzi Na. 23
  /// Tenzi Namba 23
  static int? _extractHymnNumber(String query) {
    final String normalized = query.trim().toLowerCase();

    /// Pure number.
    final int? directNumber = int.tryParse(normalized);

    if (directNumber != null) {
      return directNumber;
    }

    final RegExp expression = RegExp(
      r'^tenzi\s+(?:(?:na|namba)\.?\s*)?(\d+)$',
      caseSensitive: false,
    );

    final RegExpMatch? match = expression.firstMatch(normalized);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1) ?? '');
  }

  /// Converts text into a consistent searchable format.
  ///
  /// Search ignores:
  /// - uppercase/lowercase
  /// - punctuation
  /// - repeated spaces
  /// - line breaks
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'''["“”‘’'.,;:!?()[\]{}<>«»—–_-]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Clears the cache during development if
  /// tenzi.json has been modified.
  static void clearCache() {
    _cachedTenzi = null;
  }
}

class _RankedTenzi {
  final Tenzi hymn;
  final int score;

  const _RankedTenzi({required this.hymn, required this.score});
}
